import '../../../domain/models/explanation.dart';

import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/branch_move.dart';
import '../../../domain/use_cases/engine_fallback.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/models/variation_tree.dart';
import '../../../domain/use_cases/speech_lines.dart';
import '../../../domain/use_cases/variation_tree_builder.dart';
import '../../../domain/use_cases/speech_links.dart';
import '../../../domain/use_cases/wiki_markup.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/viktor_sheet.dart';
import '../../core/widgets/reference_link.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/speech_flash.dart';
import '../../core/keys/school_keys.dart';
import '../../core/keys/lesson_v2_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/step_timer.dart';
import '../../core/widgets/typing_dots.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../core/widgets/lesson_sound_dialog.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/lesson_cubit.dart';
import '../../core/board/exercise_layout.dart';
import '../../core/board/centered_board_layout.dart';
import 'lesson_part_widgets.dart';
import 'lesson_finished.dart';
import 'lesson_practice.dart';
import 'star_shape.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/text_link.dart';
import '../../../domain/models/endgame_position.dart';
import 'failed_moves_list.dart';

/// Uma aula com o Viktor: tabuleiro fixo no centro e fala na folha abaixo.
/// A folha expandida cobre o jogo sem alterar sua geometria.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, this.engine});

  /// O motor que responde ao lance fora dos dados (T70, crit. 8 e 9c). Sem
  /// ele, a peça volta e a folha avisa.
  final EngineFallback? engine;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // O tabuleiro entra a cada passo novo com um esmaecer curto.
  // T70: "Ver enunciado completo" aberto pelo link (mostra "Ocultar"); o
  // enunciado forçado enquanto a folha mede para abrir sozinha; a linha do
  // lance errado aberta no modo variante; árvores e falas das linhas do think.
  bool _statementShown = false;
  bool _forceStatement = false;
  bool _autoUser = false;
  bool _wrongBranch = false;
  String? _wrongHandled;
  final _lineTrees = Expando<VariationTree>();
  final _lineTexts = Expando<List<String>>();

  late final _landing = AnimationController(
    vsync: this,
    duration: AppMotion.component,
    value: 1,
  );

  ChessboardController? _board;

  // Apresentação (T65 §8). Caso B: a folha cobre o tabuleiro, sem rodapé e
  // sem relógio, até o fim da fala (ou do tempo de leitura) ou o X.
  final _speechContent = GlobalKey();
  final _presentingModal = ValueNotifier(false);
  bool _presentHandled = false;
  bool _presentExpanded = false;
  bool _presentSpoke = false;
  Duration _presentWait = Duration.zero;

  // Sacode o tabuleiro no lance errado.
  // A casa ou o lance tocado na fala, por um instante no tabuleiro.
  final _flash = SpeechFlash();

  // A variante citada na fala, aberta no tabuleiro (lance a lance). Nula: o
  // tabuleiro mostra o passo. Fica na tela: sobrevive ao segundo plano e
  // sai sozinha quando o passo, a posição ou a fala mudam.
  VariationCursor? _authoredVariation;

  final _variation = ValueNotifier<SpeechLineCursor?>(null);

  // Sub-variante da faixa (T68): onde o aluno está quando não é na linha
  // principal. Nulo: na principal, no lance do cursor acima. Com ramo, o
  // cursor fica no ponto de partida dele (`at`).
  final _branch = ValueNotifier<TreePosition?>(null);
  VariationTree? _tree;
  Object? _treeKey;

  // Lances ocultos (T69): os já vistos por linha da faixa (passo + fonte +
  // lance), só na memória da tela: o segundo plano mantém, fechar o app e
  // sair da lição zeram.
  final _seen = <String, Set<TreePosition>>{};
  String? _seenId;
  final _seenTick = ValueNotifier<int>(0);
  final _engineThinking = ValueNotifier<bool>(false);
  RevealEvent? _revealing;

  // A folha da faixa (segunda ViktorSheet, só no modo variante) e se está
  // aberta (T68). Fica só na memória da tela: fechar o app sai da variante.
  final _variationSheet = DraggableScrollableController();

  // A entrada na variante segue a sequência do canvas: a folha sai, o
  // tabuleiro anda, entra a faixa e, por fim, os controles. [_stage] conta
  // quantos passos já valem (3: tudo à vista); a fala só troca com a folha
  // já fora ([_speechHeld] segura o texto do passo até lá).
  final _stage = ValueNotifier<int>(0);
  final _entryTimers = <Timer>[];
  bool _speechHeld = false;

  // As variantes da fala mostrada, guardadas pela fala e pelas posições.
  String? _linesKey;
  List<SpeechLine> _lines = const [];

  // Os toques no passo de estrelas, para achar o lance proibido.
  final _illegal = IllegalStarMoves();

  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.component,
  );

  // O cronômetro do passo (T60) e o ritmo da demonstração (T51).
  Timer? _ticker;

  // O tempo decorrido no passo, só para o cronômetro: parado quando o passo
  // é respondido, fica com o tempo final até a transição levar.
  final _elapsed = ValueNotifier(Duration.zero);

  // A folha da fala: a cada passo novo ela volta ao mínimo, para o
  // tabuleiro aparecer inteiro.
  final _sheet = DraggableScrollableController();
  double _sheetMin = 0.3;

  // O tamanho da folha, para o "x". A folha avisa até durante a montagem da
  // tela (quando o passo troca e o tamanho dela é refeito): o aviso passa
  // para depois do quadro.
  final _sheetMoving = ValueNotifier(false);

  // A folha que abre sozinha com o texto novo do Viktor e recolhe depois do
  // tempo de leitura (T65, folha automática). [_visited] guarda o que já foi
  // dito nesta sessão da lição: passo revisto não anima a folha nem digita.
  final _visited = <String>{};
  bool _revisiting = false;
  bool _firstSynced = false;
  bool _autoSettled = false;
  bool _autoOpen = false;
  int _autoGen = 0;
  int _autoLength = 0;
  double? _areaHeight;
  Timer? _autoTimer;
  Duration _autoTotal = Duration.zero;
  Duration? _autoLeft;
  final _autoWatch = Stopwatch();

  // A altura medida dos botões que flutuam embaixo (com a margem acima
  // deles). Começa na prevista, até a primeira medida.
  final _footerHeight = ValueNotifier<double>(_actionsHeight);

  void _onFooterSize(Size size) {
    if (mounted) _footerHeight.value = size.height;
  }

  Duration _demoWait = Duration.zero;

  // O anel do ⏭ da demonstração (-1: falando; nulo: sem anel).
  final _demoRing = ValueNotifier<double?>(null);
  Duration? _lastTickElapsed;
  String? _demoAt;
  String? _ringFor;
  bool _demoSpoke = false;

  bool _background = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state != AppLifecycleState.resumed;
    if (background == _background) {
      return;
    }
    _background = background;
    final cubit = context.read<LessonCubit>();
    final speech = TeacherSpeech.speechOf(context);
    if (background) {
      _pauseAuto();
      unawaited(cubit.pauseForBackground());
      unawaited(speech?.pauseForBackground());
    } else {
      _resumeAuto();
      unawaited(cubit.resumeFromBackground());
      unawaited(speech?.resumeFromBackground());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    // Lição já carregada ao abrir a tela: o ouvinte do estado só fala nas
    // mudanças, então o 1º passo é tratado aqui, depois do 1º quadro.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _previous.ready) return;
      final state = context.read<LessonCubit>().state;
      if (state.ready) _syncSheet(state, _previous);
    });
  }

  void _tick() {
    if (!mounted || _background) {
      return;
    }
    final cubit = context.read<LessonCubit>();
    final state = cubit.state;
    if (state.finished) {
      return;
    }
    final elapsed = cubit.stepElapsed;
    final difference = elapsed - (_lastTickElapsed ?? elapsed);
    final delta = difference.isNegative ? Duration.zero : difference;
    _lastTickElapsed = elapsed;
    if (state.layout == LessonLayoutMode.solving) {
      _elapsed.value = cubit.stepElapsed;
    }
    if (state.presenting && _presentingModal.value) {
      // O relógio do passo está parado na apresentação: o tempo vem do tick.
      _pacePresentation(cubit, state, const Duration(milliseconds: 250));
    }
    switch (state.current) {
      case DemoStep(:final line)
          when state.demoPlaying &&
              !state.offScript &&
              !state.typing &&
              state.demoMove < line.length:
        _paceDemo(cubit, state, delta);
      case DemoStep(:final line) when state.demoMove < line.length:
        _freezeDemo(state);
      default:
        _demoRing.value = null;
    }
  }

  /// Pausada (ou fora do roteiro), a demonstração congela o ritmo (T70, crit.
  /// 19): o anel fica parado onde estava e, ao retomar, a contagem recomeça.
  /// Num lance novo (⏭ ou ⏮ na mão) o anel zera e fica parado.
  void _freezeDemo(LessonState state) {
    _demoAt = null;
    final at = '${state.current!.id}:${state.demoMove}';
    if (_ringFor != at || (_demoRing.value ?? 0) < 0) {
      _ringFor = at;
      _demoRing.value = 0;
    }
  }

  /// A demonstração anda sozinha no ritmo da fala (docs/spikes/T51-ritmo.md):
  /// com a voz, espera ela terminar e mais uma pausa; sem voz, um tempo de
  /// leitura pelo tamanho da fala. A velocidade da voz vale para os dois.
  void _paceDemo(LessonCubit cubit, LessonState state, Duration delta) {
    if (_authoredVariation != null || _variation.value != null) {
      _demoRing.value = null;
      return;
    }
    final at = '${state.current!.id}:${state.demoMove}';
    _ringFor = at;
    if (_demoAt != at) {
      _demoAt = at;
      _demoSpoke = false;
      _demoWait = Duration.zero;
    } else {
      _demoWait += delta;
    }
    final speech = TeacherSpeech.speechOf(context)?.state;
    final speed = speech?.settings.speed ?? 1.0;
    final text = state.speech ?? '';
    // Fala audível: som do app e voz do Viktor ligados. Sem isso, a fala que
    // ainda conste como "em andamento" (botão de áudio, voz presa) não segura
    // a demonstração: vale o tempo de leitura, com teto (T65, §7).
    final audible =
        (context.read<SettingsCubit>().state?.sound ?? true) &&
        (speech?.settings.enabled ?? false);
    if (audible && speech!.isSpeaking(text)) {
      // Ainda falando: o relógio conta a partir do fim da fala.
      _demoSpoke = true;
      _demoWait = Duration.zero;
      _demoRing.value = DemoRing.speaking;
      return;
    }
    final waitMs = DemoPace.waitMs(
      length: text.length,
      spoke: _demoSpoke,
      speed: speed,
    );
    _demoRing.value = (_demoWait.inMilliseconds / waitMs).clamp(0.0, 1.0);
    if (_demoWait.inMilliseconds >= waitMs) {
      _demoAt = null;
      // O lance sai: o anel zera na hora (decisão do orquestrador).
      _demoRing.value = 0;
      unawaited(cubit.demoForward());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _board?.dispose();
    _autoTimer?.cancel();
    _sheet.dispose();
    _sheetMoving.dispose();
    _footerHeight.dispose();
    _shake.dispose();
    _landing.dispose();
    _elapsed.dispose();
    _demoRing.dispose();
    _presentingModal.dispose();
    _flash.dispose();
    _variation.dispose();
    _seenTick.dispose();
    _engineThinking.dispose();
    _branch.dispose();
    _variationSheet.dispose();
    _stage.dispose();
    _cancelEntry();
    super.dispose();
  }

  GameData _gameData(LessonState state) {
    final fen = state.fen!;
    final step = state.current!;
    final side = step.side;
    final player = state.interactive
        ? (side == Side.white ? PlayerSide.white : PlayerSide.black)
        : PlayerSide.none;
    if (step is StarsStep) {
      return GameData(
        fen: fen,
        playerSide: player,
        sideToMove: side,
        validMoves: LessonRules.starsMoves(LessonRules.starsBoard(fen), side),
        lastMove: state.lastMove,
      );
    }
    final position = GameRules.fromFen(fen);
    // Na demonstração (T70, ponto 2) o aluno joga só o lado dele e na vez
    // dele, pausada ou não; o lance pausa a demonstração.
    final demoTurn =
        step is DemoStep &&
        position != null &&
        state.phase == StepPhase.active &&
        !state.typing &&
        position.turn == side;
    return GameData(
      fen: fen,
      playerSide: position == null
          ? PlayerSide.none
          : demoTurn
          ? (side == Side.white ? PlayerSide.white : PlayerSide.black)
          : player,
      sideToMove: position?.turn ?? side,
      validMoves: position == null || (step is DemoStep && !demoTurn)
          ? const {}
          : GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  // O estado anterior, para saber o que mudou.
  LessonState _previous = const LessonState();

  void _onState(BuildContext context, LessonState state) {
    final previous = _previous;
    var cleared = false;
    // O 1º estado (o anterior ainda é o vazio) só povoa a tela: não há
    // variante aberta para fechar.
    if (previous.ready &&
        (state.fen != previous.fen ||
            state.step != previous.step ||
            state.speech != previous.speech ||
            state.layout != previous.layout)) {
      cleared = _authoredVariation != null;
      _authoredVariation = null;
      _branch.value = null;
    }
    _previous = state;
    final cubit = context.read<LessonCubit>();
    if (state.engineErrors > previous.engineErrors) _showEngineError();
    if (state.thinkPlayed == null || state.correct) {
      _wrongHandled = null;
    } else if (_wrongPending(state)) {
      final key = '${state.step}|${state.thinkPlayed}';
      if (_wrongHandled != key) {
        _wrongHandled = key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !context.read<LessonCubit>().isClosed) {
            _enterWrongBranch(context.read<LessonCubit>().state);
          }
        });
      }
    }
    // Resolvendo: o cronômetro já com o tempo do passo (ao reabrir o app, o
    // tabuleiro nasce aqui, antes do primeiro tique). Saindo para a fala, ele
    // fica parado no tempo final até sumir.
    if (state.layout == LessonLayoutMode.solving) {
      _elapsed.value = cubit.stepElapsed;
    }
    if (state.step != previous.step) _illegal.reset();
    final genBefore = _autoGen;
    _syncSheet(state, previous);
    // O estado correto abre sempre na mesma altura (a do texto inteiro),
    // venha do acerto, do "Ver resposta" ou do link (crit. 7).
    if (state.correct &&
        !previous.correct &&
        state.ready &&
        !state.finished &&
        !_presentingModal.value &&
        genBefore == _autoGen) {
      // O acerto já abriu sozinho em _syncSheet; "Ver resposta" e o link
      // abrem aqui, do mesmo jeito (altura do texto, recolhe no tempo).
      _cancelAuto();
      _autoLength = _said(context, state)?.length ?? 0;
      _measureThenOpen(++_autoGen, null, 0);
    }
    // Saiu da Solução vista (Tentar de novo): a folha recolhe até o tabuleiro.
    if (previous.solutionSeen && !state.solutionSeen && _sheet.isAttached) {
      if (AppMotion.of(context).disabled) {
        _sheet.jumpTo(_sheetMin);
      } else {
        _sheet.animateTo(
          _sheetMin,
          duration: AppMotion.of(context).component,
          curve: AppMotion.enter,
        );
      }
    }
    if (state.mistakes > previous.mistakes) _shake.forward(from: 0);
    // O pouso do passo novo.
    if (previous.current != null &&
        state.current?.id != previous.current?.id &&
        !AppMotion.of(context).disabled) {
      _landing.forward(from: 0);
    }
    // A variante aberta sai quando o passo, a posição ou a fala mudam; senão
    // o tabuleiro continua nela.
    if (_variation.value != null) {
      final changed =
          state.step != previous.step ||
          previous.ready &&
              (state.fen != previous.fen ||
                  state.speech != previous.speech ||
                  state.layout != previous.layout);
      if (!changed) {
        return;
      }
      _branch.value = null;
      _variation.value = null;
      _wrongBranch = false;
    }
    if (state.fen == null || state.current == null) {
      return;
    }
    if (_authoredVariation != null) {
      return;
    }
    // Saiu de uma variante da explicação (Voltar, Tentar de novo...): o
    // tabuleiro volta a ser o do passo, com quem joga dele (o da variante é
    // sem toque).
    if (cleared) {
      _board?.updatePosition(
        _gameData(state),
        animate: false,
        resetPremove: true,
      );
    }
    final board = _board;
    if (board == null) {
      _board = ChessboardController(game: _gameData(state));
      return;
    }
    // Sempre redesenha: a peça de um lance recusado volta para a casa dela.
    board.updatePosition(
      _gameData(state),
      animate: previous.step == state.step || previous.fen != state.fen,
      resetPremove: true,
    );
  }

  /// As variantes da fala que o Viktor mostra agora, jogadas a partir da
  /// posição do passo (ou da atual, se for nela que cabem).
  List<SpeechLine> _linesOf(BuildContext context, LessonState state) {
    final step = state.current;
    final text = step == null
        ? null
        : state.layout == LessonLayoutMode.solving
        ? _promptText(context, state, step)
        : _said(context, state);
    if (step == null || text == null) return const [];
    final language = Localizations.localeOf(context).languageCode;
    final marked = WikiMarkup.parse(text).text;
    final bases = [
      for (final fen
          in step is DemoStep ? [state.fen, step.fen] : [step.fen, state.fen])
        ?fen,
    ];
    final key = [language, marked, ...bases].join('\n');
    if (key == _linesKey) return _lines;
    final letters = SpeechLinks.lettersFor(language);
    _linesKey = key;
    _lines = SpeechLines.find(
      SpeechLinks.find(marked, letters),
      letters,
      bases,
    );
    return _lines;
  }

  /// O toque num trecho da fala: o lance de uma variante abre o tabuleiro
  /// nela, com o lance jogado (de novo no mesmo lance, volta ao passo); a
  /// casa, ou o lance que não se joga ali, só se destaca.
  void _onLink(BuildContext context, LessonState state, SpeechLink link) {
    if (state.explanation != null || _authoredVariation != null) {
      final cursor = link.isMove
          ? state.explanation?.cursorForNotation(
              link.text,
              preferred: _authoredVariation?.variation,
            )
          : null;
      final cited = cursor == null ? _citedCursor(context, state, link) : null;
      if (cursor != null) {
        _showAuthoredVariation(cursor);
        return;
      }
      if (cited != null) {
        _showAuthoredVariation(cited.$1);
        _goTo(TreePosition.branch(cited.$2, 1));
        return;
      }
      // A fala do passo mostrada junto da explicação (o passo revisto): o
      // lance é de uma linha citada nela, que abre com as alternativas.
      final spoken = _authoredVariation == null && link.isMove
          ? SpeechLines.lineOf(_linesOf(context, state), link)
          : null;
      if (spoken == null) {
        _flash.toggle(
          link,
          fen: _authoredVariation?.fen ?? state.fen,
          color: Theme.of(context).colorScheme.primary,
        );
        return;
      }
    }
    final line = link.isMove
        ? SpeechLines.lineOf(_linesOf(context, state), link)
        : null;
    if (line != null) {
      final ply = line.plyOf(link)!;
      final open = _variation.value;
      if (open != null && identical(open.line, line) && open.ply == ply) {
        _exitLine();
      } else {
        final step = state.current;
        final letters =
            MoveNotation.letters.pieceLetters(context.l10n) ?? const {};
        final of = step == null
            ? null
            : VariationTreeBuilder.lineOfBranch(step, line, letters);
        if (of == null) {
          _showLine(context, SpeechLineCursor(line, ply));
        } else {
          // O lance solto é o começo de uma alternativa da aula: abre a
          // linha citada na alternativa (recuada, com ? e =).
          final id = of.branch.id;
          _showLine(context, SpeechLineCursor(of.line, of.branch.at));
          _goTo(TreePosition.branch(id, min(ply, of.branch.uci.length)));
        }
      }
      return;
    }
    _flash.toggle(
      link,
      fen: _variation.value?.fen ?? state.fen ?? state.current?.fen,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  List<CitedBranchSource>? _cited;
  Lesson? _citedLesson;

  /// As alternativas citadas da aula (em qualquer passo), para a explicação.
  List<CitedBranchSource> _citedSources(LessonState state) {
    final lesson = state.lesson;
    if (lesson == null) return const [];
    if (!identical(_citedLesson, lesson)) {
      _citedLesson = lesson;
      _cited = VariationTreeBuilder.citedSources(lesson.steps);
    }
    return _cited!;
  }

  /// O toque num lance solto da explicação ("2.g4?") que é o 1º de uma
  /// alternativa citada: a variante da explicação que passa pela posição de
  /// onde ela sai, aberta nesse ponto, e o id da alternativa.
  (VariationCursor, String)? _citedCursor(
    BuildContext context,
    LessonState state,
    SpeechLink link,
  ) {
    final payload = state.explanation;
    if (payload == null || !link.isMove) return null;
    String plain(String value) => value.replaceAll(RegExp(r'[?!\s]'), '');
    final numbered = RegExp(r'^\d+\.').hasMatch(link.text);
    final wanted = plain(link.text);
    final letters = MoveNotation.letters.pieceLetters(context.l10n) ?? const {};
    final variations = [
      ?_authoredVariation?.variation,
      for (final block in payload.explanations) ...block.variations,
    ];
    for (final source in _citedSources(state)) {
      var label = VariationTreeBuilder.firstLabel(source, letters);
      if (label == null) continue;
      label = plain(label);
      if (!numbered) label = label.replaceFirst(RegExp(r'^\d+\.(?:\.\.)?'), '');
      if (label != wanted) continue;
      for (final variation in variations) {
        final cursor = payload.openVariation(variation);
        if (cursor == null) continue;
        for (var ply = 0; ply <= cursor.moves.length; ply++) {
          if (VariationTreeBuilder.placeOf(cursor.fens[ply]) ==
              VariationTreeBuilder.placeOf(source.fen)) {
            return (cursor.at(ply), source.branch.id);
          }
        }
      }
    }
    return null;
  }

  /// O tabuleiro na variante, no lance do [cursor]; a folha sai para baixo
  /// (fica montada, com o tamanho e a rolagem) e a faixa e os controles entram.
  void _showLine(BuildContext context, SpeechLineCursor cursor) {
    _flash.clear();
    final entering = _variation.value == null && _authoredVariation == null;
    // O ramo, o cursor e a árvore mudam juntos, no mesmo quadro.
    _branch.value = null;
    _variation.value = cursor;
    _syncTree();
    _markSeen(_position);
    _enterVariant(entering, () {
      _board?.updatePosition(
        _branchGame() ?? _lineGame(cursor),
        animate: !AppMotion.of(this.context).disabled,
        resetPremove: true,
      );
    });
  }

  /// A árvore da faixa para a variante aberta (guardada enquanto for a mesma).
  VariationTree? _syncTree() {
    final cubit = context.read<LessonCubit>();
    final state = cubit.state;
    final authored = _authoredVariation;
    final line = _variation.value?.line;
    if (authored != null && state.explanation != null) {
      if (!identical(_treeKey, authored.variation)) {
        final lessonId = state.lesson?.id ?? '';
        _tree = VariationTreeBuilder.fromExplanation(
          payload: state.explanation!,
          cursor: authored,
          cited: _citedSources(state),
          letters: MoveNotation.letters.pieceLetters(context.l10n) ?? const {},
          comment: (stepId, id, ply) =>
              state.texts.alternative(lessonId, stepId, id, ply),
        );
        _treeKey = authored.variation;
      }
      _seenId =
          '${state.current?.id}|a|${authored.moves.map((m) => m.uci).join(' ')}';
    } else if (line != null && state.current != null) {
      if (!identical(_treeKey, line)) {
        final step = state.current!;
        final ucis = [for (final move in line.moves) move.uci];
        final cited = step.lines.where((l) => l.matches(ucis)).firstOrNull;
        final lessonId = state.lesson?.id ?? '';
        _tree =
            _lineTrees[line] ??
            VariationTreeBuilder.fromSpeech(
              line: line,
              branches: cited?.branches ?? const [],
              letters:
                  MoveNotation.letters.pieceLetters(context.l10n) ?? const {},
              comment: (id, ply) =>
                  state.texts.alternative(lessonId, step.id, id, ply),
            );
        _treeKey = line;
      }
      _seenId =
          '${state.current!.id}|s|${line.moves.map((m) => m.uci).join(' ')}';
    } else {
      _tree = null;
      _treeKey = null;
      _seenId = null;
    }
    return _tree;
  }

  /// O lance da vez na árvore: o ramo, ou o ponto da linha principal.
  TreePosition? get _position {
    if (_branch.value case final branch?) return branch;
    if (_authoredVariation case final authored?) {
      return TreePosition.main(authored.ply);
    }
    if (_variation.value case final line?) return TreePosition.main(line.ply);
    return null;
  }

  /// O tabuleiro, a faixa e o comentário vão juntos para [target]: o cursor,
  /// o ramo e o tabuleiro mudam no mesmo instante (sem quadro no meio), e a
  /// peça desliza com a animação do tabuleiro (uma só, de onde está até lá).
  void _goTo(TreePosition target) {
    final tree = _syncTree();
    if (tree == null || !tree.contains(target)) return;
    _flash.clear();
    _markSeen(target, animate: true);
    final branch = target.branch == null ? null : tree.branchOf(target.branch!);
    final mainPly = branch?.at ?? target.ply;
    if (_authoredVariation case final authored?) {
      setState(() => _authoredVariation = authored.at(mainPly));
    } else if (_variation.value case final line?) {
      _variation.value = SpeechLineCursor(line.line, mainPly);
    }
    _branch.value = branch == null ? null : target;
    _board?.updatePosition(
      _treeGame(tree, target),
      animate: !AppMotion.of(context).disabled,
      resetPremove: true,
    );
  }

  /// O tabuleiro DEPOIS do lance [target] da árvore (o lance da vez).
  GameData _treeGame(VariationTree tree, TreePosition target) {
    final fen = tree.fenAt(target);
    final position = GameRules.fromFen(fen);
    final student = _studentSide();
    final playable =
        student != null &&
        position != null &&
        position.turn == student &&
        target.branch == null &&
        _variation.value != null &&
        _lineTrees[_variation.value!.line] != null &&
        _seenSet.contains(target);
    return GameData(
      fen: fen,
      playerSide: playable
          ? (student == Side.white ? PlayerSide.white : PlayerSide.black)
          : PlayerSide.none,
      sideToMove: position?.turn ?? Side.white,
      validMoves: playable ? GameRules.legalMoves(position) : const {},
      lastMove: tree.lastMoveAt(target),
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  /// Ao entrar na variante o tabuleiro só anda depois da folha sair; se nesse
  /// meio-tempo o aluno já foi a um ramo, vale a posição dele, não a da
  /// principal (o `showBoard` atrasado desfazia o `_goTo`).
  GameData? _branchGame() {
    final target = _branch.value;
    final tree = _tree;
    if (target == null || tree == null || !tree.contains(target)) return null;
    return _treeGame(tree, target);
  }

  bool get _hideUnseen =>
      context.read<SettingsCubit>().state?.lessonHiddenMoves ?? true;

  Set<TreePosition> get _seenSet =>
      _seenId == null ? const {} : (_seen[_seenId!] ??= {});

  /// [target] e o caminho até ele entram nos lances vistos. Com [animate] e
  /// os lances ocultos ligados, o bloco desliza para fora do que é novo.
  void _markSeen(TreePosition? target, {bool animate = false}) {
    final tree = _tree;
    if (target == null || tree == null || _seenId == null) return;
    if (!tree.contains(target)) return;
    final seen = _seenSet;
    final fresh = tree.pathTo(target).where(seen.add).toList();
    if (fresh.isEmpty) return;
    if (animate && fresh.contains(target) && _hideUnseen) {
      _revealing = (position: target, stamp: (_revealing?.stamp ?? 0) + 1);
    }
    _seenTick.value++;
  }

  /// Toque num bloco: revela o 1º lance coberto no caminho até o 1º lance
  /// coberto da linha, e o tabuleiro vai até ele.
  void _revealRow(int rowIndex) {
    final tree = _tree;
    if (tree == null || rowIndex >= tree.rows.length) return;
    final seen = _seenSet;
    final moves = tree.rows[rowIndex].moves;
    final firstHidden = moves.where((m) => !seen.contains(m.position));
    if (firstHidden.isEmpty) return;
    final path = tree.pathTo(firstHidden.first.position);
    final target = path.firstWhere(
      (p) => !seen.contains(p),
      orElse: () => firstHidden.first.position,
    );
    _goTo(target);
  }

  void _cancelEntry() {
    for (final timer in _entryTimers) {
      timer.cancel();
    }
    _entryTimers.clear();
  }

  /// Entrar na variante: a folha sai (300 ms), o tabuleiro anda, a faixa
  /// entra 100 ms depois e os controles aos 450 ms. Dentro da variante, ou
  /// sem movimento, tudo vale já.
  void _enterVariant(bool entering, VoidCallback showBoard) {
    _cancelEntry();
    if (!entering || AppMotion.of(context).disabled) {
      _speechHeld = false;
      _stage.value = 3;
      showBoard();
      return;
    }
    final sheet = AppMotion.of(context).component;
    _stage.value = 0;
    _speechHeld = true;
    _entryTimers
      ..add(
        Timer(sheet, () {
          if (!mounted) return;
          setState(() => _speechHeld = false);
          showBoard();
          _stage.value = 1;
        }),
      )
      ..add(Timer(sheet + AppMotion.of(context).state, () => _stage.value = 2))
      ..add(
        Timer(
          sheet + AppMotion.of(context).state + AppMotion.of(context).component,
          () => _stage.value = 3,
        ),
      );
  }

  void _showAuthoredVariation(VariationCursor? cursor) {
    // A linha do erro ("3.g4? Rg6 4.g5") é a alternativa da aula: abre a
    // linha citada com a alternativa recuada, com o ? e o =.
    if (cursor != null && _authoredVariation == null) {
      final state = context.read<LessonCubit>().state;
      final step = state.current;
      final of = step == null
          ? null
          : VariationTreeBuilder.lineOfBranch(
              step,
              SpeechLine(
                links: const [],
                fens: cursor.fens,
                moves: cursor.moves,
              ),
              MoveNotation.letters.pieceLetters(context.l10n) ?? const {},
            );
      if (of != null) {
        _showLine(context, SpeechLineCursor(of.line, of.branch.at));
        _goTo(
          TreePosition.branch(
            of.branch.id,
            cursor.ply.clamp(1, of.branch.uci.length),
          ),
        );
        return;
      }
    }
    _flash.clear();
    final entering =
        cursor != null &&
        _variation.value == null &&
        _authoredVariation == null;
    _variation.value = null;
    _branch.value = null;
    if (cursor == null) {
      _cancelEntry();
      _speechHeld = false;
      _stage.value = 0;
    }
    setState(() => _authoredVariation = cursor);
    _syncTree();
    _markSeen(_position);
    final state = context.read<LessonCubit>().state;
    if (cursor == null) {
      _board?.updatePosition(
        _gameData(state),
        animate: true,
        resetPremove: true,
      );
    } else {
      final position = GameRules.fromFen(cursor.fen);
      _enterVariant(entering, () {
        _board?.updatePosition(
          _branchGame() ??
              GameData(
                fen: cursor.fen,
                playerSide: PlayerSide.none,
                sideToMove: position?.turn ?? Side.white,
                validMoves: const {},
                lastMove: cursor.lastMove,
                kingSquareInCheck: position == null
                    ? null
                    : GameRules.checkedKing(position),
              ),
          animate: !AppMotion.of(context).disabled,
          resetPremove: true,
        );
      });
    }
  }

  /// Fecha a variante: o tabuleiro volta à posição do passo.
  void _exitLine() {
    if (_variation.value == null) {
      return;
    }
    _cancelEntry();
    _stage.value = 0;
    _branch.value = null;
    _variation.value = null;
    _wrongBranch = false;
    _syncTree();
    final state = context.read<LessonCubit>().state;
    if (state.fen == null || state.current == null) {
      return;
    }
    _board?.updatePosition(_gameData(state), animate: true, resetPremove: true);
  }

  /// A linha mostrada no tabuleiro é a errada da aula: a variante aberta
  /// que o JSON do passo marca, ou a demonstração marcada.
  bool _wrongShown(LessonState state) {
    if (_branch.value != null) return false;
    if (_wrongBranch && _variation.value != null) return true;
    final cursor = _variation.value;
    if (cursor == null) return state.wrongDemo;
    return state.current?.wrongLine([
          for (final move in cursor.line.moves) move.uci,
        ]) ??
        false;
  }

  /// A fala do Viktor no estado: a genérica do app quando o lance errado
  /// não tem explicação própria.
  String? _said(BuildContext context, LessonState state) {
    // Lance errado no passo de pensar: a explicação começa pelo lance dele.
    if (state.thinkMistake case final san?) {
      final l10n = context.l10n;
      final letters = MoveNotation.letters.pieceLetters(l10n)!;
      final local = san.replaceAllMapped(
        RegExp('[KQRBN]'),
        (match) => letters[match[0]] ?? match[0]!,
      );
      return [
        l10n.lessonThinkMistakeGeneric(local),
        ?state.speech,
      ].join('\n\n');
    }
    return _baseSpeech(context, state);
  }

  String? _baseSpeech(BuildContext context, LessonState state) {
    final noted = _noteText(context, state, state.current);
    if (noted != null) return noted;
    if (!state.genericMistake) return state.speech;
    final lesson = state.lesson;
    final part = state.part;
    final topic = lesson == null
        ? ''
        : part == null
        ? state.texts.lessonTitle(lesson.id)
        : state.texts.partTitle(lesson.id, part.id) ??
              state.texts.lessonTitle(lesson.id);
    return context.l10n.lessonMistakeGeneric(topic);
  }

  /// A posição da variante no tabuleiro: só de olhar, com o último lance
  /// marcado.
  static GameData _lineGame(SpeechLineCursor cursor) {
    final position = GameRules.fromFen(cursor.fen);
    return GameData(
      fen: cursor.fen,
      playerSide: PlayerSide.none,
      sideToMove: position?.turn ?? Side.white,
      validMoves: const {},
      lastMove: cursor.lastMove,
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LessonCubit>();
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.leave();
      },
      child: BlocConsumer<LessonCubit, LessonState>(
        listener: _onState,
        builder: (context, state) {
          if (state.fen != null && state.current != null && _board == null) {
            _board = ChessboardController(game: _gameData(state));
            _elapsed.value = cubit.stepElapsed;
          }
          final lesson = state.lesson;
          return Scaffold(
            key: LessonKeys.screen,
            appBar: LucenaAppBar(
              // Só o título (da parte, na aula em partes, ou da aula),
              // centralizado: sem contador "1/5" no canto (Gabriel,
              // 2026-10-13). Na escola, o iniciante não vê quantas faltam.
              // Na formatura, a barra fica limpa: não é mais uma aula.
              title: lesson == null || state.courseFinished
                  ? null
                  : Text(
                      state.part == null
                          ? state.texts.lessonTitle(lesson.id)
                          : state.texts.partTitle(lesson.id, state.part!.id) ??
                                '',
                      key: LessonKeys.appBarTitle,
                      // Título comprido (ou idioma mais longo) desce para a
                      // segunda linha, menor, em vez de cortar.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
              // A barra contínua no pé da AppBar: some no fim da parte e na
              // formatura (PartFinished fica como na V1).
              bottom:
                  state.ready &&
                      !state.missing &&
                      !state.finished &&
                      !state.courseFinished &&
                      state.current != null
                  ? _progressBar(context, state)
                  : null,
            ),
            body: BoardViewport(
              usefulHeight: BoardViewport.usefulHeightOf(context),
              child: SafeArea(child: _body(context, state, boardSettings)),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _progressBar(BuildContext context, LessonState state) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(4),
      child: Semantics(
        label: context.l10n.lessonStep(state.step + 1, state.stepCount),
        child: ExcludeSemantics(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: state.progress.clamp(0.0, 1.0)),
            duration: AppMotion.of(context).component,
            curve: AppMotion.enter,
            builder: (context, value, _) => LinearProgressIndicator(
              key: LessonKeys.progress,
              value: value,
              minHeight: 4,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    LessonState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    if (!state.ready) return const SizedBox.shrink();
    if (state.missing) {
      return Center(child: Text(l10n.lessonMissing, key: LessonKeys.missing));
    }
    final viktor = state.viktor;
    final step = state.current!;
    final theme = Theme.of(context);
    final board = _board;
    final hasBoard = state.fen != null && board != null;
    // O prático novo (T70): move/play no layout da tela de exercício.
    final practice =
        context.read<LessonCubit>().practiceV2 &&
        !state.finished &&
        (step is MoveStep || step is PlayStep);
    // Fora do AnimatedSwitcher: o esmaecer montaria dois tabuleiros no mesmo
    // controlador.
    if (practice && viktor != null && hasBoard) {
      return _practice(context, state, viktor, boardSettings, board);
    }
    // Entre as partes não há tela de fim: fade direto para o 1º passo da
    // próxima (crit. 18). Só a última parte termina na tela de fim.
    final advancing =
        state.finished && state.part != null && state.nextPart != null;
    if (advancing) _advancePart();
    return AnimatedSwitcher(
      duration: AppMotion.component,
      child: advancing
          ? const SizedBox.expand(key: ValueKey('advancing-part'))
          : state.finished && state.part != null
          ? PartFinished(key: LessonKeys.finished, state: state)
          : state.finished
          ? LessonFinished(key: LessonKeys.finished, state: state)
          : LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Column(
                    children: [
                      SizedBox.shrink(
                        key: LessonKeys.step(state.lesson!.id, step.id),
                      ),
                      // 12 dp entre a barra e o tabuleiro: topo em 80 dp.
                      const SizedBox(height: 12),
                      if (hasBoard) ...[
                        Expanded(
                          child: _exerciseArea(
                            context,
                            state,
                            step,
                            viktor,
                            boardSettings,
                            board,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) => Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.school_outlined,
                                    size: 96,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: .18,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: ValueListenableBuilder(
                                    valueListenable: _footerHeight,
                                    builder: (context, footer, _) =>
                                        ViktorSheet(
                                          key: LessonKeys.viktorSheet,
                                          top: box.maxHeight * .4,
                                          controller: _sheet,
                                          scrollKey: LessonKeys.scroll,
                                          closeKey: LessonKeys.closeSheet,
                                          onMinimumChanged: (value) =>
                                              _sheetMin = value,
                                          onMoving: (value) =>
                                              _sheetMoving.value = value,
                                          padding: EdgeInsets.only(
                                            bottom: footer + _endGap,
                                          ),
                                          children: [
                                            _speechSheet(
                                              context,
                                              state,
                                              step,
                                              viktor,
                                            ),
                                          ],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Os botões flutuam sobre a tela: a fala usa a altura
                  // toda e passa por baixo deles. Resolvendo, o rodapé é o
                  // cronômetro e as ações do passo; respondido, troca num
                  // esmaecer, com o cronômetro parado no tempo final.
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    // A altura de verdade dos botões (com a margem acima
                    // deles): a fala termina antes dela.
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        _sheetMoving,
                        _variation,
                        _presentingModal,
                        _stage,
                        _branch,
                      ]),
                      builder: (context, _) {
                        final variation = _variation.value;
                        final authored = _authoredVariation;
                        final variantOn = variation != null || authored != null;
                        // Entrando na variante, o rodapé da demo sai junto
                        // com a folha e os controles novos só aparecem aos
                        // 450 ms (etapa 3): nada fica parado no meio.
                        final entering = variantOn && _stage.value < 3;
                        final covered =
                            _sheetMoving.value ||
                            _presentingModal.value ||
                            entering;
                        final inVariant = variantOn && _stage.value >= 1;
                        // Na apresentação B o rodapé nasce oculto: sem
                        // animação de saída por cima do modal.
                        final hideTime = _presentingModal.value
                            ? Duration.zero
                            : AppMotion.of(context).component;
                        // Os botões saem só enquanto a folha anda (arrasto
                        // ou animação) e voltam quando ela para, recolhida
                        // ou aberta: a fala rola por baixo deles.
                        return IgnorePointer(
                          ignoring: covered,
                          child: ExcludeSemantics(
                            excluding: covered,
                            child: AnimatedSlide(
                              duration: hideTime,
                              curve: AppMotion.exit,
                              offset: covered
                                  ? const Offset(0, 1)
                                  : Offset.zero,
                              child: AnimatedOpacity(
                                duration: hideTime,
                                opacity: covered ? 0 : 1,
                                child: _SizeReporter(
                                  onSize: _onFooterSize,
                                  child: AnimatedSwitcher(
                                    // 100 ms saindo e 100 ms entrando: o
                                    // rodapé antigo nunca cobre o texto novo.
                                    duration: AppMotion.of(context).state,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation.drive(
                                            CurveTween(
                                              curve: const Interval(.5, 1),
                                            ),
                                          ),
                                          child: child,
                                        ),
                                    child: KeyedSubtree(
                                      key: ValueKey((
                                        state.layout,
                                        inVariant,
                                        state.correct,
                                        _wrongBranch,
                                      )),
                                      child: inVariant
                                          ? KeyedSubtree(
                                              key: LessonKeys.footer,
                                              child: VariationControls(
                                                canPrevious: _canStep(
                                                  previous: true,
                                                ),
                                                canNext: _canStep(
                                                  previous: false,
                                                ),
                                                // No erro do pensar o selo
                                                // fica só no cabeçalho da
                                                // folha (canvas 1.2).
                                                wrong:
                                                    _wrongShown(state) &&
                                                    !_wrongBranch,
                                                primaryAction: _wrongBranch
                                                    ? VariationPrimaryAction(
                                                        label: context
                                                            .l10n
                                                            .lessonShowAnswer,
                                                        onPressed:
                                                            _answerFromBranch,
                                                      )
                                                    : null,
                                                inBranch: _branch.value != null,
                                                onExit: () => variation != null
                                                    ? _exitLine()
                                                    : _showAuthoredVariation(
                                                        null,
                                                      ),
                                                onBack: () =>
                                                    _step(previous: true),
                                                onForward: () =>
                                                    _step(previous: false),
                                              ),
                                            )
                                          : _isThinkPrompt(state) ||
                                                _thinkOrigin(state)
                                          ? _thinkFooter(context, state)
                                          : state.layout ==
                                                    LessonLayoutMode.solving &&
                                                !state.wrongMove
                                          ? _solvingFooter(context, state)
                                          : _actions(context, state),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// O convite e o passo prático (T70, crit. 10 a 16): sem folha nem faixa.
  /// Rodapé: Dica | Voltar, e Continuar depois do 1º lance (refaz o par
  /// desfeito ou, no fim do passo, segue).
  Widget _practice(
    BuildContext context,
    LessonState state,
    Character viktor,
    BoardSettings boardSettings,
    ChessboardController board,
  ) {
    final cubit = context.read<LessonCubit>();
    final canContinue = state.canRedo || state.phase == StepPhase.done;
    return LessonPractice(
      key: ValueKey(('practice', state.step)),
      viktor: viktor,
      invite: state.practiceGate,
      comment: state.practiceComment ?? _baseSpeech(context, state),
      hint: state.practiceHint,
      typing: state.typing,
      expanded: state.speechMode == SpeechMode.expanded,
      onExpandedChanged: (open) =>
          open ? cubit.expandSpeech() : cubit.collapseSpeech(),
      onStart: cubit.startPractice,
      onInviteBack: cubit.practiceInviteBack,
      onHint: cubit.askHint,
      onBack: cubit.practiceBack,
      onContinue: canContinue
          ? (state.canRedo ? cubit.practiceForward : cubit.next)
          : null,
      board: (context, size) =>
          _boardArea(context, state, boardSettings, board, size: size),
    );
  }

  /// The board stays high in every lesson state, solving too (D15; the
  /// centre rule of the play screens excludes lessons): top [gutter] below
  /// the progress bar, as wide as the screen minus the gutters, and the
  /// Viktor sheet with the rest of the screen.
  Widget _exerciseArea(
    BuildContext context,
    LessonState state,
    LessonStep step,
    Character? viktor,
    BoardSettings boardSettings,
    ChessboardController board,
  ) => LayoutBuilder(
    builder: (context, box) {
      final area = Size(box.maxWidth, box.maxHeight);
      _areaHeight = box.maxHeight;
      final side = ExerciseLayout.boardSize(area, footer: _sheetPeek);
      final rect = Rect.fromLTWH(
        (area.width - side) / 2,
        ExerciseLayout.gutter,
        side,
        side,
      );
      _openSolutionSheet(
        state,
        box.maxHeight - rect.bottom - ExerciseLayout.gutter,
      );
      _openPresentation(context, state, step, area, rect);
      return Stack(
        children: [
          Positioned.fromRect(
            rect: rect,
            child: _boardArea(
              context,
              state,
              boardSettings,
              board,
              size: rect.width,
            ),
          ),
          // A linha errada: o tabuleiro com a borda na cor de erro e o selo
          // sobre a borda de cima.
          Positioned.fromRect(
            rect: rect,
            child: IgnorePointer(
              child: ValueListenableBuilder(
                valueListenable: _variation,
                builder: (context, _, _) {
                  if (!_wrongShown(state) || _wrongBranch) {
                    return const SizedBox.shrink();
                  }
                  final error = Theme.of(context).colorScheme.error;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: error, width: 3),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: -14,
                        start: 0,
                        end: 0,
                        child: Center(
                          child: WrongLineBadge(key: LessonKeys.wrongLine),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: ValueListenableBuilder(
              valueListenable: _variation,
              builder: (context, line, child) {
                final motion = AppMotion.of(context);
                final variant = line != null || _authoredVariation != null;
                _trackSheetScroll(variant);
                // A folha sai para baixo e fica montada: o tamanho e a
                // rolagem voltam como estavam ao fechar a variante.
                return AnimatedSlide(
                  offset: variant ? const Offset(0, 1) : Offset.zero,
                  duration: motion.component,
                  curve: variant ? AppMotion.exit : AppMotion.enter,
                  child: IgnorePointer(
                    ignoring: variant,
                    child: ExcludeSemantics(excluding: variant, child: child),
                  ),
                );
              },
              child: ValueListenableBuilder(
                valueListenable: _footerHeight,
                builder: (context, footer, _) => ListenableBuilder(
                  listenable: _presentingModal,
                  // Na apresentação B não há rodapé: o texto vai até o fim.
                  builder: (context, _) => Listener(
                    behavior: HitTestBehavior.deferToChild,
                    onPointerDown: (_) => _onSheetPointerDown(),
                    child: ViktorSheet(
                      key: LessonKeys.viktorSheet,
                      top: rect.bottom + ExerciseLayout.gutter,
                      controller: _sheet,
                      scrollKey: LessonKeys.scroll,
                      closeKey: _presentingModal.value
                          ? LessonKeys.presentationClose
                          : LessonKeys.closeSheet,
                      closeTooltip: _presentingModal.value
                          ? context.l10n.lessonPresentationClose
                          : null,
                      modalKey: _presentingModal.value
                          ? LessonKeys.presentation
                          : null,
                      onMinimumChanged: (value) => _sheetMin = value,
                      // Recolhida, o texto vai até a barra de controles; a
                      // folga final (_endGap) só pesa ao rolar até o fim.
                      collapsedInset: _presentingModal.value ? 0 : footer,
                      onMoving: (value) => _sheetMoving.value = value,
                      onExpanded: _onSheetExpanded,
                      padding: EdgeInsets.only(
                        bottom: (_presentingModal.value ? 0 : footer) + _endGap,
                      ),
                      children: [
                        KeyedSubtree(
                          key: _speechContent,
                          child: _speechSheet(context, state, step, viktor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // A faixa da variante (T68): uma segunda folha do Viktor, só no
          // modo variante, com as linhas de lances e o comentário. Recolhida
          // logo abaixo do tabuleiro; arrastada, abre até perto do alto.
          ListenableBuilder(
            listenable: Listenable.merge([
              _variation,
              _branch,
              _stage,
              _footerHeight,
              _seenTick,
              _engineThinking,
            ]),
            builder: (context, _) {
              final strip = _stage.value >= 2 ? _stripOf(context, state) : null;
              final on = _variation.value != null || _authoredVariation != null;
              if (!on) {
                return const Positioned(width: 0, height: 0, child: SizedBox());
              }
              return Positioned.fill(
                child: AnimatedOpacity(
                  opacity: strip == null ? 0 : 1,
                  duration: AppMotion.of(context).state,
                  child: IgnorePointer(
                    ignoring: strip == null,
                    child: LayoutBuilder(
                      builder: (context, box) => ViktorSheet(
                        key: LessonKeys.variationSheet,
                        top: rect.bottom + ExerciseLayout.gutter,
                        controller: _variationSheet,
                        scrollKey: LessonKeys.variationStripScroll,
                        closeKey: LessonKeys.variationSheetClose,
                        closeTooltip: context.l10n.lessonPresentationClose,
                        padding: EdgeInsets.only(
                          bottom: _footerHeight.value + _endGap,
                        ),
                        children: [
                          // O selo único do erro do pensar (canvas 1.2).
                          if (strip != null && _wrongBranch)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: WrongLineBadge(
                                  key: LessonKeys.wrongLine,
                                  label: context.l10n.lessonIncorrectMove,
                                ),
                              ),
                            ),
                          if (strip != null)
                            Builder(
                              builder: (context) {
                                final hide = context.select(
                                  (SettingsCubit cubit) =>
                                      cubit.state?.lessonHiddenMoves ?? true,
                                );
                                return VariationStrip(
                                  key: LessonKeys.variationStrip,
                                  tree: strip.tree,
                                  position: strip.position,
                                  text: strip.text,
                                  typing: _engineThinking.value,
                                  onSelect: _goTo,
                                  hideUnseen: hide,
                                  revealed: _seenSet,
                                  revealing: _revealing,
                                  onReveal: _revealRow,
                                  onToggleHidden: () => context
                                      .read<SettingsCubit>()
                                      .setLessonHiddenMoves(hidden: !hide),
                                  // Folha recolhida: do alto dela ao rodapé,
                                  // menos a alça (12), o respiro de cima (8)
                                  // e o corte de 4 dp da máscara.
                                  maxHeight: max(
                                    120.0,
                                    box.maxHeight -
                                        (rect.bottom + ExerciseLayout.gutter) -
                                        _footerHeight.value -
                                        _endGap -
                                        24 -
                                        (_wrongBranch ? 40 : 0),
                                  ),
                                );
                              },
                            )
                          else
                            const SizedBox(width: double.infinity),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );

  /// O que a faixa da variante mostra: a árvore, o lance da vez e o texto
  /// (no ramo, o dele ou o da alternativa; na linha principal, na fala o
  /// parágrafo que cita a linha e na explicação o do lance).
  ({VariationTree tree, TreePosition position, String text})? _stripOf(
    BuildContext context,
    LessonState state,
  ) {
    final tree = _syncTree();
    final position = _position;
    if (tree == null || position == null) return null;
    if (tree.commentAt(position) case final comment?) {
      return (
        tree: tree,
        position: position,
        text: WikiMarkup.parse(comment).text,
      );
    }
    final authored = _authoredVariation;
    if (authored != null) {
      return (
        tree: tree,
        position: position,
        text: authored.texts.isEmpty
            ? ''
            : WikiMarkup.parse(authored.texts.first).text,
      );
    }
    final line = _variation.value;
    if (line == null) return null;
    if (_lineTexts[line.line] case final texts? when position.branch == null) {
      final at = position.ply - 1;
      return (
        tree: tree,
        position: position,
        text: at >= 0 && at < texts.length ? texts[at] : '',
      );
    }
    final step = state.current;
    final said = step == null
        ? null
        : state.layout == LessonLayoutMode.solving
        ? _promptText(context, state, step)
        : _said(context, state);
    final marked = WikiMarkup.parse(said ?? '').text;
    final first = line.line.links.first.text;
    final paragraphs = marked.split('\n').where((p) => p.trim().isNotEmpty);
    return (
      tree: tree,
      position: position,
      text: paragraphs.firstWhere(
        (p) => p.contains(first),
        orElse: () => paragraphs.isEmpty ? '' : paragraphs.first,
      ),
    );
  }

  bool _canStep({required bool previous}) {
    final tree = _tree;
    final position = _position;
    if (tree == null || position == null) return false;
    return previous ? tree.canPrevious(position) : tree.canNext(position);
  }

  void _step({required bool previous}) {
    final tree = _tree;
    final position = _position;
    if (tree == null || position == null) return;
    _goTo(previous ? tree.previous(position) : tree.next(position));
  }

  /// A folha na troca de estado. Passo novo, lance jogado ou fala trocada:
  /// a folha volta ao mínimo no mesmo quadro da troca (sem transição, sem
  /// quadro com o texto antigo numa altura intermediária). Texto novo do
  /// Viktor, ainda não visto nesta sessão, abre a folha com ele todo.
  void _syncSheet(LessonState state, LessonState previous) {
    final stepChanged = state.step != previous.step;
    final layoutChanged =
        state.layout != previous.layout ||
        state.wrongMove != previous.wrongMove;
    if (stepChanged) _statementShown = false;
    if (stepChanged ||
        (_autoOpen && (state.fen != previous.fen || layoutChanged))) {
      _cancelAuto();
      _snapSheet();
    }
    final entered = !previous.ready && state.ready && !_firstSynced;
    if (!previous.ready && !entered) return;
    if (entered) _firstSynced = true;
    if (!state.ready || !(entered || stepChanged || layoutChanged)) return;
    final step = state.current;
    if (step == null) return;
    // Entrar no passo vale pelo passo (revisto não anima); dentro do mesmo
    // passo, vale pela fala nova (explicação, lance errado).
    final layoutKey = 'L:${step.id}|${state.layout.name}|${state.wrongMove}';
    final bool isNew;
    if (entered || stepChanged) {
      isNew = _visited.add('S:${step.id}');
      _visited.add(layoutKey);
    } else {
      isNew = _visited.add(layoutKey);
    }
    _revisiting = !isNew;
    if (!isNew ||
        state.viktor == null ||
        state.fen == null ||
        _board == null ||
        state.finished ||
        state.solutionSeen) {
      return;
    }
    final prompting =
        state.layout == LessonLayoutMode.solving && !state.wrongMove;
    final text = prompting
        ? _promptText(context, state, step)
        : _said(context, state);
    _autoLength = text?.length ?? 0;
    // Pensar: a folha mede o enunciado inteiro para abrir (A1); recolhida,
    // volta à frase curta (A2).
    if (prompting && step is ThinkStep) _forceStatement = true;
    _measureThenOpen(++_autoGen, null, 0);
  }

  bool _advancing = false;

  void _advancePart() {
    if (_advancing) return;
    _advancing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<LessonCubit>().continueToNextPart();
      _advancing = false;
    });
  }

  bool _variantWas = false;
  double? _savedScroll;

  /// Fechar o ramo devolve a folha na mesma rolagem de antes de abri-lo.
  void _trackSheetScroll(bool variant) {
    if (variant == _variantWas) return;
    _variantWas = variant;
    final position = _sheetScrollPosition();
    if (variant) {
      _savedScroll = position?.pixels;
      return;
    }
    final saved = _savedScroll;
    _savedScroll = null;
    if (saved == null) return;
    void restore() {
      final position = _sheetScrollPosition();
      if (!mounted || position == null || !position.hasContentDimensions) {
        return;
      }
      final target = saved.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((position.pixels - target).abs() > .5) position.jumpTo(target);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      restore();
      WidgetsBinding.instance.addPostFrameCallback((_) => restore());
    });
  }

  ScrollPosition? _sheetScrollPosition() {
    final context = _speechContent.currentContext;
    return context == null ? null : Scrollable.maybeOf(context)?.position;
  }

  void _snapSheet() {
    if (_sheet.isAttached && _sheet.size > _sheetMin + .001) {
      _sheet.jumpTo(_sheetMin);
    }
  }

  /// O toque na folha: cancela o recolhimento; se ela repousava aberta pelo
  /// tamanho do texto, volta a contar como em movimento (arrasto).
  void _onSheetPointerDown() {
    final settled = _autoSettled;
    _cancelAuto();
    if (settled) _sheetMoving.value = true;
  }

  void _cancelAuto() {
    _autoGen++;
    // A medida do enunciado inteiro acabou junto com a abertura.
    if (_forceStatement && mounted) setState(() => _forceStatement = false);
    _autoOpen = false;
    _autoSettled = false;
    _autoTimer?.cancel();
    _autoTimer = null;
    _autoLeft = null;
    _autoWatch.stop();
  }

  /// Mede o conteúdo da folha quadro a quadro até parar de mudar (o texto
  /// novo entra com um AnimatedSize) e então abre.
  void _measureThenOpen(int gen, double? last, int tries) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _autoGen) return;
      final height = _speechContent.currentContext?.size?.height;
      final ready = _sheet.isAttached && height != null;
      if (ready && last != null && (height - last).abs() < .5) {
        _openAuto(height);
        return;
      }
      if (tries >= 60) {
        _clearForce();
        return;
      }
      _measureThenOpen(gen, ready ? height : null, tries + 1);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _openAuto(double content) {
    final area = _areaHeight;
    if (area == null || area <= 0 || _presentingModal.value) {
      _clearForce();
      return;
    }
    final fixed = _handleHeight + content + _footerHeight.value;
    // Cabe na folha recolhida: ela não abre.
    if (fixed / area <= _sheetMin + .001) {
      _clearForce();
      return;
    }
    final ceiling = max(_sheetMin, 1 - ViktorSheet.openGap / area);
    final target = ((fixed + _endGap) / area)
        .clamp(_sheetMin, ceiling)
        .toDouble();
    if (target <= _sheetMin + .03) {
      _clearForce();
      return;
    }
    final byUser = _autoUser;
    _autoOpen = !byUser;
    final gen = _autoGen;
    void settled() {
      _clearForce();
      // Aberta no tamanho do texto (nem recolhida nem no máximo): os botões
      // ficam à vista, já que a folha parou.
      if (!mounted || !_autoOpen || gen != _autoGen) return;
      _autoSettled = true;
      _sheetMoving.value = false;
    }

    if (AppMotion.of(context).disabled) {
      _sheet.jumpTo(target);
      WidgetsBinding.instance.addPostFrameCallback((_) => settled());
    } else {
      unawaited(
        _sheet
            .animateTo(
              target,
              duration: AppMotion.of(context).panel,
              curve: AppMotion.enter,
            )
            .then((_) => settled()),
      );
    }
    if (!byUser) _startAutoTimer(ViktorSheet.readingTime(_autoLength));
  }

  void _startAutoTimer(Duration left) {
    _autoTimer?.cancel();
    _autoTotal = left;
    _autoLeft = null;
    _autoWatch
      ..reset()
      ..start();
    _autoTimer = Timer(left, _autoCollapse);
  }

  void _autoCollapse() {
    _autoTimer = null;
    if (!mounted || !_autoOpen) return;
    _autoOpen = false;
    _autoSettled = false;
    if (!_sheet.isAttached) return;
    if (AppMotion.of(context).disabled) {
      _sheet.jumpTo(_sheetMin);
    } else {
      unawaited(
        _sheet.animateTo(
          _sheetMin,
          duration: AppMotion.of(context).component,
          curve: AppMotion.enter,
        ),
      );
    }
  }

  void _pauseAuto() {
    if (!_autoOpen || !(_autoTimer?.isActive ?? false)) return;
    _autoTimer!.cancel();
    _autoTimer = null;
    _autoWatch.stop();
    final left = _autoTotal - _autoWatch.elapsed;
    _autoLeft = left.isNegative ? Duration.zero : left;
  }

  void _resumeAuto() {
    final left = _autoLeft;
    if (!_autoOpen || left == null) return;
    _startAutoTimer(left);
  }

  /// Apresentação do passo (T65 §8): mede o objetivo e decide. Cabe entre o
  /// tabuleiro e o rodapé (A): o painel fica parado e o relógio corre já. Não
  /// cabe (B): a folha abre cobrindo o tabuleiro, sem rodapé nem relógio.
  void _openPresentation(
    BuildContext context,
    LessonState state,
    LessonStep step,
    Size area,
    Rect rect,
  ) {
    if (!state.presenting) {
      _presentHandled = false;
      if (_presentingModal.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _endPresentation(instant: true);
        });
      }
      return;
    }
    if (_presentHandled) return;
    _presentHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<LessonCubit>();
      // Cabe: tudo o que a folha mostra (cabeçalho, contexto e objetivo,
      // medido na tela) entre o tabuleiro e o rodapé, com a alça no alto.
      final content = _speechContent.currentContext?.size?.height;
      final fits =
          content == null ||
          rect.bottom +
                  ExerciseLayout.gutter +
                  _handleHeight +
                  content +
                  _footerHeight.value +
                  _endGap <=
              area.height;
      if (fits || !cubit.state.presenting) {
        unawaited(cubit.startStepClock());
        return;
      }
      _presentWait = Duration.zero;
      _presentSpoke = false;
      _presentExpanded = false;
      _cancelAuto();
      _presentingModal.value = true;
      if (!_sheet.isAttached) return;
      // A folha sobe até a altura do texto (alça, conteúdo e respiro final),
      // no máximo até os 76 dp livres no alto (LICOES-V2 §5, §8).
      final ceiling = 1 - ViktorSheet.openGap / area.height;
      final wanted = (_handleHeight + content + _endGap) / area.height;
      // Texto curto: a folha ainda sobe um pouco, para ser o modal com o X
      // (abrir é passar de 3% do mínimo).
      final target = wanted
          .clamp(min(_sheetMin + .04, ceiling), ceiling)
          .toDouble();
      if (AppMotion.of(context).disabled) {
        _sheet.jumpTo(target);
        _presentExpanded = true;
      } else {
        unawaited(
          _sheet
              .animateTo(
                target,
                duration: AppMotion.of(context).panel,
                curve: AppMotion.enter,
              )
              .then((_) {
                if (mounted && _presentingModal.value) {
                  _presentExpanded = true;
                }
              }),
        );
      }
    });
  }

  /// Fim da apresentação B: a folha diminui até o tabuleiro, o rodapé entra
  /// e o relógio começa.
  void _endPresentation({bool instant = false}) {
    if (!_presentingModal.value) return;
    _presentingModal.value = false;
    if (_sheet.isAttached && _sheet.size > _sheetMin + .01) {
      // Fim por lance jogado: sem transição, para o enunciado antigo não
      // aparecer com a folha numa altura intermediária.
      if (instant || AppMotion.of(context).disabled) {
        _sheet.jumpTo(_sheetMin);
      } else {
        _sheet.animateTo(
          _sheetMin,
          duration: AppMotion.of(context).component,
          curve: AppMotion.enter,
        );
      }
    }
    unawaited(context.read<LessonCubit>().startStepClock());
  }

  /// A folha abriu ou fechou: na apresentação B, abrir arma o fim e
  /// recolher (o X) encerra.
  void _onSheetExpanded(bool expanded) {
    if (!expanded && _statementShown && mounted) {
      setState(() => _statementShown = false);
    }
    if (!_presentingModal.value) return;
    if (expanded) {
      _presentExpanded = true;
    } else if (_presentExpanded) {
      _endPresentation();
    }
  }

  /// A apresentação acaba com a fala (ou, sem voz, no tempo de leitura).
  void _pacePresentation(LessonCubit cubit, LessonState state, Duration delta) {
    if (!_presentExpanded) return;
    // Demonstração pausada congela também o recolhimento da folha (T70).
    if (state.current is DemoStep && !state.demoPlaying) return;
    final speech = TeacherSpeech.speechOf(context)?.state;
    final text = state.step < 0
        ? ''
        : (_promptText(context, state, state.current!) ?? '');
    final audible =
        (context.read<SettingsCubit>().state?.sound ?? true) &&
        (speech?.settings.enabled ?? false);
    if (audible && speech!.isSpeaking(text)) {
      _presentSpoke = true;
      _presentWait = Duration.zero;
      return;
    }
    _presentWait += delta;
    final waitMs = DemoPace.waitMs(
      length: text.length,
      spoke: _presentSpoke,
      speed: speech?.settings.speed ?? 1.0,
    );
    if (_presentWait.inMilliseconds >= waitMs) _endPresentation();
  }

  /// Solução vista em tela baixa (T65 §4, E6): se entre o tabuleiro e o
  /// rodapé de 2 linhas sobra menos que o cabeçalho (64) e 4 linhas de texto
  /// (160 dp), a folha abre expandida, como modal sobre o tabuleiro; o X
  /// recolhe até a borda dele.
  void _openSolutionSheet(LessonState state, double below) {
    if (!state.solutionSeen) {
      _solutionHandled = false;
      return;
    }
    if (_solutionHandled) return;
    _solutionHandled = true;
    if (below - _solutionFooterHeight >= _solutionMinSheet) return;
    _expandSolutionSheet(attempts: 5);
  }

  /// Abre a folha até o máximo. A folha pode ainda não estar ligada ao
  /// controle neste quadro, ou um relayout (o rodapé que cresce) pode
  /// devolvê-la ao mínimo no meio da animação: tenta de novo, sem desistir
  /// da primeira vez (ao vivo, no aparelho, a folha ficava recolhida).
  void _expandSolutionSheet({required int attempts}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          attempts <= 0 ||
          !context.read<LessonCubit>().state.solutionSeen) {
        return;
      }
      if (!_sheet.isAttached) {
        _expandSolutionSheet(attempts: attempts - 1);
        return;
      }
      // O modal abre do começo: cabeçalho e respiro antes da 1ª linha, não o
      // texto rolado rente à borda pela fala revelada com a folha recolhida.
      final content = _speechContent.currentContext;
      if (content != null && content.mounted) {
        final position = Scrollable.maybeOf(content)?.position;
        if (position != null && position.pixels > 0) position.jumpTo(0);
      }
      if (AppMotion.of(context).disabled) {
        _sheet.jumpTo(1);
        return;
      }
      // O controle limita ao tamanho máximo da folha.
      _sheet
          .animateTo(
            1,
            duration: AppMotion.of(context).component,
            curve: AppMotion.enter,
          )
          .then((_) {
            if (!mounted || !_sheet.isAttached) return;
            if (_sheet.size <= _sheetMin + .02) {
              _expandSolutionSheet(attempts: attempts - 1);
            }
          });
    });
  }

  bool _solutionHandled = false;

  /// Rodapé da Solução vista: 12 + 48 + 12 + 48 + 24 (LICOES-V2 §4).
  static const _solutionFooterHeight = 144.0;

  /// Cabeçalho do Viktor (64) + 4 linhas de texto de 24 dp.
  static const _solutionMinSheet = 160.0;

  /// Room kept below the board for the collapsed sheet: the handle, Viktor's
  /// header (48), the prompt bubble with [_collapsedLines] full lines of 24 dp
  /// (2 dp above it and 9 dp of padding on each side), the 12 dp fade, the gap
  /// and the footer. Short screens (360×640) shrink the board to leave it;
  /// 360×740 and 412×917 keep the full width.
  static const _collapsedLines = 3;
  static const _sheetPeek =
      _handleHeight +
      48 +
      2 +
      2 * 9 +
      _collapsedLines * 24 +
      12 +
      _endGap +
      _actionsHeight;

  /// A fala do enunciado. No passo de pensar, antes de qualquer dica, o
  /// Viktor só diz quem joga e pede para pensar, curto (o tabuleiro fica no
  /// centro); o contexto do passo abre a explicação.
  String? _promptText(
    BuildContext context,
    LessonState state,
    LessonStep step,
  ) {
    return _said(context, state);
  }

  Widget _boardArea(
    BuildContext context,
    LessonState state,
    BoardSettings boardSettings,
    ChessboardController board, {
    required double size,
  }) {
    final colors = Theme.of(context).colorScheme;
    final hint = state.hint;
    // As marcações do professor (setas e casas): o aluno pode escondê-las.
    final marked = context.select(
      (SettingsCubit cubit) => cubit.state?.lessonMarks ?? true,
    );
    final shapes = <Shape>{
      if (marked)
        for (final (from, to) in state.arrows)
          Arrow(
            // Na demonstração da linha errada, as setas na cor de erro.
            color: (state.wrongDemo ? colors.error : colors.primary).withValues(
              alpha: 0.75,
            ),
            orig: Square.fromName(from),
            dest: Square.fromName(to),
          ),
      if (marked)
        for (final mark in state.marks)
          Circle(color: const Color(0xcc15781b), orig: Square.fromName(mark)),
      for (final star in state.stars)
        CustomShape(
          orig: Square.fromName(star),
          scale: 0.7,
          child: StarShape(key: LessonKeys.star(star)),
        ),
      if (hint is NormalMove)
        Arrow(color: const Color(0xcc15781b), orig: hint.from, dest: hint.to),
      // Solução vista: a seta verde (a da dica) no lance certo.
      if (state.solutionSeen)
        if (state.solutionMove case final NormalMove move)
          Arrow(color: const Color(0xcc15781b), orig: move.from, dest: move.to),
    };
    // Cada passo novo: o tabuleiro "pousa" (o controle volta do zero ao
    // trocar de passo, sem refazer o tabuleiro).
    return AnimatedBuilder(
      animation: _landing,
      builder: (context, child) {
        final value = AppMotion.enter.transform(_landing.value);
        // Só um esmaecer: as peças que andam já se movem sozinhas (§8).
        return Opacity(opacity: 0.3 + 0.7 * value, child: child);
      },
      child: _shakingBoard(context, state, boardSettings, board, size, shapes),
    );
  }

  Widget _shakingBoard(
    BuildContext context,
    LessonState state,
    BoardSettings boardSettings,
    ChessboardController board,
    double size,
    Set<Shape> shapes,
  ) {
    final step = state.current!;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 4) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      // O tabuleiro não espelha em idiomas da direita para a esquerda.
      child: Directionality(
        textDirection: TextDirection.ltr,
        // O destaque da fala muda sozinho: só o tabuleiro é refeito.
        child: ListenableBuilder(
          listenable: Listenable.merge([_flash, _variation, _branch]),
          builder: (context, _) {
            final variation = _variation.value;
            final previewFen = _branch.value != null
                ? _tree?.fenAt(_branch.value!)
                : _authoredVariation?.fen ?? variation?.fen;
            final chessboard = Chessboard(
              key: LessonKeys.board,
              size: size,
              controller: board,
              // Ler o tabuleiro sem as letras e os números da borda.
              settings: step is TapStep && !step.coordinates
                  ? boardSettings.copyWith(coordinates: false).chessground
                  : boardSettings.chessground,
              orientation: step.side,
              // O destaque da fala, só na posição em que foi tocado.
              // Na variante, só o destaque dela: as marcações são do passo.
              shapes: previewFen != null
                  ? _flash.shapesFor(previewFen)
                  : {...shapes, ..._flash.shapesFor(state.fen ?? step.fen)},
              onMove: (move, {viaDragAndDrop}) {
                if (_variation.value != null) {
                  unawaited(_onVariantMove(move));
                } else if (_authoredVariation == null) {
                  context.read<LessonCubit>().play(move);
                }
              },
              // No passo de tocar, o toque na casa é a resposta.
              onTouchedSquare: step is TapStep && previewFen == null
                  ? (square) => context.read<LessonCubit>().tap(square.name)
                  : null,
            );
            if (step is! StarsStep) return chessboard;
            // O tabuleiro ignora o lance proibido em silêncio: os toques
            // são lidos aqui para o Viktor explicar como a peça anda.
            Square? at(Offset local) {
              final border = chessboard.settings.border?.width ?? 0;
              return chessboard.offsetSquare(local - Offset(border, border));
            }

            return Listener(
              onPointerDown: (event) =>
                  _illegal.down(context, at(event.localPosition)),
              onPointerUp: (event) =>
                  _illegal.up(context, at(event.localPosition)),
              onPointerCancel: (_) => _illegal.reset(),
              child: chessboard,
            );
          },
        ),
      ),
    );
  }

  /// Sob o enunciado: o que fazer no passo (a casa pedida, no passo de
  /// tocar).
  Widget _guide(BuildContext context, LessonState state, LessonStep step) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = switch (state.phase) {
      StepPhase.waiting => l10n.lessonThinking,
      StepPhase.done => l10n.lessonGuideDone,
      StepPhase.failed => l10n.lessonRetry,
      StepPhase.active => switch (step) {
        TalkStep() => l10n.lessonGuideTalk,
        StarsStep() => l10n.lessonGuideStars,
        TapStep() => l10n.lessonGuideTap(state.tapTarget ?? ''),
        MoveStep() => l10n.lessonGuideMove(
          step.side == Side.white ? 'white' : 'black',
        ),
        PlayStep() => l10n.lessonGuidePlay(step.goal.name),
        ThinkStep() => l10n.lessonGuideThink,
        DemoStep() => l10n.lessonGuideDemo,
      },
    };
    // O ícone do que se faz no passo.
    final icon = switch (state.phase) {
      StepPhase.waiting => Icons.pending_rounded,
      StepPhase.done => Icons.check_circle_rounded,
      StepPhase.failed => Icons.replay_rounded,
      StepPhase.active => switch (step) {
        TalkStep() => Icons.visibility_outlined,
        StarsStep() => Icons.star_rounded,
        TapStep() => Icons.touch_app_outlined,
        MoveStep() || PlayStep() => Icons.sports_esports_outlined,
        ThinkStep() => Icons.psychology_outlined,
        DemoStep() => Icons.play_circle_outline,
      },
    };
    final done = state.phase == StepPhase.done;
    // A tarefa do passo numa faixa, alinhada à esquerda, como nos apps de
    // ensino (o nome da aula já está na tela da aula e a parte, na barra de
    // cima).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AnimatedContainer(
        duration: AppMotion.of(context).state,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: done ? colors.primaryContainer : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppShape.medium),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: done ? colors.onPrimaryContainer : colors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                key: LessonKeys.guide,
                // No passo de tocar, a casa pedida é o que importa: grande.
                style: state.tapTarget != null
                    ? theme.textTheme.titleLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      )
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: done
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ExplanationPayload _explanationFor(BuildContext context, LessonState state) {
    final payload = wrongMoveSheetPayload(
      demoSheetPayload(
        state.explanation ??
            ExplanationPayload.context([?_baseSpeech(context, state)]),
        inDemo: state.current is DemoStep && state.demoMove > 0,
      ),
      correctMoveTitle: context.l10n.lessonCorrectMove,
      solutionSeen: state.solutionSeen,
    );
    final attempted = state.attemptedSan ?? state.thinkMistake;
    if (attempted == null ||
        (state.current is DemoStep && state.demoMove > 0) ||
        payload.explanations.any(
          (b) => b.kind == ExplanationKind.playedIncorrect,
        )) {
      return payload;
    }
    final letters = MoveNotation.letters.pieceLetters(context.l10n)!;
    final local = attempted.replaceAllMapped(
      RegExp('[KQRBN]'),
      (m) => letters[m[0]] ?? m[0]!,
    );
    return ExplanationPayload(
      positionId: payload.positionId,
      state: ExplanationState.incorrect,
      explanations: _correctFirst(
        state.solutionSeen,
        context.l10n.lessonCorrectMove,
        [
          ExplanationBlock(
            id: 'played-unmapped',
            kind: ExplanationKind.playedIncorrect,
            texts: ['$local? ${context.l10n.explanationDoesNotMeetGoal}.'],
          ),
          for (final block in payload.explanations)
            // A explicação do lance certo ganha o título dela (D13–D16).
            if (block.kind == ExplanationKind.context && block.title.isEmpty)
              ExplanationBlock(
                id: block.id,
                kind: block.kind,
                title: context.l10n.lessonCorrectMove,
                texts: block.texts,
                variations: block.variations,
              )
            else
              block,
        ],
      ),
    );
  }

  /// O Viktor da lição, na folha.
  Widget _teacher(
    BuildContext context,
    LessonState state,
    LessonStep? step,
    Character viktor, {
    required TeacherSpeechPart part,
    String? text,
  }) {
    final theme = Theme.of(context);
    final prompting =
        state.layout == LessonLayoutMode.solving && !state.wrongMove;
    return TeacherSpeech(
      part: part,
      lessonV2: true,
      // Pensar e passos de lance: a fala fica no balão cinza (PropV2LicaoPratica).
      lessonPromptBubble:
          step != null &&
          prompting &&
          (state.explanation == null ||
              state.explanation?.state == ExplanationState.intro) &&
          _authoredVariation == null,
      onSoundSettings: () => showLessonSoundDialog(context),
      teacher: viktor,
      explanation: prompting && state.explanation == null
          ? null
          : _explanationFor(context, state),
      onVariation: _showAuthoredVariation,
      activeVariation: _speechHeld ? null : _authoredVariation,
      text: state.typing
          ? ''
          : text ??
                (prompting && step != null
                    ? _promptText(context, state, step)
                    : _said(context, state)),
      emotion: state.emotion,
      avatarSize: 56,
      compactInSheet: false,
      bubbleKey: LessonKeys.speech,
      onLink: (link) => _onLink(context, state, link),
      onSpoken: (link) => _flash.show(
        link,
        fen: _authoredVariation?.fen ?? state.fen ?? state.current?.fen,
        color: theme.colorScheme.primary,
      ),
      speaks: true,
      speechContext: SpeechContext.teaching,
      typed: !_revisiting,
      // Ao lado do som: mostrar ou esconder as marcações.
      headerAction: Builder(
        builder: (context) {
          final shown = context.select(
            (SettingsCubit cubit) => cubit.state?.lessonMarks ?? true,
          );
          final hide = context.select(
            (SettingsCubit cubit) => cubit.state?.lessonHiddenMoves ?? true,
          );
          final l10n = context.l10n;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HiddenMovesButton(
                buttonKey: LessonKeys.hiddenMovesToggle,
                hidden: hide,
                onPressed: () => context
                    .read<SettingsCubit>()
                    .setLessonHiddenMoves(hidden: !hide),
              ),
              IconButton(
                key: LessonKeys.marksToggle,
                visualDensity: VisualDensity.standard,
                tooltip: shown ? l10n.lessonHideMarks : l10n.lessonShowMarks,
                isSelected: shown,
                icon: const Icon(Icons.layers_clear_outlined),
                selectedIcon: const Icon(Icons.layers_outlined),
                onPressed: () =>
                    context.read<SettingsCubit>().setLessonMarks(shown: !shown),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- T70: folha do aprendizado (pensar, erro e estado correto) ---

  /// O passo de pensar em resolução, sem lance feito: A1/A2/A3.
  bool _isThinkPrompt(LessonState state) =>
      state.current is ThinkStep &&
      state.layout == LessonLayoutMode.solving &&
      !state.wrongMove;

  /// A fala vem de um passo de pensar (acerto, erro com ramo ou
  /// "Ver resposta").
  bool _thinkOrigin(LessonState state) =>
      state.correct ||
      (state.thinkPlayed != null && state.current is! ThinkStep);

  /// O erro com ramo: modo variante com "Ver resposta" no rodapé.
  bool _wrongPending(LessonState state) =>
      !state.correct &&
      state.thinkPlayed != null &&
      state.current is! ThinkStep;

  ThinkStep? _thinkOf(LessonState state) {
    final steps = state.lesson?.steps;
    if (steps == null) return null;
    if (state.current case final ThinkStep think) return think;
    final previous = state.step - 1;
    if (previous >= 0 && steps[previous] is ThinkStep) {
      return steps[previous] as ThinkStep;
    }
    return null;
  }

  bool _isDrawLesson(LessonState state) => (state.lesson?.steps ?? const [])
      .any((step) => step is PlayStep && step.goal == PlayGoal.draw);

  String _sideWord(BuildContext context, Side side) =>
      side == Side.white ? context.l10n.blindWhite : context.l10n.blindBlack;

  String _localSan(BuildContext context, String san) {
    return localizedSan(context.l10n, san);
  }

  /// A1/A2/A3: o cabeçalho do Viktor e, embaixo, a frase curta (recolhida)
  /// ou o enunciado inteiro (aberta), com os links de 48 dp.
  Widget _thinkPrompt(
    BuildContext context,
    LessonState state,
    LessonStep? step,
    Character viktor,
  ) {
    final cubit = context.read<LessonCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _teacher(context, state, step, viktor, part: TeacherSpeechPart.header),
        Builder(
          builder: (context) {
            final l10n = context.l10n;
            final theme = Theme.of(context);
            final expanded =
                _statementShown ||
                _forceStatement ||
                ViktorSheet.expandedOf(context);
            final think = _thinkOf(state);
            final style = theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.5,
            );
            final note = _noteText(context, state, think);
            Widget? first;
            if (state.typing) {
              first = const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TypingDots(key: LessonKeys.sheetTyping),
                ),
              );
            } else if (state.wrongNotice) {
              first = Text(
                l10n.lessonWrongMoveTryAnother,
                key: LessonKeys.wrongMoveNotice,
                style: style,
              );
            } else if (note != null) {
              first = Text(note, key: LessonKeys.speech, style: style);
            }
            final statement = _said(context, state) ?? '';
            final Widget body;
            if (!expanded) {
              body =
                  first ??
                  Text(
                    l10n.lessonYourTurnPlay(
                      _sideWord(context, think?.side ?? Side.white),
                    ),
                    key: LessonKeys.yourTurnLine,
                    style: style,
                  );
            } else if (first == null) {
              body = _teacher(
                context,
                state,
                step,
                viktor,
                part: TeacherSpeechPart.bubble,
              );
            } else {
              final rest = statement.split('\n').skip(1).join('\n').trim();
              body = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  first,
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _teacher(
                      context,
                      state,
                      step,
                      viktor,
                      part: TeacherSpeechPart.bubble,
                      text: rest,
                    ),
                  ],
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                if (!expanded)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextLink(
                      key: LessonKeys.fullStatementLink,
                      label: l10n.lessonSeeFullStatement,
                      onTap: _showStatement,
                    ),
                  )
                else if (_statementShown)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextLink(
                      key: LessonKeys.fullStatementLink,
                      label: l10n.lessonHideStatement,
                      onTap: _hideStatement,
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextLink(
                    key: LessonKeys.showAnswerLink,
                    label: l10n.lessonShowAnswer,
                    onTap: () => unawaited(cubit.showAnswer()),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// O comentário da vez quando o motor ou o "também é correto" falam.
  String? _noteText(
    BuildContext context,
    LessonState state,
    LessonStep? think,
  ) {
    final l10n = context.l10n;
    final opponent = (think?.side ?? Side.white).opposite;
    return switch (state.note) {
      LessonNote.alsoCorrect => l10n.lessonAlsoCorrect(
        _localSan(context, state.noteSan ?? ''),
      ),
      LessonNote.engineMove => l10n.lessonEngineMove(
        _sideWord(context, opponent),
      ),
      LessonNote.engineReply => l10n.lessonEngineReply(
        _sideWord(context, opponent),
      ),
      LessonNote.alsoWins => l10n.lessonEngineAlsoWins,
      LessonNote.alsoHolds => l10n.lessonEngineAlsoHolds,
      LessonNote.alsoWinsShowMain => l10n.lessonEngineAlsoWinsShowMain,
      LessonNote.alsoHoldsShowMain => l10n.lessonEngineAlsoHoldsShowMain,
      null => null,
    };
  }

  /// "Ver enunciado completo": a folha abre até o enunciado inteiro e o link
  /// vira "Ocultar enunciado" (não persiste).
  void _showStatement() {
    _cancelAuto();
    setState(() {
      _statementShown = true;
      _forceStatement = true;
    });
    _autoUser = true;
    _measureThenOpen(++_autoGen, null, 0);
  }

  void _hideStatement() {
    setState(() => _statementShown = false);
    if (!_sheet.isAttached) return;
    if (AppMotion.of(context).disabled) {
      _sheet.jumpTo(_sheetMin);
    } else {
      unawaited(
        _sheet.animateTo(
          _sheetMin,
          duration: AppMotion.of(context).component,
          curve: AppMotion.enter,
        ),
      );
    }
  }

  void _clearForce() {
    _autoUser = false;
    if (_forceStatement && mounted) setState(() => _forceStatement = false);
  }

  /// O estado correto (crit. 7): título, explicação curta com o link da
  /// completa e "Alternativas que falham".
  Widget _correctSheet(
    BuildContext context,
    LessonState state,
    LessonStep? step,
    Character viktor,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final lesson = state.lesson;
    final title = lesson == null
        ? null
        : (state.part == null
              ? state.texts.lessonTitle(lesson.id)
              : state.texts.partTitle(lesson.id, state.part!.id) ??
                    state.texts.lessonTitle(lesson.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _teacher(context, state, step, viktor, part: TeacherSpeechPart.header),
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              title,
              key: LessonKeys.correctTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        _teacher(context, state, step, viktor, part: TeacherSpeechPart.bubble),
        if (state.fullSpeech != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextLink(
              key: LessonKeys.fullExplanationLink,
              label: l10n.lessonSeeFullExplanation,
              onTap: cubit.showFullExplanation,
            ),
          ),
        if (state.alternatives.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          FailedMovesList(
            alternatives: state.alternatives,
            onOpen: _openAlternative,
          ),
        ],
      ],
    );
  }

  /// A linha do passo de pensar no modo variante: [ucis] a partir da posição
  /// do passo; [texts] são os comentários por lance.
  bool _openThinkLine(
    LessonState state,
    List<String> ucis,
    List<String> texts, {
    required bool wrong,
  }) {
    final think = _thinkOf(state);
    final start = think == null ? null : GameRules.fromFen(think.fen);
    if (think == null || start == null) return false;
    var position = start;
    final fens = [think.fen];
    final moves = <Move>[];
    final main = <TreeMove>[];
    for (final uci in ucis) {
      final move = Move.parse(uci);
      final played = move == null ? null : GameRules.play(position, move);
      if (move == null || played == null) break;
      final dots = position.turn == Side.white ? '.' : '...';
      final mark = wrong && moves.isEmpty ? '?' : '';
      main.add(
        TreeMove(
          label: '${position.fullmoves}$dots${played.san}$mark',
          fen: played.position.fen,
          move: move,
        ),
      );
      moves.add(move);
      fens.add(played.position.fen);
      position = played.position;
    }
    if (moves.isEmpty) return false;
    final line = SpeechLine(links: const [], fens: fens, moves: moves);
    _lineTrees[line] = VariationTree(startFen: think.fen, main: main);
    _lineTexts[line] = texts;
    _wrongBranch = wrong;
    _showLine(context, SpeechLineCursor(line, 1));
    if (wrong && moves.length > 1) {
      final motion = AppMotion.of(context);
      if (motion.disabled) {
        _goTo(const TreePosition.main(2));
      } else {
        _entryTimers.add(
          Timer(
            motion.component +
                motion.state +
                motion.component +
                motion.component,
            () {
              if (mounted && identical(_variation.value?.line, line)) {
                _goTo(const TreePosition.main(2));
              }
            },
          ),
        );
      }
    }
    return true;
  }

  /// O erro com ramo: abre o modo variante na linha do aluno e a refutação
  /// anda sozinha (crit. 4–5).
  void _enterWrongBranch(LessonState state) {
    final played = state.thinkPlayed;
    if (played == null || _variation.value != null) return;
    final engine = state.engineLine.isNotEmpty;
    final think = _thinkOf(state);
    final opponent = (think?.side ?? Side.white).opposite;
    final l10n = context.l10n;
    final branch = context.read<LessonCubit>().thinkBranch(
      played,
      fallback: l10n.lessonBranchMoveFallback,
    );
    final ucis = engine ? state.engineLine : branch.ucis;
    final texts = engine
        ? [
            l10n.lessonEngineMove(_sideWord(context, opponent)),
            l10n.lessonEngineReply(_sideWord(context, opponent)),
          ]
        : branch.texts;
    _openThinkLine(state, ucis, texts, wrong: true);
  }

  /// Toque numa alternativa que falha (estado correto): o ramo abre no modo
  /// variante, sem selo nem refutação automática.
  void _openAlternative(String uci) {
    final cubit = context.read<LessonCubit>();
    final state = cubit.state;
    final branch = cubit.thinkBranch(
      uci,
      fallback: context.l10n.lessonBranchMoveFallback,
    );
    final ucis = branch.ucis;
    final texts = branch.texts;
    // A folha sai para a linha entrar (o toque nela a deixou "em movimento").
    _cancelAuto();
    _snapSheet();
    if (_openThinkLine(state, ucis, texts, wrong: false)) {
      cubit.markSeen(uci);
    }
  }

  /// O lado do aluno na linha do passo de pensar aberta.
  Side? _studentSide() {
    final line = _variation.value?.line;
    if (line == null || _lineTrees[line] == null) return null;
    return _thinkOf(context.read<LessonCubit>().state)?.side;
  }

  /// Ramificação jogável (crit. 9b/9c): o lance do aluno no modo variante.
  Future<void> _onVariantMove(Move move) async {
    final tree = _tree;
    final position = _position;
    final line = _variation.value?.line;
    if (tree == null || position == null || line == null) return;
    void revert() => _board?.updatePosition(
      _treeGame(tree, position),
      animate: false,
      resetPremove: true,
    );
    final target = BranchMove.match(tree, position, move.uci);
    if (target != null) {
      _goTo(target);
      _replyAfter(tree, target);
      return;
    }
    final engine = widget.engine;
    final before = GameRules.fromFen(tree.fenAt(position));
    final played = before == null ? null : GameRules.play(before, move);
    final student = _studentSide();
    if (position.branch != null ||
        engine == null ||
        before == null ||
        played == null ||
        student == null) {
      revert();
      if (position.branch == null && engine == null) _showEngineError();
      return;
    }
    revert();
    final state = context.read<LessonCubit>().state;
    _engineThinking.value = true;
    final answer = await engine.respond(
      played.position,
      student: student,
      mustWin: !_isDrawLesson(state),
    );
    if (mounted) _engineThinking.value = false;
    if (!mounted || _position != position || _tree == null) return;
    switch (answer.verdict) {
      case EngineVerdict.failed:
        revert();
        _showEngineError();
      case EngineVerdict.keeps:
        revert();
        if (tree.canNext(position)) _goTo(tree.next(position));
      case EngineVerdict.loses:
        final reply = answer.reply;
        final afterReply = reply == null
            ? null
            : GameRules.play(played.position, reply);
        if (reply == null || afterReply == null) {
          revert();
          _showEngineError();
          return;
        }
        final l10n = context.l10n;
        final id = 'engine-${position.ply}-${move.uci}';
        String dots(Position p) => p.turn == Side.white ? '.' : '...';
        final branch = VariationBranch(
          id: id,
          at: position.ply,
          moves: [
            TreeMove(
              label: '${before.fullmoves}${dots(before)}${played.san}',
              fen: played.position.fen,
              move: move,
            ),
            TreeMove(
              label:
                  '${played.position.fullmoves}${dots(played.position)}${afterReply.san}',
              fen: afterReply.position.fen,
              move: reply,
            ),
          ],
          commentByPly: {
            1: l10n.lessonEngineMove(_sideWord(context, student.opposite)),
            2: l10n.lessonEngineReply(_sideWord(context, student.opposite)),
          },
        );
        final grown = VariationTree(
          startFen: tree.startFen,
          main: tree.main,
          branches: [...tree.branches, branch],
        );
        _tree = grown;
        _lineTrees[line] = grown;
        _goTo(TreePosition.branch(id, 1));
        _replyAfter(grown, TreePosition.branch(id, 1));
    }
  }

  /// O adversário responde ao lance do aluno: o próximo lance da árvore anda
  /// sozinho (240 ms; na hora sem animações).
  void _replyAfter(VariationTree tree, TreePosition at) {
    final student = _studentSide();
    final next = tree.canNext(at) ? tree.next(at) : null;
    final position = GameRules.fromFen(tree.fenAt(at));
    if (next == null || student == null || position?.turn == student) return;
    final motion = AppMotion.of(context);
    void go() {
      if (mounted && _position == at) _goTo(next);
    }

    if (motion.disabled) {
      go();
    } else {
      _entryTimers.add(Timer(motion.component, go));
    }
  }

  /// "Ver resposta" do rodapé do erro: fecha o ramo e abre o estado correto.
  void _answerFromBranch() {
    _cancelEntry();
    _stage.value = 0;
    _branch.value = null;
    _variation.value = null;
    _wrongBranch = false;
    _syncTree();
    unawaited(context.read<LessonCubit>().showAnswer());
  }

  void _showEngineError() {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: LessonKeys.engineErrorSnack,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, _footerHeight.value + 8),
          content: Text(context.l10n.lessonEngineError),
        ),
      );
  }

  /// O rodapé do passo de pensar e do que sai dele: ✕ ⏮ ⏭, ou, no erro com
  /// ramo, [Ver resposta] ⏮ ⏭.
  Widget _thinkFooter(BuildContext context, LessonState state) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    return KeyedSubtree(
      key: LessonKeys.footer,
      child: VariationControls(
        canPrevious: state.canGoBack,
        canNext: state.correct,
        exitKey: LessonKeys.lessonExitButton,
        exitTooltip: l10n.lessonExit,
        onExit: () => unawaited(Navigator.of(context).maybePop()),
        onBack: cubit.back,
        onForward: cubit.next,
        primaryAction: _wrongPending(state)
            ? VariationPrimaryAction(
                label: l10n.lessonShowAnswer,
                onPressed: _answerFromBranch,
              )
            : null,
      ),
    );
  }

  /// The whole speech in the sheet: Viktor's header always on top of it.
  Widget _speechSheet(
    BuildContext context,
    LessonState state,
    LessonStep? step,
    Character? viktor,
  ) {
    return Column(
      children: [
        // A faixa da tarefa só no passo de tocar: lá a casa pedida é o
        // exercício. No resto, o Viktor já diz o que fazer.
        if (viktor != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _isThinkPrompt(state)
                ? _thinkPrompt(context, state, step, viktor)
                : _thinkOrigin(state) && state.correct
                ? _correctSheet(context, state, step, viktor)
                : _teacher(
                    context,
                    state,
                    step,
                    viktor,
                    // Digitando: só o cabeçalho; os pontinhos tomam o lugar
                    // do texto.
                    part: state.typing
                        ? TeacherSpeechPart.header
                        : TeacherSpeechPart.all,
                  ),
          ),
        // A máquina responde ao lance do aluno na demonstração: três pontos
        // centralizados no lugar do comentário (T70, pg. 2.3).
        if (state.typing && step is DemoStep)
          Padding(
            key: LessonKeys.sheetTyping,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Align(
              child: TypingDots(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (step is TapStep) _guide(context, state, step),
        // A folha da demonstração não traz o convite (T70, P2 #6).
        if (step is! DemoStep &&
            (state.layout == LessonLayoutMode.explaining || state.wrongMove) &&
            state.fen != null)
          Padding(
            // Em cima, 0: o último bloco da explicação já termina com 16.
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Canvas: 16 + linha + 16 até "Ainda com dúvida?".
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                // End of the explanation (PropV2Licao*): 16/24 onSurfaceVariant.
                Text(
                  context.l10n.lessonFreeBoardInvite,
                  key: LessonV2Keys.freeBoardInvite,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: LessonV2Keys.openFreeBoard,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => context.push(
                    Routes.setup(
                      (_branch.value != null
                              ? _tree?.fenAt(_branch.value!)
                              : null) ??
                          _authoredVariation?.fen ??
                          _variation.value?.fen ??
                          state.fen!,
                      goal: _isDrawLesson(state)
                          ? PositionGoal.draw.code
                          : PositionGoal.win.code,
                    ),
                  ),
                  icon: const Icon(Icons.grid_on),
                  label: Text(context.l10n.lessonOpenFreeBoard),
                ),
                // Estado correto: respiro até o rodapé, o botão nunca fica
                // rente a ele.
                if (state.correct) const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        if (state.link case final reference?)
          if (state.fen == null || !_isWikipedia(reference.url))
            Padding(
              // No canto de início, logo abaixo do balão (alinhado à
              // borda dele).
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 16, 0),
              child: ReferenceLink(
                key: LessonKeys.referenceLink,
                reference: reference,
                blackBelow: step?.side == Side.black,
              ),
            ),
      ],
    );
  }

  bool _isWikipedia(String? url) {
    final host = url == null ? null : Uri.tryParse(url)?.host.toLowerCase();
    return host == 'wikipedia.org' ||
        (host?.endsWith('.wikipedia.org') ?? false);
  }

  /// O esmaecer no fim da tela, por trás dos botões: a fala usa a tela até
  /// perto da borda de baixo, passando ao lado (e por trás) deles; só uma
  /// faixa fina no fim esmaece até a cor do fundo, para ela não terminar
  /// cortada seco e dar para ver que continua (rolando, o fim dela sobe
  /// acima dos botões).
  Widget _footer(BuildContext context, {required Widget child}) => KeyedSubtree(
    key: LessonKeys.footer,
    child: LessonFooterSurface(child: child),
  );

  /// O texto do botão principal: "Explicação" no passo de pensar (D16),
  /// "Concluir a aula" no último passo da aula, "Continuar" no resto.
  String _nextLabel(BuildContext context, LessonState state, LessonStep step) {
    final l10n = context.l10n;
    final isLast = state.step + 1 >= state.stepCount;
    if (step is ThinkStep) return l10n.lessonExplanationShort;
    if (state.returnTo != null) return l10n.lessonBackToTest;
    // Último passo de uma parte: segue para a próxima parte (LICOES-V2 §3).
    if (isLast && state.part != null) return l10n.lessonContinue;
    return isLast ? l10n.lessonFinish : l10n.lessonContinue;
  }

  /// Enquanto o aluno resolve: as ações do passo no canto de início (voltar
  /// um passo, dica, voltar à posição e o principal com o texto, "Ver
  /// explicação" ou "Continuar" ao rever, que encolhe se não couber) e o
  /// cronômetro no canto de fim. Todos os botões da mesma altura.
  Widget _solvingFooter(BuildContext context, LessonState state) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final step = state.current!;
    final colors = Theme.of(context).colorScheme;
    final canHint =
        state.phase == StepPhase.active &&
        (step is MoveStep || step is PlayStep);
    final moved = step is ThinkStep && state.fen != step.fen;
    Widget round(Key key, IconData icon, String tooltip, VoidCallback onTap) =>
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
          child: FloatingActionButton(
            key: key,
            heroTag: null,
            shape: const CircleBorder(),
            elevation: 2,
            backgroundColor: colors.surface,
            foregroundColor: colors.primary,
            tooltip: tooltip,
            onPressed: onTap,
            child: Icon(icon),
          ),
        );
    return _footer(
      context,
      child: Row(
        children: [
          if (state.canGoBack)
            round(
              LessonKeys.backButton,
              Icons.arrow_back,
              l10n.lessonPrevious,
              cubit.back,
            ),
          if (canHint)
            round(
              LessonKeys.hintButton,
              Icons.lightbulb_outline,
              l10n.lessonHint,
              cubit.askHint,
            ),
          // No passo de pensar: a próxima dica, quando o aluno quiser.
          if (state.canHint)
            round(
              LessonKeys.moreHintButton,
              Icons.lightbulb_outline,
              l10n.lessonMoreHint,
              cubit.moreHint,
            ),
          // Mexeu nas peças: de volta à posição do passo.
          if (moved)
            round(
              LessonKeys.thinkReset,
              Icons.replay,
              l10n.lessonThinkReset,
              cubit.resetThink,
            ),
          if (state.phase == StepPhase.waiting)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: _waiting(context),
            ),
          // Com botão principal, ele toma o espaço que sobra; sem ele, o
          // cronômetro vai sozinho para o canto de fim.
          if (state.canContinue)
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                child: _FooterAction(
                  key: LessonKeys.nextButton,
                  onPressed: cubit.next,
                  // A explicação do Viktor (a lâmpada é da dica).
                  icon: step is ThinkStep
                      ? Icons.forum_outlined
                      : Icons.arrow_forward_rounded,
                  label: _nextLabel(context, state, step),
                  background: colors.primary,
                  foreground: colors.onPrimary,
                ),
              ),
            )
          else
            const Spacer(),
          // Na escola, sem cronômetro: o iniciante aprende sem pressa (os
          // desafios das estrelas, contra o relógio, têm o deles).
          if (state.endgame)
            // Sem fundo de pílula (CompTimer do canvas): ícone e tempo soltos.
            StepTimer(key: LessonKeys.stepTimer, elapsed: _elapsed),
        ],
      ),
    );
  }

  /// A máquina está respondendo.
  Widget _waiting(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      color: colors.surface,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(context.l10n.lessonThinking),
          ],
        ),
      ),
    );
  }

  /// Com o professor falando: voltar um passo, tentar de novo e continuar.
  Widget _actions(BuildContext context, LessonState state) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final step = state.current!;
    final colors = Theme.of(context).colorScheme;
    if (step is DemoStep && state.phase != StepPhase.done) {
      return KeyedSubtree(
        key: LessonKeys.footer,
        child: DemoControls(
          state: state,
          height: _actionsHeight,
          ring: _demoRing,
        ),
      );
    }
    // Com a explicação aberta (T65 §3, §4): o rodapé do canvas, de botões de
    // texto em partes iguais, no lugar do FAB e da pílula.
    final explanation = state.explanation;
    final failed = state.phase == StepPhase.failed;
    final mistake = state.showsMistake;
    if (mistake && state.solutionSeen) {
      return _solutionFooter(context, state);
    }
    // Lance errado sem erro previsto: a folha monta o "Lance certo" a partir do
    // passo, mesmo sem a solução principal no conteúdo.
    if (mistake &&
        (state.wrongMove ||
            (explanation?.explanations.any(
                  (b) => b.kind == ExplanationKind.mainSolution,
                ) ??
                false))) {
      return _errorFooter(context, state, step);
    }
    if (explanation != null && !failed && state.phase != StepPhase.waiting) {
      return _panelFooter(
        context,
        children: [
          _backButton(context, state),
          _continueButton(context, state, step),
        ],
      );
    }
    final review = state.phase == StepPhase.failed && state.reviewStep != null;
    if (state.phase == StepPhase.failed) {
      Widget action(
        Key key,
        IconData icon,
        String label,
        VoidCallback? onPressed, {
        bool primary = false,
        bool tonal = false,
      }) {
        final style = FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: Theme.of(context).textTheme.labelLarge,
        );
        final content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        );
        return Expanded(
          child: primary
              ? FilledButton(
                  key: key,
                  style: style,
                  onPressed: onPressed,
                  child: content,
                )
              : tonal
              ? FilledButton.tonal(
                  key: key,
                  style: style,
                  onPressed: onPressed,
                  child: content,
                )
              : OutlinedButton(
                  key: key,
                  style: style.copyWith(
                    backgroundColor: WidgetStatePropertyAll(colors.surface),
                  ),
                  onPressed: onPressed,
                  child: content,
                ),
        );
      }

      return _footer(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                action(
                  LessonKeys.backButton,
                  Icons.arrow_back,
                  l10n.lessonPrevious,
                  state.canGoBack ? cubit.back : null,
                ),
                const SizedBox(width: 8),
                action(
                  LessonKeys.reviewPoint,
                  Icons.auto_stories_outlined,
                  l10n.lessonReviewIdea,
                  review ? cubit.reviewPoint : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                action(
                  LessonKeys.seeSolution,
                  Icons.lightbulb_outline,
                  l10n.lessonSeeSolution,
                  state.explanation != null
                      ? cubit.seeSolution
                      : state.canContinue
                      ? cubit.next
                      : null,
                  tonal: true,
                ),
                const SizedBox(width: 8),
                action(
                  LessonKeys.retryButton,
                  Icons.replay,
                  l10n.lessonRetry,
                  cubit.retry,
                  primary: true,
                ),
              ],
            ),
          ],
        ),
      );
    }
    return _footer(
      context,
      child: Row(
        children: [
          if (state.canGoBack) ...[
            FloatingActionButton(
              key: LessonKeys.backButton,
              heroTag: null,
              // Redondo e da altura dos outros botões da fileira.
              shape: const CircleBorder(),
              elevation: 2,
              backgroundColor: colors.surface,
              foregroundColor: colors.primary,
              tooltip: l10n.lessonPrevious,
              onPressed: cubit.back,
              child: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
          ],
          if (state.phase == StepPhase.waiting) _waiting(context),
          if (!state.canContinue) const Spacer(),
          // A pill like the FAB, but its label wraps at font 2.0 instead of
          // overflowing the row (CompRodapeLicao `leitura`).
          if (state.canContinue)
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  key: LessonKeys.nextButton,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    elevation: 2,
                    shape: const StadiumBorder(),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  onPressed: cubit.next,
                  child: Text(
                    _nextLabel(context, state, step),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// O rodapé do painel (CompRodapeLicao `rodape_botoes`): fundo da folha,
  /// borda de cima de 1 dp, padding 12/16/24; as linhas em [children] e os
  /// botões de cada linha em partes iguais, 12 dp entre eles.
  Widget _panelFooter(BuildContext context, {required List<Widget> children}) =>
      _footerBox(
        key: LessonKeys.footer,
        context: context,
        // Os botões da fileira da mesma altura se um rótulo quebrar linha.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: child),
              ],
            ],
          ),
        ),
      );

  Widget _footerBox({
    required Key key,
    required BuildContext context,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: child,
      ),
    );
  }

  ButtonStyle _footerButtonStyle(BuildContext context) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    ),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge),
  );

  Widget _outlinedButton(
    BuildContext context, {
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    final colors = Theme.of(context).colorScheme;
    final button = OutlinedButton(
      key: key,
      style: _footerButtonStyle(context).copyWith(
        foregroundColor: WidgetStatePropertyAll(colors.primary),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: .12)
                : colors.outline,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  /// "Voltar" (o passo anterior; o tooltip é `lessonPrevious`).
  Widget _backButton(BuildContext context, LessonState state) =>
      _outlinedButton(
        context,
        key: LessonKeys.backButton,
        label: context.l10n.lessonFooterBack,
        tooltip: context.l10n.lessonPrevious,
        onPressed: state.canGoBack ? context.read<LessonCubit>().back : null,
      );

  /// "Continuar" cheio, ou o texto do passo (Concluir, Voltar ao teste...).
  Widget _continueButton(
    BuildContext context,
    LessonState state,
    LessonStep step, {
    bool filled = true,
  }) {
    final cubit = context.read<LessonCubit>();
    final label = _nextLabel(context, state, step);
    final onPressed = state.canContinue ? cubit.next : null;
    if (!filled) {
      return _outlinedButton(
        context,
        key: LessonKeys.nextButton,
        label: label,
        onPressed: onPressed,
      );
    }
    return FilledButton(
      key: LessonKeys.nextButton,
      style: _footerButtonStyle(context),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
  }

  /// Explicação do erro (E2): Voltar | Ver solução | Continuar, 1:1:1; só o
  /// Continuar é cheio.
  Widget _errorFooter(
    BuildContext context,
    LessonState state,
    LessonStep step,
  ) => _panelFooter(
    context,
    children: [
      _backButton(context, state),
      _outlinedButton(
        context,
        key: LessonKeys.seeSolution,
        label: context.l10n.lessonSeeSolution,
        onPressed: context.read<LessonCubit>().seeSolution,
      ),
      _continueButton(context, state, step),
    ],
  );

  /// Solução vista (E5): em cima, Tentar de novo cheio com o ícone; embaixo,
  /// Voltar | Continuar em contorno (um só primário na tela).
  Widget _solutionFooter(BuildContext context, LessonState state) {
    final cubit = context.read<LessonCubit>();
    final step = state.current!;
    return KeyedSubtree(
      key: LessonKeys.footer,
      child: _footerBox(
        key: LessonKeys.solutionFooter,
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: LessonKeys.retryButton,
              style: _footerButtonStyle(context),
              onPressed: cubit.retry,
              icon: const Icon(Icons.replay, size: 18),
              label: Text(
                context.l10n.lessonRetry,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _backButton(context, state)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _continueButton(context, state, step, filled: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// O espaço que os botões flutuantes tomam embaixo: a fala rola até
  /// passar deles.
  static const _actionsHeight = 96.0;

  /// Folga depois do último item da folha, além da altura do rodapé: ele
  /// nunca encosta no rodapé nem no anel da demonstração.
  static const _endGap = AppSpacing.md;
  // A alça da folha: 8 dp em cima e 4 dp dela.
  static const _handleHeight = 12.0;
}

/// Na demonstração, a folha mostra só a fala do lance (TelaLicaoDemoFim):
/// a seção fixa de contexto ("A posição e o objetivo") não se repete.
@visibleForTesting
ExplanationPayload demoSheetPayload(
  ExplanationPayload payload, {
  required bool inDemo,
}) {
  if (!inDemo) return payload;
  bool isSolution(ExplanationBlock b) =>
      b.kind == ExplanationKind.mainSolution ||
      b.kind == ExplanationKind.otherSolutions ||
      b.kind == ExplanationKind.failedAlternatives;
  final rest = [
    for (final b in payload.explanations)
      if (b.kind != ExplanationKind.context)
        // Só a fala do lance: sem o título da seção nem as linhas de
        // variante ("Esta continuação…", "Continuação: …").
        if (isSolution(b))
          ExplanationBlock(
            id: b.id,
            kind: ExplanationKind.context,
            texts: b.texts,
          )
        else
          b,
  ];
  if (payload.explanations.every((b) => b.kind == ExplanationKind.context)) {
    return payload;
  }
  return ExplanationPayload(
    positionId: payload.positionId,
    reviewStepId: payload.reviewStepId,
    state: payload.state,
    explanations: rest,
  );
}

/// Lance errado (PropV2LicaoPensarErrado): LANCE ERRADO, LANCE CERTO e
/// TAMBÉM NÃO FUNCIONAM; sem a seção da posição e com a solução principal
/// intitulada "Lance certo" em vez do título do conteúdo.
@visibleForTesting
ExplanationPayload wrongMoveSheetPayload(
  ExplanationPayload payload, {
  required String correctMoveTitle,
  bool solutionSeen = false,
}) {
  if (payload.state != ExplanationState.incorrect ||
      !payload.explanations.any(
        (b) => b.kind == ExplanationKind.playedIncorrect,
      )) {
    return payload;
  }
  return ExplanationPayload(
    positionId: payload.positionId,
    reviewStepId: payload.reviewStepId,
    state: payload.state,
    explanations: _correctFirst(solutionSeen, correctMoveTitle, [
      for (final b in payload.explanations)
        if (b.kind == ExplanationKind.mainSolution)
          ExplanationBlock(
            id: b.id,
            kind: b.kind,
            title: correctMoveTitle,
            texts: b.texts,
            variations: b.variations,
          )
        // A citação de contexto só fica na Solução vista (LICOES-V2 §4).
        else if (solutionSeen ||
            !(b.kind == ExplanationKind.context && b.title.isNotEmpty))
          b,
    ]),
  );
}

/// Solução vista (T65 §4): Lance certo, depois o lance do aluno ("Lance
/// errado") e "Também não funcionam" (a citação de contexto vai por último,
/// em `ExplanationCards._ordered`). Sem a solução
/// vista, a ordem é a do conteúdo (erro antes do certo, §3).
List<ExplanationBlock> _correctFirst(
  bool solutionSeen,
  String correctMoveTitle,
  List<ExplanationBlock> blocks,
) {
  if (!solutionSeen) return blocks;
  bool isCorrect(ExplanationBlock b) =>
      b.kind == ExplanationKind.mainSolution ||
      (b.kind == ExplanationKind.context && b.title == correctMoveTitle);
  return [...blocks.where(isCorrect), ...blocks.where((b) => !isCorrect(b))];
}

/// Abre a próxima aula da trilha no lugar desta.
void openLesson(BuildContext context, String lessonId) =>
    context.pushReplacement(Routes.lesson(lessonId));

/// O botão principal do rodapé enquanto o aluno resolve: da altura dos
/// outros, com o texto numa linha só que encolhe se faltar largura.
class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 2,
      // Sem contorno, como os outros botões da fileira.
      side: BorderSide.none,
      shape: const StadiumBorder(),
      textStyle: Theme.of(context).textTheme.labelLarge,
    ),
    onPressed: onPressed,
    // The label wraps (font 2.0) instead of shrinking or overflowing.
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

/// Avisa o tamanho do filho depois de cada medida que o muda (fora do
/// quadro, para quem ouve poder refazer a tela).
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) {
      return;
    }
    _reported = size;
    final measured = size;
    SchedulerBinding.instance.addPostFrameCallback((_) => onSize(measured));
  }
}
