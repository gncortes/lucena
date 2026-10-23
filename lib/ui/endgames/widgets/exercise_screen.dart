import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/use_cases/exercise_review.dart';
import '../../../domain/use_cases/game_export.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/exercise_actions.dart';
import '../../core/widgets/external_page_sheet.dart';
import '../../core/widgets/lesson_sound_dialog.dart';
import '../../core/widgets/script_speech_sheet.dart';
import '../../core/widgets/speech_balloon.dart';
import '../../core/widgets/square_flash.dart';
import '../../core/widgets/time_display.dart';
import '../../../domain/use_cases/step_clock.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';
import '../../lesson_script/widgets/script_board.dart' show ScriptShapes;
import '../../lesson_script/widgets/script_move_list.dart';
import '../../lesson_script/widgets/script_page.dart';
import '../../lesson_script/widgets/script_speech.dart';
import '../../school/widgets/variation_strip.dart' show HiddenMovesButton;
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../view_models/exercise_cubit.dart';
import 'endgame_ui.dart';
import '../../../domain/use_cases/wiki_markup.dart';
import 'move_sentence.dart';
import '../../core/keys/lesson_script_keys.dart';

/// Um exercício (T72): como a lição roteirizada, o balão do Viktor em cima,
/// o tabuleiro e, embaixo, a notação dos lances. O feedback do lance vem na
/// fala do Viktor; no fim, a notação traz todas as variantes previstas.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    this.lessonId,
    this.exerciseId,
    this.previewFen,
    super.key,
  });

  /// A aula e o exercício (da rota), para o voo da miniatura da lista até o
  /// tabuleiro: [previewFen] é a posição, mostrada parada enquanto o
  /// exercício carrega, porque o voo precisa do destino já no primeiro quadro.
  final String? lessonId;
  final String? exerciseId;
  final String? previewFen;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  ChessboardController? _board;

  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.component,
  );

  // O cronômetro: anda enquanto o aluno resolve; resolvido, fica parado no
  // tempo final.
  final _elapsed = ValueNotifier(Duration.zero);
  Timer? _ticker;

  bool _background = false;

  /// A casa que o aluno tocou na fala, realçada no tabuleiro.
  final _flash = SquareFlash();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state != AppLifecycleState.resumed;
    if (background == _background) {
      return;
    }
    _background = background;
    final cubit = context.read<ExerciseCubit>();
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
    _ticker = Timer.periodic(AppMotion.exerciseTick, (_) {
      if (!mounted || _background) {
        return;
      }
      final cubit = context.read<ExerciseCubit>();
      if (cubit.state.phase != ExercisePhase.done) {
        _elapsed.value = cubit.elapsed;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _elapsed.dispose();
    _flash.dispose();
    _board?.dispose();
    _shake.dispose();
    super.dispose();
  }

  GameData _gameData(ExerciseState state) {
    final fen = state.fen!;
    final side = state.side;
    final position = GameRules.fromFen(fen);
    return GameData(
      fen: fen,
      playerSide: position == null || !state.interactive
          ? PlayerSide.none
          : (side == Side.white ? PlayerSide.white : PlayerSide.black),
      sideToMove: position?.turn ?? side,
      validMoves: position == null ? const {} : GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  ExerciseState _previous = const ExerciseState();

  void _onState(BuildContext context, ExerciseState state) {
    final previous = _previous;
    _previous = state;
    // Resolvendo: o cronômetro já com o tempo do exercício (ao reabrir o
    // app, o tabuleiro nasce aqui, antes do primeiro tique).
    if (state.phase != ExercisePhase.done) {
      _elapsed.value = context.read<ExerciseCubit>().elapsed;
    }
    if (state.mistakes > previous.mistakes) {
      _shake.forward(from: 0);
    }
    // Outro passo (posição ou fase nova): a casa marcada pela fala sai.
    if (state.fen != previous.fen || state.phase != previous.phase) {
      _flash.clear();
    }
    if (state.fen == null) {
      return;
    }
    final board = _board;
    if (board == null) {
      _board = ChessboardController(game: _gameData(state));
      return;
    }
    board.updatePosition(
      _gameData(state),
      animate: previous.fen != state.fen,
      resetPremove: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ExerciseCubit>();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.leave();
      },
      child: BlocConsumer<ExerciseCubit, ExerciseState>(
        listener: _onState,
        builder: (context, state) {
          if (state.fen != null && _board == null) {
            _board = ChessboardController(game: _gameData(state));
            _elapsed.value = cubit.elapsed;
          }
          final lesson = state.lesson;
          return Scaffold(
            key: ExerciseKeys.screen,
            // Só o número: o título da aula, longo, ficou na tela dela.
            appBar: LucenaAppBar(
              title: lesson == null
                  ? null
                  : Text(
                      l10n.exerciseTitle(state.number, state.count),
                      key: ExerciseKeys.counter,
                    ),
              // O que o exercício vale agora: dourada (3), prata (2) ou
              // bronze (1); cada erro ou dica desce um degrau, e a vazia fica
              // vazia até o fim.
              actions: [
                if (state.exercise case final exercise?)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.md,
                    ),
                    child: Semantics(
                      label: _starLabel(l10n, state, exercise),
                      excludeSemantics: true,
                      // Neutra, na cor do texto (canvas PropV2ExA*): cheia se
                      // ainda vale pontos, vazia se não.
                      child: Icon(
                        state.worth > 0
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        key: ExerciseKeys.stars,
                        size: AppIconSize.large,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(top: false, child: _body(context, state)),
          );
        },
      ),
    );
  }

  static String _starLabel(
    AppLocalizations l10n,
    ExerciseState state,
    Exercise exercise,
  ) {
    if (state.zeroed) return l10n.exerciseNoMorePoints;
    return state.phase == ExercisePhase.done
        ? l10n.exerciseEarned(state.earned ?? 0, exercise.stars)
        : l10n.exercisePoints(state.worth);
  }

  /// O tabuleiro fica com chave: o voo da miniatura só continua se o widget
  /// for o mesmo entre o carregamento e o exercício aberto.
  static const _boardAreaKey = ValueKey('exercise.boardArea');

  Widget _body(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    if (!state.ready) return _loading(context, state);
    final exercise = state.exercise;
    if (state.missing || exercise == null) {
      return Center(
        child: Text(l10n.exerciseMissing, key: ExerciseKeys.missing),
      );
    }
    final boardSettings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    final hide = context.select(
      (SettingsCubit c) => c.state?.exerciseHiddenMoves ?? false,
    );
    final cubit = context.read<ExerciseCubit>();
    final done = state.phase == ExercisePhase.done;
    final nodes = done
        ? state.review
        : ExerciseReview.mainLine(
            exercise,
            state.played,
            payload: state.explanationPayload,
          );
    final covered = done && hide
        ? {
            for (final node in nodes)
              if (!state.seen.contains(node.id)) node.id,
          }
        : const <String>{};
    final said = _speech(context, state, hide: hide && done);
    final texts = [...said.paragraphs, ?said.tip];
    final viktor = state.viktor;
    final voice = TeacherSpeech.speechOf(context);
    final sound = context.select((SettingsCubit c) => c.state?.sound ?? true);
    final spoken = SpeechText.plainOf(context, texts.join(' '));
    // O cabeçalho da faixa e o da folha: o mesmo, com borrar e som.
    Widget header(BuildContext c, Character teacher, double avatar) {
      final headerHide = c.select(
        (SettingsCubit cubit) => cubit.state?.exerciseHiddenMoves ?? false,
      );
      return TeacherSpeech(
        part: TeacherSpeechPart.header,
        lessonV2: true,
        headerAvatar: avatar,
        avatarHeroTag: scriptViktorHeroTag,
        teacher: teacher,
        text: spoken,
        speechContext: SpeechContext.teaching,
        onSoundSettings: () => showLessonSoundDialog(c),
        // Ao lado do som, com a lista completa: cobrir ou mostrar
        // os lances ainda não vistos (T69).
        headerAction: done && nodes.isNotEmpty
            ? HiddenMovesButton(
                buttonKey: ExerciseKeys.hiddenMovesToggle,
                hidden: headerHide,
                onPressed: () => c.read<SettingsCubit>().setExerciseHiddenMoves(
                  hidden: !headerHide,
                ),
              )
            : null,
      );
    }

    Widget speechOf(ScriptSpeechMetrics metrics) {
      Widget speech = ScriptSpeech(
        texts: [said.text],
        footnote: said.tip,
        metrics: metrics,
        onSquareTap: _flash.show,
        onOpen: viktor == null
            ? null
            : () => unawaited(
                showScriptSpeechSheet(
                  context,
                  viktor: viktor,
                  title: l10n.teacherName(viktor.name),
                  texts: texts,
                  onSquareTap: _flash.show,
                  background: Theme.of(context).colorScheme.surfaceContainerLow,
                  headerBuilder: (sheet) => header(sheet, viktor, 56),
                  // Canvas `PropV2ExA7`: retrato de 56 e margem de 16.
                  horizontalPadding: 16,
                  headerHeight: 72,
                ),
              ),
      );
      if (voice != null) {
        speech = AutoSpeak(
          speech: voice,
          text: spoken,
          auto: sound,
          speakerId: 'master',
          child: speech,
        );
      }
      return speech;
    }

    final strip = SizedBox(
      key: LessonScriptKeys.characterBar,
      height: ScriptPage.stripHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: viktor == null ? null : header(context, viktor, 40),
      ),
    );
    return Column(
      children: [
        Expanded(
          child: ScriptPage(
            pageKey: ExerciseKeys.page,
            speechBuilder: speechOf,
            strip: strip,
            boardBuilder: (size) => KeyedSubtree(
              key: _boardAreaKey,
              child: _boardArea(context, state, boardSettings, size: size),
            ),
            list: ScriptMoveList(
              moves: [for (final node in nodes) _entry(node)],
              currentId: done ? state.cursorId : nodes.lastOrNull?.id,
              covered: covered,
              // A notação só leva a uma posição depois que o exercício
              // acaba; antes, o tabuleiro é do aluno.
              onTap: done ? (id) => cubit.goToReview(id, hide: hide) : (_) {},
              onReveal: done ? (id) => cubit.goToReview(id, hide: hide) : null,
            ),
          ),
        ),
        _footer(context, state),
      ],
    );
  }

  static ScriptMoveEntry _entry(ReviewNode node) => ScriptMoveEntry(
    id: node.id,
    san: node.san,
    number: node.number,
    side: node.side,
    variant: node.depth > 0,
    depth: node.depth,
    startsVariant: node.startsVariant,
    symbol: node.symbol,
    result: node.result,
  );

  /// O que o balão diz: o resultado do lance (Correto./Não.), o porquê que a
  /// aula escreveu (ou, sem ele, a frase gerada do lance: nunca notação) e o
  /// que o aluno faz em seguida. A dica do borrar ([SpeechLine.tip]) vem à
  /// parte, para o corte do balão não a esconder.
  SpeechLine _speech(
    BuildContext context,
    ExerciseState state, {
    required bool hide,
  }) {
    final l10n = context.l10n;
    final parts = <String>[];
    String sentence(String fenBefore, String uci, String symbol) =>
        moveSentence(l10n, fenBefore: fenBefore, uci: uci, symbol: symbol);
    switch (state.say) {
      case ExerciseSay.goal:
        parts.addAll(
          state.sayTexts.isEmpty
              ? [
                  if (state.exercise != null)
                    l10n.exerciseGoal(
                      state.side == Side.white ? 'white' : 'black',
                      state.exercise!.goal.name,
                    ),
                ]
              : state.sayTexts,
        );
      case ExerciseSay.hint:
        parts.addAll(state.sayTexts);
      case ExerciseSay.correct:
        final move = state.sayMove;
        parts
          ..add(l10n.exerciseSayCorrect)
          ..addAll(
            state.sayTexts.isNotEmpty || move == null
                ? state.sayTexts
                : [sentence(move.fenBefore, move.uci, '!')],
          )
          ..add(l10n.exerciseYourTurnShort);
      case ExerciseSay.wrong:
        final move = state.sayMove;
        // O aviso de zerado vem antes do porquê: cabe nas 2 linhas (ExA8).
        parts.add(l10n.exerciseSayWrong);
        if (state.sayZeroed) parts.add(l10n.exerciseFirstMoveZeroed);
        parts.addAll(
          state.sayTexts.isNotEmpty || move == null
              ? state.sayTexts
              : [sentence(move.fenBefore, move.uci, '?')],
        );
        parts.add(l10n.exerciseTryAnother);
      case ExerciseSay.solved:
        parts.add(_solvedLead(l10n, state));
        _addNode(parts, l10n, state);
      case ExerciseSay.node:
        _addNode(parts, l10n, state);
    }
    // A primeira vez com os lances cobertos: como ver o resto.
    final tip = hide && state.browsed == 0 && state.review.length > 1
        ? l10n.exerciseRevealTip
        : null;
    return (
      text: WikiMarkup.plain(parts.join(' ')),
      // Na folha da dica, uma linha em branco entre a pista e o enunciado.
      paragraphs: state.say == ExerciseSay.hint
          ? [for (final part in parts) WikiMarkup.plain(part)]
          : [WikiMarkup.plain(parts.join(' '))],
      tip: tip,
    );
  }

  /// O comentário do lance do balão; sem ele, a frase gerada.
  static void _addNode(
    List<String> parts,
    AppLocalizations l10n,
    ExerciseState state,
  ) {
    final node = state.sayNode;
    if (state.sayTexts.isNotEmpty) {
      parts.addAll(state.sayTexts);
    } else if (node != null) {
      parts.add(
        moveSentence(
          l10n,
          fenBefore: node.fenBefore,
          uci: node.uci,
          symbol: node.symbol,
        ),
      );
    }
  }

  /// "Correto!" sem erro nem dica; senão "Resolvido, mas com ..." com o que
  /// houve (um erro, N erros, dicas).
  static String _solvedLead(AppLocalizations l10n, ExerciseState state) {
    final mistakes = state.mistakes;
    final hints = state.hints;
    if (mistakes == 0 && hints == 0) return l10n.exerciseSolvedCorrect;
    if (mistakes == 1 && hints == 0) return l10n.exerciseSolvedWithMistake;
    final what = [
      if (mistakes > 0) l10n.exerciseSolvedMistakes(mistakes),
      if (hints > 0) l10n.exerciseSolvedHints(hints),
    ];
    return l10n.exerciseSolvedBut(
      what.length == 2 ? l10n.exerciseSolvedAnd(what[0], what[1]) : what.first,
    );
  }

  /// Enquanto o exercício carrega: o tabuleiro parado no centro (se a rota
  /// trouxe a posição), para a miniatura pousar nele.
  Widget _loading(BuildContext context, ExerciseState state) {
    if (widget.previewFen == null) return const SizedBox.shrink();
    return ScriptPage(
      pageKey: ExerciseKeys.page,
      speechBuilder: (_) => const SizedBox.shrink(),
      strip: const SizedBox(height: ScriptPage.stripHeight),
      boardBuilder: (size) => KeyedSubtree(
        key: _boardAreaKey,
        child: _boardArea(context, state, const BoardSettings(), size: size),
      ),
      list: const SizedBox.shrink(),
    );
  }

  Widget _boardArea(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings, {
    required double size,
  }) {
    final board = _board;
    final previewFen = widget.previewFen;
    if (board == null && previewFen == null) return const SizedBox.shrink();
    final lessonId = state.lesson?.id ?? widget.lessonId ?? '';
    final exerciseId = state.exercise?.id ?? widget.exerciseId ?? '';
    final hint = state.hint;
    final wrong = state.wrongMove;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 4) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      // A miniatura da lista voa até aqui e vira o tabuleiro.
      child: Hero(
        tag: exerciseHeroTag(lessonId, exerciseId),
        child: board == null
            ? PositionBoard(
                fen: previewFen!,
                size: size,
                radius: AppShape.none,
                coordinates: true,
              )
            : Directionality(
                textDirection: TextDirection.ltr,
                // A seta vermelha do lance errado fica parada enquanto ele é
                // comentado (canvas PropV2ExA3/A8).
                child: ListenableBuilder(
                  listenable: _flash,
                  builder: (context, _) => Chessboard(
                    key: ExerciseKeys.board,
                    size: size,
                    controller: board,
                    settings: boardSettings.chessground,
                    orientation: state.side,
                    shapes: {
                      // A casa tocada na fala do professor.
                      if (_flash.square case final flashed?)
                        Circle(
                          color: ScriptShapes.arrow(
                            Theme.of(context).colorScheme,
                            'b',
                          ),
                          orig: Square.fromName(flashed),
                        ),
                      if (hint is NormalMove)
                        Arrow(
                          color: AppColors.successColor.withValues(
                            alpha: AppColors.boardMarkAlpha,
                          ),
                          orig: hint.from,
                          dest: hint.to,
                        ),
                      if (wrong is NormalMove)
                        Arrow(
                          color: AppColors.errorColor.withValues(
                            alpha: AppColors.boardMarkAlpha,
                          ),
                          orig: wrong.from,
                          dest: wrong.to,
                        ),
                    },
                    onMove: (move, {viaDragAndDrop}) =>
                        context.read<ExerciseCubit>().play(move),
                  ),
                ),
              ),
      ),
    );
  }

  /// "Analisar no Lichess": a posição do exercício no tabuleiro de análise.
  Widget _lichessButton(BuildContext context, ExerciseState state) =>
      TextButton.icon(
        key: ExerciseKeys.lichessButton,
        // Dentro do app, na folha da página: a aula fica atrás.
        onPressed: () =>
            showExternalPage(context, GameExport.lichess(state.exercise!.fen)),
        icon: const Icon(Icons.open_in_new_rounded),
        label: Text(context.l10n.exerciseLichess),
      );

  /// O botão principal do resolvido: o próximo exercício, a volta à aula
  /// (treino avulso) ou o resultado (o último da série).
  ExerciseAction _primaryAction(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final lesson = state.lesson!;
    final next = state.nextExercise;
    if (next != null) {
      return ExerciseAction(
        label: l10n.exerciseNext,
        key: ExerciseKeys.nextButton,
        primary: true,
        onPressed: () =>
            context.pushReplacement(Routes.endgameExercise(lesson.id, next)),
      );
    }
    if (state.locked) {
      // Treino avulso: a nota já está fechada, volta à aula.
      return ExerciseAction(
        label: l10n.exerciseBack,
        key: ExerciseKeys.backButton,
        primary: true,
        onPressed: () => context.pop(),
      );
    }
    // O último da série: a tela de resultado, que volta à aula.
    return ExerciseAction(
      label: l10n.exerciseSeeResult,
      key: ExerciseKeys.resultButton,
      primary: true,
      onPressed: () =>
          context.pushReplacement(Routes.endgameExercisesDone(lesson.id)),
    );
  }

  /// O que a dica custa agora (tooltip e rótulo de acessibilidade).
  String _hintLabel(AppLocalizations l10n, ExerciseState state) =>
      switch (state.worth) {
        0 => l10n.exerciseHintFree,
        1 => l10n.exerciseHintLast,
        _ => l10n.exerciseHint,
      };

  /// O rodapé fixo, com a margem de 16 e o mesmo componente da lição.
  /// Resolvendo: a dica à esquerda e o cronômetro à direita (sem pontos, só
  /// "Ver solução"); resolvido: só o próximo exercício, à direita.
  Widget _footer(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<ExerciseCubit>();
    if (!state.ready || state.exercise == null) {
      return const SizedBox.shrink();
    }
    final color = theme.scaffoldBackgroundColor;
    final hide = context.select(
      (SettingsCubit c) => c.state?.exerciseHiddenMoves ?? false,
    );
    final lichess = state.locked ? _lichessButton(context, state) : null;
    final Widget actions;
    if (state.phase == ExercisePhase.done) {
      actions = ExerciseActions(
        key: ExerciseKeys.solved,
        color: color,
        hug: true,
        hint: lichess,
        actions: [_primaryAction(context, state)],
      );
    } else if (state.zeroed && state.interactive) {
      actions = ExerciseActions(
        key: ExerciseKeys.footer,
        color: color,
        hug: true,
        hint: lichess,
        actions: [
          ExerciseAction(
            label: l10n.lessonSeeSolution,
            key: ExerciseKeys.showSolution,
            primary: true,
            onPressed: () => unawaited(cubit.showSolution(hidden: hide)),
          ),
        ],
      );
    } else {
      actions = ExerciseActions(
        key: ExerciseKeys.footer,
        color: color,
        hint: Expanded(
          child: Row(
            children: [
              if (state.interactive)
                KeyedSubtree(
                  key: ExerciseKeys.hintButton,
                  child: ExerciseHintButton(
                    label: _hintLabel(l10n, state),
                    onPressed: cubit.askHint,
                  ),
                ),
              // Com a nota fechada, a posição vai para a análise do Lichess.
              if (lichess != null && state.interactive) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: lichess),
              ],
              if (state.phase == ExercisePhase.waiting) ...[
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(l10n.lessonThinking),
              ],
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppShape.small),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: ValueListenableBuilder<Duration>(
                    valueListenable: _elapsed,
                    builder: (context, value, _) {
                      final text = StepClock.format(value);
                      return TimeDisplay(
                        key: ExerciseKeys.timer,
                        value: text,
                        semanticsLabel: text,
                        size: TimeDisplaySize.inline,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Nota fechada: este é treino livre.
    if (!state.locked) return actions;
    return ColoredBox(
      color: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              l10n.exerciseScoreLocked,
              key: ExerciseKeys.locked,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          actions,
        ],
      ),
    );
  }
}

/// A fala do balão: o texto, os parágrafos da folha e, à parte, a dica do
/// borrar.
typedef SpeechLine = ({String text, List<String> paragraphs, String? tip});
