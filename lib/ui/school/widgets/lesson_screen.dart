import '../../../domain/models/explanation.dart';

import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/speech_lines.dart';
import '../../../domain/use_cases/speech_links.dart';
import '../../../domain/use_cases/wiki_markup.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/viktor_sheet.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/reference_link.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/speech_flash.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/step_timer.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/lesson_cubit.dart';
import '../../core/board/exercise_layout.dart';
import '../../core/board/centered_board_layout.dart';
import 'lesson_part_widgets.dart';
import 'lesson_finished.dart';
import 'star_shape.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// Uma aula com o Viktor: tabuleiro fixo no centro e fala na folha abaixo.
/// A folha expandida cobre o jogo sem alterar sua geometria.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // O tabuleiro "pousa" a cada passo novo: um fade curto e uma leve escala.
  late final _landing = AnimationController(
    vsync: this,
    duration: AppMotion.component,
    value: 1,
  );

  // O layout do tabuleiro: 0 resolvendo (no centro), 1 explicando (no alto,
  // com a folha da fala). Uma animação só move o tabuleiro e traz a folha.
  late final _mode = AnimationController(
    vsync: this,
    duration: AppMotion.component,
    value: 1,
  );
  double _target = 1;

  ChessboardController? _board;

  // Sacode o tabuleiro no lance errado.
  // A casa ou o lance tocado na fala, por um instante no tabuleiro.
  final _flash = SpeechFlash();

  // A variante citada na fala, aberta no tabuleiro (lance a lance). Nula: o
  // tabuleiro mostra o passo. Fica na tela: sobrevive ao segundo plano e
  // sai sozinha quando o passo, a posição ou a fala mudam.
  VariationCursor? _authoredVariation;

  final _variation = ValueNotifier<SpeechLineCursor?>(null);

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

  // O cabeçalho do Viktor acima do tabuleiro: fica lá até a folha subir
  // até ele ([_headerLimit], o pé dele na área); aí entra no topo da folha.
  final _headerOnTop = ValueNotifier(true);
  double _headerLimit = 0;

  // A altura medida dos botões que flutuam embaixo (com a margem acima
  // deles). Começa na prevista, até a primeira medida.
  final _footerHeight = ValueNotifier<double>(_actionsHeight);

  void _onFooterSize(Size size) {
    if (mounted) _footerHeight.value = size.height;
  }

  Duration _demoWait = Duration.zero;
  Duration? _lastTickElapsed;
  String? _demoAt;
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
      unawaited(cubit.pauseForBackground());
      unawaited(speech?.pauseForBackground());
    } else {
      unawaited(cubit.resumeFromBackground());
      unawaited(speech?.resumeFromBackground());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
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
    switch (state.current) {
      case DemoStep(:final line)
          when state.demoPlaying && state.demoMove < line.length:
        _paceDemo(cubit, state, delta);
      default:
        break;
    }
  }

  /// A demonstração anda sozinha no ritmo da fala (docs/spikes/T51-ritmo.md):
  /// com a voz, espera ela terminar e mais uma pausa; sem voz, um tempo de
  /// leitura pelo tamanho da fala. A velocidade da voz vale para os dois.
  void _paceDemo(LessonCubit cubit, LessonState state, Duration delta) {
    if (_authoredVariation != null || _variation.value != null) {
      return;
    }
    final at = '${state.current!.id}:${state.demoMove}';
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
    if (speech != null && speech.isSpeaking(text)) {
      // Ainda falando: o relógio conta a partir do fim da fala.
      _demoSpoke = true;
      _demoWait = Duration.zero;
      return;
    }
    final reading = max(DemoPace.minReadMs, text.length * DemoPace.msPerChar);
    final waitMs =
        ((_demoSpoke ? 0 : reading) + DemoPace.pauseMs) / max(speed, 0.5);
    if (_demoWait.inMilliseconds >= waitMs) {
      _demoAt = null;
      unawaited(cubit.demoForward());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _board?.dispose();
    _sheet.dispose();
    _sheetMoving.dispose();
    _headerOnTop.dispose();
    _footerHeight.dispose();
    _shake.dispose();
    _landing.dispose();
    _mode.dispose();
    _elapsed.dispose();
    _flash.dispose();
    _variation.dispose();
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
    return GameData(
      fen: fen,
      playerSide: position == null ? PlayerSide.none : player,
      sideToMove: position?.turn ?? side,
      validMoves: position == null ? const {} : GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  // O estado anterior, para saber o que mudou.
  LessonState _previous = const LessonState();

  /// O layout que o estado pede: 0 resolvendo, 1 explicando.
  static double _targetOf(LessonState state) =>
      state.fen != null && state.layout == LessonLayoutMode.solving ? 0 : 1;

  /// Leva o tabuleiro ao layout [target]: animado, ou direto na abertura da
  /// tela e com "reduzir movimento" ligado.
  void _setMode(BuildContext context, double target, {required bool animate}) {
    _target = target;
    if (!animate || AppMotion.of(context).disabled) {
      _mode.value = target;
      return;
    }
    _mode.animateTo(
      target,
      duration: AppMotion.of(context).component,
      curve: AppMotion.enter,
    );
  }

  void _onState(BuildContext context, LessonState state) {
    final previous = _previous;
    if (state.fen != previous.fen ||
        state.step != previous.step ||
        state.speech != previous.speech ||
        state.layout != previous.layout) {
      _authoredVariation = null;
    }
    _previous = state;
    final cubit = context.read<LessonCubit>();
    // Resolvendo: o cronômetro já com o tempo do passo (ao reabrir o app, o
    // tabuleiro nasce aqui, antes do primeiro tique). Saindo para a fala, ele
    // fica parado no tempo final até sumir.
    if (state.layout == LessonLayoutMode.solving) {
      _elapsed.value = cubit.stepElapsed;
    }
    final target = _targetOf(state);
    final modeChanged = target != _target;
    if (modeChanged) {
      _setMode(context, target, animate: previous.current != null);
    }
    if (state.step != previous.step) {
      _illegal.reset();
      if (_sheet.isAttached) {
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
    }
    if (state.mistakes > previous.mistakes) _shake.forward(from: 0);
    // O pouso do passo novo; com o tabuleiro já se movendo, só o movimento.
    if (previous.current != null &&
        state.current?.id != previous.current?.id &&
        !modeChanged &&
        !AppMotion.of(context).disabled) {
      _landing.forward(from: 0);
    }
    // A variante aberta sai quando o passo, a posição ou a fala mudam; senão
    // o tabuleiro continua nela.
    if (_variation.value != null) {
      final changed =
          state.step != previous.step ||
          state.fen != previous.fen ||
          state.speech != previous.speech ||
          state.layout != previous.layout;
      if (!changed) {
        return;
      }
      _variation.value = null;
    }
    if (state.fen == null || state.current == null) {
      return;
    }
    if (_authoredVariation != null) {
      return;
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

  /// A primeira variante de verdade da fala (dois lances ou mais), para o
  /// botão do rodapé.
  SpeechLine? _mainLine(BuildContext context, LessonState state) {
    for (final line in _linesOf(context, state)) {
      if (line.length >= 2) return line;
    }
    return null;
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
      if (cursor != null) {
        _showAuthoredVariation(cursor);
      } else {
        _flash.toggle(
          link,
          fen: _authoredVariation?.fen ?? state.fen,
          color: Theme.of(context).colorScheme.primary,
        );
      }
      return;
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
        _showLine(context, SpeechLineCursor(line, ply));
      }
      return;
    }
    _flash.toggle(
      link,
      fen: _variation.value?.fen ?? state.fen ?? state.current?.fen,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  /// O tabuleiro na variante, no lance do [cursor]; a folha recolhe para o
  /// tabuleiro aparecer inteiro.
  void _showLine(BuildContext context, SpeechLineCursor cursor) {
    final opening = _variation.value == null;
    _flash.clear();
    _variation.value = cursor;
    _board?.updatePosition(
      _lineGame(cursor),
      animate: true,
      resetPremove: true,
    );
    if (opening && _sheet.isAttached) {
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
  }

  void _showAuthoredVariation(VariationCursor? cursor) {
    _flash.clear();
    _variation.value = null;
    setState(() => _authoredVariation = cursor);
    final state = context.read<LessonCubit>().state;
    if (cursor == null) {
      _board?.updatePosition(
        _gameData(state),
        animate: true,
        resetPremove: true,
      );
    } else {
      final position = GameRules.fromFen(cursor.fen);
      _board?.updatePosition(
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
        animate: true,
        resetPremove: true,
      );
    }
  }

  /// Fecha a variante: o tabuleiro volta à posição do passo.
  void _exitLine() {
    if (_variation.value == null) {
      return;
    }
    _variation.value = null;
    final state = context.read<LessonCubit>().state;
    if (state.fen == null || state.current == null) {
      return;
    }
    _board?.updatePosition(_gameData(state), animate: true, resetPremove: true);
  }

  /// A linha mostrada no tabuleiro é a errada da aula: a variante aberta
  /// que o JSON do passo marca, ou a demonstração marcada.
  bool _wrongShown(LessonState state) {
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
    final l10n = context.l10n;
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
            _setMode(context, _targetOf(state), animate: false);
            _elapsed.value = cubit.stepElapsed;
          }
          final lesson = state.lesson;
          return Scaffold(
            key: LessonKeys.screen,
            appBar: AppBar(
              // Só o título (da parte, na aula em partes, ou da aula) e, no
              // canto da aula em partes, onde ela está: "1/5". Na escola, o
              // iniciante não vê quantas aulas faltam.
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
              actions: [
                if (lesson != null &&
                    !state.courseFinished &&
                    state.part != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: Center(
                      child: Semantics(
                        label: l10n.homeEndgamePart(
                          state.partNumber,
                          state.partCount,
                        ),
                        excludeSemantics: true,
                        child: Text(
                          '${state.partNumber}/${state.partCount}',
                          key: LessonKeys.place,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
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
    return AnimatedSwitcher(
      duration: AppMotion.component,
      child: state.finished && state.part != null
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label: l10n.lessonStep(
                                  state.step + 1,
                                  state.stepCount,
                                ),
                                child: ExcludeSemantics(
                                  child: StepProgress(
                                    key: LessonKeys.progress,
                                    total: state.stepCount,
                                    value: state.progress * state.stepCount,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasBoard) ...[
                        Expanded(
                          child: _exerciseArea(
                            context,
                            state,
                            step,
                            viktor,
                            boardSettings,
                            board,
                            bodyHeight: constraints.maxHeight,
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
                                            bottom: footer,
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
                      listenable: Listenable.merge([_sheetMoving, _variation]),
                      builder: (context, _) {
                        final covered = _sheetMoving.value;
                        final variation = _variation.value;
                        // Os botões saem só enquanto a folha anda (arrasto
                        // ou animação) e voltam quando ela para, recolhida
                        // ou aberta: a fala rola por baixo deles.
                        return IgnorePointer(
                          ignoring: covered,
                          child: ExcludeSemantics(
                            excluding: covered,
                            child: AnimatedSlide(
                              duration: AppMotion.of(context).component,
                              curve: AppMotion.exit,
                              offset: covered
                                  ? const Offset(0, 1)
                                  : Offset.zero,
                              child: AnimatedOpacity(
                                duration: AppMotion.of(context).component,
                                opacity: covered ? 0 : 1,
                                child: _SizeReporter(
                                  onSize: _onFooterSize,
                                  child: AnimatedSwitcher(
                                    duration: AppMotion.of(context).component,
                                    child: KeyedSubtree(
                                      key: ValueKey((
                                        state.layout,
                                        variation != null,
                                      )),
                                      child: variation != null
                                          ? KeyedSubtree(
                                              key: LessonKeys.footer,
                                              child: VariationControls(
                                                cursor: variation,
                                                wrong: _wrongShown(state),
                                                onExit: () => _exitLine(),
                                                onBack: () => _showLine(
                                                  context,
                                                  variation.previous(),
                                                ),
                                                onForward: () => _showLine(
                                                  context,
                                                  variation.next(),
                                                ),
                                              ),
                                            )
                                          : state.layout ==
                                                LessonLayoutMode.solving
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

  /// Centro explícito descontando somente a barra de progresso acima.
  /// O rodapé limita o tamanho, sem deslocar o centro nem encurtar a folha.
  Widget _exerciseArea(
    BuildContext context,
    LessonState state,
    LessonStep step,
    Character? viktor,
    BoardSettings boardSettings,
    ChessboardController board, {
    required double bodyHeight,
  }) => LayoutBuilder(
    builder: (context, box) {
      final area = Size(box.maxWidth, box.maxHeight);
      final centerY =
          BoardViewport.centerYOf(context) - (bodyHeight - area.height);
      final centered = ExerciseLayout.solvingRect(
        area,
        footer: ViktorSheet.peekHeight,
        centerY: centerY,
      );
      // Resolvendo, o tabuleiro fica no centro; explicando, sobe para o alto
      // (com animação) e a folha da fala fica com o resto da tela.
      final high = centered.shift(
        Offset(0, ExerciseLayout.gutter - centered.top),
      );
      return AnimatedBuilder(
        animation: _mode,
        builder: (context, _) {
          final rect = Rect.lerp(centered, high, _mode.value)!;
          // O cabeçalho do Viktor acima do tabuleiro, só resolvendo e se couber;
          // explicando (ou tela baixa), ele fica na folha.
          final headerRoom =
              _mode.value == 0 &&
              rect.top >= _headerHeight + 2 * ExerciseLayout.gutter;
          _headerLimit = rect.top - ExerciseLayout.gutter;
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
                      if (!_wrongShown(state)) return const SizedBox.shrink();
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
                          const PositionedDirectional(
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
              if (viktor != null && headerRoom)
                PositionedDirectional(
                  start: 16,
                  end: 16,
                  top: rect.top - ExerciseLayout.gutter - _headerHeight,
                  height: _headerHeight,
                  child: ValueListenableBuilder(
                    valueListenable: _headerOnTop,
                    builder: (context, onTop, _) => IgnorePointer(
                      ignoring: !onTop,
                      child: AnimatedSlide(
                        duration: AppMotion.of(context).component,
                        curve: AppMotion.enter,
                        offset: onTop ? Offset.zero : const Offset(0, .3),
                        child: AnimatedOpacity(
                          duration: AppMotion.of(context).component,
                          opacity: onTop ? 1 : 0,
                          child: _teacher(
                            context,
                            state,
                            step,
                            viktor,
                            part: TeacherSpeechPart.header,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: ValueListenableBuilder(
                  valueListenable: _footerHeight,
                  builder: (context, footer, _) => ViktorSheet(
                    key: LessonKeys.viktorSheet,
                    onTop: (top) => _headerOnTop.value = top > _headerLimit,
                    top: rect.bottom + ExerciseLayout.gutter,
                    controller: _sheet,
                    scrollKey: LessonKeys.scroll,
                    closeKey: LessonKeys.closeSheet,
                    onMinimumChanged: (value) => _sheetMin = value,
                    onMoving: (value) => _sheetMoving.value = value,
                    padding: EdgeInsets.only(bottom: footer),
                    children: [
                      if (headerRoom)
                        ValueListenableBuilder(
                          valueListenable: _headerOnTop,
                          builder: (context, onTop, _) => _speechSheet(
                            context,
                            state,
                            step,
                            viktor,
                            headerOnTop: onTop,
                          ),
                        )
                      else
                        _speechSheet(context, state, step, viktor),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  /// A altura do cabeçalho do Viktor acima do tabuleiro (retrato de 56).
  static const _headerHeight = 56.0;

  /// A fala do enunciado. No passo de pensar, antes de qualquer dica, o
  /// Viktor só diz quem joga e pede para pensar, curto (o tabuleiro fica no
  /// centro); o contexto do passo abre a explicação.
  String? _promptText(
    BuildContext context,
    LessonState state,
    LessonStep step,
  ) {
    if (step is ThinkStep && state.hintsShown == 0) {
      final l10n = context.l10n;
      return [
        l10n.lessonThinkTurn(step.turn == Side.white ? 'white' : 'black'),
        l10n.lessonThinkCalm(step.ask.name),
      ].join(' ');
    }
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
    };
    // Cada passo novo: o tabuleiro "pousa" (o controle volta do zero ao
    // trocar de passo, sem refazer o tabuleiro).
    return AnimatedBuilder(
      animation: _landing,
      builder: (context, child) {
        final value = AppMotion.enter.transform(_landing.value);
        return Opacity(
          opacity: 0.3 + 0.7 * value,
          child: Transform.scale(scale: 0.95 + 0.05 * value, child: child),
        );
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
          listenable: Listenable.merge([_flash, _variation]),
          builder: (context, _) {
            final variation = _variation.value;
            final previewFen = _authoredVariation?.fen ?? variation?.fen;
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
              onMove: (move, {viaDragAndDrop}) => _authoredVariation == null
                  ? context.read<LessonCubit>().play(move)
                  : null,
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

  /// A folha da fala: o puxador, a faixa da tarefa (no passo de tocar) e o
  /// balão do Viktor. A folha compartilhada controla expansão e rolagem.
  /// [AnimatedSize], menos com movimento reduzido (com duração zero ele se
  /// suja no próprio layout).
  Widget _animatedSize(BuildContext context, Widget child) =>
      AppMotion.of(context).disabled
      ? child
      : AnimatedSize(
          duration: AppMotion.of(context).component,
          curve: AppMotion.enter,
          child: child,
        );

  ExplanationPayload _explanationFor(BuildContext context, LessonState state) {
    final payload =
        state.explanation ??
        ExplanationPayload.context([?_baseSpeech(context, state)]);
    final attempted = state.attemptedSan ?? state.thinkMistake;
    if (attempted == null ||
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
      explanations: [
        ExplanationBlock(
          id: 'played-unmapped',
          kind: ExplanationKind.playedIncorrect,
          texts: ['$local: ${context.l10n.explanationDoesNotMeetGoal}.'],
        ),
        ...payload.explanations,
      ],
    );
  }

  /// O Viktor da lição: inteiro, só o cabeçalho (acima do tabuleiro) ou só
  /// o balão (na folha).
  Widget _teacher(
    BuildContext context,
    LessonState state,
    LessonStep? step,
    Character viktor, {
    required TeacherSpeechPart part,
  }) {
    final theme = Theme.of(context);
    return TeacherSpeech(
      part: part,
      teacher: viktor,
      explanation:
          state.layout == LessonLayoutMode.solving && state.explanation == null
          ? null
          : _explanationFor(context, state),
      onVariation: _showAuthoredVariation,
      activeVariation: _authoredVariation,
      text: state.layout == LessonLayoutMode.solving && step != null
          ? _promptText(context, state, step)
          : _said(context, state),
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
      typed: true,
      // Ao lado do som: mostrar ou esconder as marcações.
      headerAction: Builder(
        builder: (context) {
          final shown = context.select(
            (SettingsCubit cubit) => cubit.state?.lessonMarks ?? true,
          );
          final l10n = context.l10n;
          return IconButton(
            key: LessonKeys.marksToggle,
            visualDensity: VisualDensity.compact,
            tooltip: shown ? l10n.lessonHideMarks : l10n.lessonShowMarks,
            isSelected: shown,
            icon: const Icon(Icons.layers_clear_outlined),
            selectedIcon: const Icon(Icons.layers_outlined),
            onPressed: () =>
                context.read<SettingsCubit>().setLessonMarks(shown: !shown),
          );
        },
      ),
    );
  }

  /// [headerOnTop]: nulo, a fala inteira na folha; senão, o cabeçalho fica
  /// acima do tabuleiro (true) ou no topo da folha aberta (false).
  Widget _speechSheet(
    BuildContext context,
    LessonState state,
    LessonStep? step,
    Character? viktor, {
    bool? headerOnTop,
  }) {
    return Column(
      children: [
        // A faixa da tarefa só no passo de tocar: lá a casa pedida é o
        // exercício. No resto, o Viktor já diz o que fazer.
        if (viktor != null && headerOnTop != null)
          // O cabeçalho mora acima do tabuleiro; quando a folha sobe até
          // ele, entra no topo dela (anima).
          _animatedSize(
            context,
            headerOnTop
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _teacher(
                      context,
                      state,
                      step,
                      viktor,
                      part: TeacherSpeechPart.header,
                    ),
                  ),
          ),
        if (viktor != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _teacher(
              context,
              state,
              step,
              viktor,
              part: headerOnTop == null
                  ? TeacherSpeechPart.all
                  : TeacherSpeechPart.bubble,
            ),
          ),
        if (step is TapStep) _guide(context, state, step),
        if (state.link case final reference?)
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

  /// O esmaecer no fim da tela, por trás dos botões: a fala usa a tela até
  /// perto da borda de baixo, passando ao lado (e por trás) deles; só uma
  /// faixa fina no fim esmaece até a cor do fundo, para ela não terminar
  /// cortada seco e dar para ver que continua (rolando, o fim dela sobe
  /// acima dos botões).
  Widget _footer(BuildContext context, {required Widget child}) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return DecoratedBox(
      key: LessonKeys.footer,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            background.withValues(alpha: 0),
            background.withValues(alpha: 0),
            background,
          ],
          stops: const [0, 0.7, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: child,
      ),
    );
  }

  /// O texto do botão principal: "Ver explicação" no passo de pensar,
  /// "Concluir" no último passo, "Continuar" no resto.
  String _nextLabel(BuildContext context, LessonState state, LessonStep step) {
    final l10n = context.l10n;
    final isLast = state.step + 1 >= state.stepCount;
    if (step is ThinkStep) return l10n.lessonSeeExplanation;
    if (state.returnTo != null) return l10n.lessonBackToTest;
    if (isLast && state.part != null) return l10n.lessonFinishPart;
    return isLast ? l10n.lessonFinish : l10n.lessonContinue;
  }

  /// Enquanto o aluno resolve: as ações do passo no canto de início (voltar
  /// um passo, dica, voltar à posição e o principal com o texto, "Ver
  /// explicação" ou "Continuar" ao rever, que encolhe se não couber) e o
  /// cronômetro no canto de fim. Todos os botões da mesma altura.
  Widget _solvingFooter(BuildContext context, LessonState state) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    if (_authoredVariation != null) {
      return _footer(
        context,
        child: TextButton.icon(
          onPressed: () => _showAuthoredVariation(null),
          icon: const Icon(Icons.undo),
          label: Text(l10n.explanationReturn),
        ),
      );
    }
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
    if (_authoredVariation != null) {
      return _footer(
        context,
        child: TextButton.icon(
          onPressed: () => _showAuthoredVariation(null),
          icon: const Icon(Icons.undo),
          label: Text(context.l10n.explanationReturn),
        ),
      );
    }
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final step = state.current!;
    final colors = Theme.of(context).colorScheme;
    if (step is DemoStep && state.phase != StepPhase.done) {
      return KeyedSubtree(
        key: LessonKeys.footer,
        child: DemoControls(state: state, height: _actionsHeight),
      );
    }
    final review = state.phase == StepPhase.failed && state.reviewStep != null;
    final line = state.phase == StepPhase.waiting || review
        ? null
        : _mainLine(context, state);
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
          // A variante citada na fala: o aluno anda por ela com as setas,
          // sem ler a linha até o fim.
          if (line != null)
            Flexible(
              flex: 4,
              child: _FooterAction(
                key: LessonKeys.variationShow,
                onPressed: () => _showLine(context, SpeechLineCursor(line, 1)),
                icon: Icons.call_split,
                label: l10n.lessonVariationShow,
                background: colors.surface,
                foreground: colors.primary,
              ),
            ),
          // O lance errado previsto: rever o ponto da lição que o explica.
          if (review)
            Flexible(
              flex: 4,
              child: _FooterAction(
                key: LessonKeys.reviewPoint,
                onPressed: cubit.reviewPoint,
                icon: Icons.auto_stories_outlined,
                label: l10n.lessonReviewPoint,
                background: colors.surface,
                foreground: colors.primary,
              ),
            ),
          const Spacer(),
          if (state.phase == StepPhase.failed)
            FloatingActionButton.extended(
              key: LessonKeys.retryButton,
              heroTag: null,
              shape: const StadiumBorder(),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              onPressed: cubit.retry,
              icon: const Icon(Icons.replay),
              label: Text(l10n.lessonRetry),
            ),
          if (state.canContinue)
            FloatingActionButton.extended(
              key: LessonKeys.nextButton,
              heroTag: null,
              shape: const StadiumBorder(),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              onPressed: cubit.next,
              label: Text(_nextLabel(context, state, step)),
            ),
        ],
      ),
    );
  }

  /// O espaço que os botões flutuantes tomam embaixo: a fala rola até
  /// passar deles.
  static const _actionsHeight = 96.0;
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
    // O texto flexível de verdade: encolhe em vez de estourar.
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: OneLine(label)),
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
