import '../../../domain/models/load_failure.dart';
import '../../core/theme/app_icon_size.dart';

import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/skeleton.dart';

import '../../course_guide/widgets/training_load_error.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../routing/routes.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/theme_cycle.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/training_canvas_layout.dart';
import '../../lesson_script/widgets/script_move_list.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/script_speech_sheet.dart';
import '../../core/widgets/lesson_sound_dialog.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../endgames/widgets/grade_widgets.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/training_exercise_cubit.dart';
import '../../core/motion/tabuleiro_animado.dart';
import '../../core/motion/retorno_do_lance.dart';
import '../../core/motion/tabuleiro_hero.dart';
import '../../core/motion/troca_com_fade.dart';

/// Course-neutral destination. Navigation callbacks run only after persistence.
class TrainingExerciseScreen extends StatelessWidget {
  const TrainingExerciseScreen({
    required this.repository,
    required this.config,
    required this.now,
    required this.goalKey,
    required this.title,
    required this.teacher,
    required this.onNextGoal,
    required this.onRedoLesson,
    this.practiceTheme,
    this.practiceExerciseId,
    this.heroTag,
    this.preview,
    this.previewSpeech,
    super.key,
  });
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final String goalKey, title;
  final String? practiceTheme, practiceExerciseId;
  final Character teacher;
  final VoidCallback onNextGoal;
  final ValueChanged<String> onRedoLesson;
  final Object? heroTag;
  final TrainingExerciseState? preview;

  /// Explicit visual fixture text; ignored without a preview state.
  final String? previewSpeech;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TrainingExerciseCubit(
      repository: repository,
      config: config,
      now: now,
      goalKey: goalKey,
      practiceTheme: practiceTheme,
      practiceExerciseId: practiceExerciseId,
      analytics: context.analytics,
      trainingAnalytics: context.trainingAnalytics,
    )..load(),
    child: _ExerciseView(screen: this),
  );
}

class _ExerciseView extends StatefulWidget {
  const _ExerciseView({required this.screen});
  final TrainingExerciseScreen screen;
  @override
  State<_ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends State<_ExerciseView> {
  /// Uma posição por tentativa: "Tentar de novo" e "Ver solução" começam
  /// outra, que entra pronta num fade enquanto a anterior some (H-ANI-03).
  final _controllers = <int, ChessboardController>{};
  int _attempt = 0;
  TrainingExercisePhase? _phase;

  /// O tabuleiro guarda o estado quando o retorno do lance o envolve.
  final _boardKeys = <int, GlobalKey>{};
  String? _heroId;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<TrainingExerciseCubit, TrainingExerciseState>(
    listenWhen: (before, after) => !before.error && after.error,
    listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.trainingExerciseSaveError)),
    ),
    builder: (context, state) {
      final loading = state.phase == TrainingExercisePhase.loading;
      if (loading && widget.screen.preview != null) {
        state = widget.screen.preview!;
      }
      final l = context.l10n;
      if (state.phase == TrainingExercisePhase.end) {
        return _CycleEnd(screen: widget.screen, state: state);
      }
      final cubit = context.read<TrainingExerciseCubit>();
      final exercise = state.exercise;
      final ready =
          exercise != null &&
          state.fen != null &&
          state.phase != TrainingExercisePhase.expired;
      final result = state.phase == TrainingExercisePhase.result;
      final feedback = result ? state.errorFeedback : null;
      final speech =
          (widget.screen.preview != null
              ? widget.screen.previewSpeech
              : null) ??
          (state.solving && !result
              ? l.trainingSolutionPrompt
              : feedback ??
                    (result
                        ? state.displayedCorrect
                              ? l.trainingFixedCorrect
                              : l.trainingFixedWrong
                        : state.hint && exercise?.hintText != null
                        ? exercise!.hintText!
                        : exercise?.statement ?? l.trainingFixedPrompt));
      final moves = state.playedMoves;
      final sans = exercise == null
          ? <String>[]
          : GameRules.sanLine(GameRules.fromFen(exercise.fen)!, moves);
      final start = exercise == null ? null : GameRules.fromFen(exercise.fen)!;
      if (state.phase == TrainingExercisePhase.unavailable) {
        return trainingLoadError(context, state.failure, cubit.load);
      }
      if (state.phase == TrainingExercisePhase.expired) {
        // A meta saiu do dia no meio do exercício: erro padrão, com ação.
        return trainingLoadError(context, LoadFailure.unavailable, cubit.load);
      }
      return Scaffold(
        key: TrainingKeys.exerciseScreen,
        appBar: LucenaAppBar(
          leading: IconButton(
            icon: const Icon(CanvasSymbols.arrowBack),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true,
          title: Text(
            widget.screen.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: BoardViewport(
          usefulHeight: BoardViewport.usefulHeightOf(context),
          bottomBar: ready ? TrainingCanvasFooter.height : 0,
          child: SafeArea(
            child: !ready
                ? const SkeletonList()
                : IgnorePointer(
                    ignoring: loading,
                    child: TrainingCanvasPage(
                      pageKey: TrainingKeys.exercisePage,
                      teacher: widget.screen.teacher,
                      text: speech,
                      onOpen: () => _feedback(context, speech),
                      boardBuilder: (size) => Builder(
                        builder: (context) => _board(context, state, size),
                      ),
                      notation: _ExerciseNotation(
                        sans: sans,
                        start: start,
                        saveError: state.error,
                      ),
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: !ready
            ? null
            : _ExerciseFooter(
                state: state,
                exercise: exercise,
                moves: moves,
                loading: loading,
                onNextGoal: widget.screen.onNextGoal,
              ),
      );
    },
  );

  Widget _board(
    BuildContext context,
    TrainingExerciseState state,
    double size,
  ) {
    final cubit = context.read<TrainingExerciseCubit>();
    final failed =
        state.phase == TrainingExercisePhase.result && !state.displayedCorrect
        ? state.errorSnapshot
        : null;
    final wrongMove = failed == null ? null : Move.parse(failed.wrongMove);
    final failedPosition = failed == null || wrongMove == null
        ? null
        : GameRules.play(GameRules.fromFen(failed.fen)!, wrongMove)?.position;
    final fen = failedPosition?.fen ?? state.fen!;
    final position = GameRules.fromFen(fen)!;
    final side = state.exercise!.fen.split(' ')[1] == 'b'
        ? Side.black
        : Side.white;
    final playing = state.phase == TrainingExercisePhase.playing;
    final data = GameData(
      fen: fen,
      playerSide: !playing
          ? PlayerSide.none
          : side == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: position.turn,
      validMoves: playing ? GameRules.legalMoves(position) : const {},
      lastMove: failedPosition != null
          ? wrongMove
          : state.lastMove == null
          ? null
          : Move.parse(state.lastMove!),
      kingSquareInCheck: GameRules.checkedKing(position),
    );
    // Do resultado de volta ao jogo: tentativa nova, sem deslize de volta.
    if (_phase == TrainingExercisePhase.result &&
        state.phase == TrainingExercisePhase.playing) {
      _attempt++;
    }
    _phase = state.phase;
    final controller = _controllers[_attempt];
    if (controller == null) {
      _controllers[_attempt] = ChessboardController(game: data);
    } else {
      controller.updatePosition(data, animate: true, resetPremove: true);
    }
    final attempt = _attempt;
    final boardController = _controllers[attempt]!;
    final settings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    final hint = (state.hint || state.solving) && playing
        ? Move.parse(state.exercise!.solution[state.cursor])
        : null;
    Widget board = Directionality(
      textDirection: TextDirection.ltr,
      // H-ANI-10: deslize do kit, captura que encolhe e halo do xeque.
      child: TabuleiroAnimado(
        controlador: boardController,
        orientacao: side,
        tamanho: size,
        pecas: settings.chessground.pieceAssets,
        child: Chessboard(
          key: TrainingKeys.exerciseBoard,
          size: size,
          controller: boardController,
          orientation: side,
          settings: TabuleiroAnimado.ajustes(context, settings.chessground),
          shapes: {
            if (hint is NormalMove)
              Arrow(
                color: state.solving
                    ? AppColors.trainingSolutionArrow
                    : Theme.of(context).colorScheme.primary,
                orig: hint.from,
                dest: hint.to,
              ),
          },
          onMove: (move, {viaDragAndDrop}) => cubit.play(move.uci),
        ),
      ),
    );
    // H-ANI-11/12: no resultado, a casa do lance pisca, o selo salta na peça
    // e o tabuleiro respira (acerto) ou fica parado (erro).
    final retornoMove = state.phase != TrainingExercisePhase.result
        ? null
        : wrongMove ??
              (state.lastMove == null ? null : Move.parse(state.lastMove!));
    board = KeyedSubtree(
      key: _boardKeys.putIfAbsent(attempt, GlobalKey.new),
      child: board,
    );
    if (retornoMove is NormalMove) {
      board = RetornoDoLance(
        key: ValueKey('${state.practicing} $fen ${retornoMove.uci}'),
        tipo: wrongMove != null ? TipoDeRetorno.erro : TipoDeRetorno.acerto,
        casa: retornoMove.to,
        orientacao: side,
        tamanho: size,
        vibrar: context.read<SettingsCubit>().state?.vibration ?? true,
        child: board,
      );
    }
    // H-ANI-03: o tabuleiro fica parado; só a posição troca em fade.
    board = TrocaComFade(chave: attempt, child: board);
    if (widget.screen.heroTag case final tag?) {
      board = Hero(tag: tag, child: board);
    } else {
      // H-ANI-02: o tabuleiro voa da tela de antes com o mesmo id (o FEN
      // com que a tela abre).
      board = TabuleiroHero(id: _heroId ??= state.exercise!.fen, child: board);
    }
    return board;
  }

  void _feedback(BuildContext context, String text) {
    showScriptSpeechSheet(
      context,
      sheetKey: TrainingKeys.exerciseFeedbackSheet,
      canvasLayout: true,
      action: LessonVoiceButton(
        audible: false,
        speed: 1,
        showSpeedBadge: false,
        canvasLayout: true,
        onPressed: () => showLessonSoundDialog(context),
      ),
      viktor: widget.screen.teacher,
      title: context.l10n.teacherName(widget.screen.teacher.name),
      texts: [text],
    );
  }
}

class _CycleEnd extends StatelessWidget {
  const _CycleEnd({required this.screen, required this.state});

  final TrainingExerciseScreen screen;
  final TrainingExerciseState state;

  void _cycleAction(
    BuildContext context,
    TrainingExerciseState state,
    String action,
    VoidCallback next,
  ) {
    unawaited(
      context.analytics
          .log(
            AnalyticsEvents.treinoCicloAcao(
              curso: screen.config.course.name,
              aulaId: state.goal!.ref,
              acao: action,
            ),
          )
          .catchError((Object _) {}),
    );
    next();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cycle = state.cycle!;
    final firm = cycle.phase == ThemePhase.firm;
    final reinforce = cycle.phase == ThemePhase.reinforce;
    final redoAfter = !firm && state.reinforcement;
    final days = state.reinforcement ? cycle.reinforceDays : cycle.cycleDays;
    final score = state.reinforcement ? cycle.reinforceScore : cycle.score;
    final title = firm
        ? l.trainingEndFirmTitle(screen.title)
        : reinforce
        ? l.trainingEndReinforceTitle
        : redoAfter
        ? l.trainingEndRedoAfterTitle
        : l.trainingEndRedoTitle;
    final body = firm
        ? l.trainingEndFirmBody
        : reinforce
        ? l.trainingEndReinforceBody(cycle.reinforcement.length, screen.title)
        : redoAfter
        ? l.trainingEndRedoAfterBody
        : l.trainingEndRedoBody;
    // The Canvas example mentions recovering from a hard mistake. Only say
    // that when it happened; a perfect cycle must not invent a mistake.
    final recoveredHard = days.indexed.any((entry) {
      final (index, day) = entry;
      if (day.stars != 3 || day.correct || index + 1 == days.length) {
        return false;
      }
      final next = days[index + 1];
      return next.earned &&
          DateTime.parse(next.date)
                  .difference(DateTime.parse(day.date))
                  .inDays ==
              1;
    });
    final viktor = firm
        ? (recoveredHard
              ? l.trainingEndFirmViktor
              : l.trainingEndFirmCleanViktor)
        : reinforce
        ? l.trainingEndReinforceViktor
        : redoAfter
        ? l.trainingEndRedoAfterViktor
        : l.trainingEndRedoViktor;
    return Scaffold(
      key: TrainingKeys.exerciseEnd,
      appBar: LucenaAppBar(
        leading: CloseButton(
          onPressed: () =>
              _cycleAction(context, state, 'voltar_metas', screen.onNextGoal),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _CycleHeader(
                grade: firm
                    ? ExerciseGrade.good
                    : reinforce
                    ? ExerciseGrade.passed
                    : ExerciseGrade.below,
                title: title,
                score: state.reinforcement
                    ? l.trainingEndReinforceScore(
                        days.where((d) => d.earned).length,
                        days.length,
                        score,
                      )
                    : l.trainingEndCycleScore(score),
              ),
              const SizedBox(height: 16),
              _CycleDays(days: days),
              const SizedBox(height: 12),
              _CycleBody(body: body, teacher: screen.teacher, viktor: viktor),
              if (state.error)
                Text(
                  l.trainingExerciseSaveError,
                  key: TrainingKeys.exerciseSaveError,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _CycleFooter(
        screen: screen,
        state: state,
        firm: firm,
        reinforce: reinforce,
        redoAfter: redoAfter,
        onAction: (action, next) => _cycleAction(context, state, action, next),
      ),
    );
  }
}

/// A medalha, o título e a pontuação do fim do ciclo.
class _CycleHeader extends StatelessWidget {
  const _CycleHeader({
    required this.grade,
    required this.title,
    required this.score,
  });

  final ExerciseGrade grade;
  final String title;
  final String score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        GradeMedal(grade: grade),
        // Canvas inline medal reserves four extra baseline pixels.
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            height: 24 / 16,
            letterSpacing: 0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Uma bolinha por dia do ciclo: acertou ou errou.
class _CycleDays extends StatelessWidget {
  const _CycleDays({required this.days});

  final List<ThemeDay> days;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final day in days)
          CircleAvatar(
            radius: 16,
            backgroundColor: day.earned
                ? AppColors.trainingDayCorrect
                : AppColors.trainingDayWrong,
            foregroundColor: AppColors.chessWhiteColor,
            child: Icon(
              day.earned ? Icons.check : Icons.close,
              size: AppIconSize.button,
            ),
          ),
      ],
    );
  }
}

/// O texto do resultado e a fala do Viktor.
class _CycleBody extends StatelessWidget {
  const _CycleBody({
    required this.body,
    required this.teacher,
    required this.viktor,
  });

  final String body;
  final Character teacher;
  final String viktor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.copyWith(
              bodyLarge: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 14, height: 20 / 14, letterSpacing: 0),
            ),
          ),
          child: TeacherSpeech(
            showSpeedBadge: false,
            canvasTrainingBalloon: true,
            teacher: teacher,
            avatarSize: 56,
            text: viktor,
            speechContext: SpeechContext.teaching,
          ),
        ),
      ],
    );
  }
}

/// Os botões do fim do ciclo; cada um registra a ação e segue.
class _CycleFooter extends StatelessWidget {
  const _CycleFooter({
    required this.screen,
    required this.state,
    required this.firm,
    required this.reinforce,
    required this.redoAfter,
    required this.onAction,
  });

  final TrainingExerciseScreen screen;
  final TrainingExerciseState state;
  final bool firm, reinforce, redoAfter;
  final void Function(String action, VoidCallback next) onAction;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<TrainingExerciseCubit>();
    return ActionsFooter(
      stacked: true,
      children: [
        FilledButton.icon(
          key: TrainingKeys.endPrimary,
          icon: Icon(firm || reinforce ? Icons.task_alt : Icons.replay),
          label: Text(
            firm
                ? l.trainingEndBackToGoals
                : reinforce
                ? l.trainingEndSeeGoals
                : l.trainingEndRedo,
          ),
          onPressed: () => onAction(
            firm
                ? 'voltar_metas'
                : reinforce
                ? 'ver_metas'
                : 'refazer_aula',
            firm || reinforce
                ? screen.onNextGoal
                : () => screen.onRedoLesson(state.goal!.ref),
          ),
        ),
        if (!firm)
          OutlinedButton.icon(
            key: TrainingKeys.endSecondary,
            icon: redoAfter
                ? null
                : Icon(reinforce ? Icons.menu_book : Icons.task_alt),
            label: Text(
              reinforce
                  ? l.trainingEndReviewLesson
                  : redoAfter
                  ? l.trainingEndNotNow
                  : l.trainingEndReinforceFirst,
            ),
            onPressed: reinforce
                ? () => onAction(
                    'rever_aula',
                    () => screen.onRedoLesson(state.goal!.ref),
                  )
                : redoAfter
                ? () => onAction('agora_nao', screen.onNextGoal)
                : () async {
                    if (await cubit.reinforceFirst() && context.mounted) {
                      onAction('reforco_antes', screen.onNextGoal);
                    }
                  },
          ),
      ],
    );
  }
}

/// A lista de lances jogados e o aviso de erro ao salvar.
class _ExerciseNotation extends StatelessWidget {
  const _ExerciseNotation({
    required this.sans,
    required this.start,
    required this.saveError,
  });

  final List<String> sans;
  final Position? start;
  final bool saveError;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        ScriptMoveList(
          moves: [
            for (var i = 0; i < sans.length; i++)
              ScriptMoveEntry(
                id: '$i',
                san: sans[i],
                number:
                    start!.fullmoves +
                    (i + (start!.turn == Side.black ? 1 : 0)) ~/ 2,
                side: i.isEven ? start!.turn : start!.turn.opposite,
                variant: false,
              ),
          ],
          currentId: sans.isEmpty ? null : '${sans.length - 1}',
          onTap: (_) {},
        ),
        if (saveError)
          Text(
            l.trainingExerciseSaveError,
            key: TrainingKeys.exerciseSaveError,
          ),
      ],
    );
  }
}

/// O rodapé do exercício: dica ou análise, solução e o botão principal.
class _ExerciseFooter extends StatelessWidget {
  const _ExerciseFooter({
    required this.state,
    required this.exercise,
    required this.moves,
    required this.loading,
    required this.onNextGoal,
  });

  final TrainingExerciseState state;
  final TrainingExercise exercise;
  final List<String> moves;
  final bool loading;
  final VoidCallback onNextGoal;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<TrainingExerciseCubit>();
    final result = state.phase == TrainingExercisePhase.result;
    return SafeArea(
      child: IgnorePointer(
        ignoring: loading,
        child: TrainingCanvasFooter(
          // A lupa só no acerto (PropV1TreinoAcertou); no erro, o
          // rodapé é "Ver a solução" + "Tentar novamente".
          leading: result && state.displayedCorrect
              ? TrainingCanvasFooter.round(
                  key: TrainingKeys.exerciseAnalyze,
                  icon: CanvasSymbols.search,
                  label: l.learningAnalysisTitle,
                  onPressed: () => context.push(
                    Routes.learningAnalysisAt(
                      exercise.fen,
                      moves: moves,
                      orientation: exercise.fen.split(' ')[1] == 'b'
                          ? 'black'
                          : 'white',
                    ),
                  ),
                )
              // Sem dica cadastrada a lâmpada não aparece
              // (canvas LicaoPraticaSemDica).
              : state.phase == TrainingExercisePhase.playing &&
                    !state.solving &&
                    !state.hint &&
                    exercise.hintText != null
              ? TrainingCanvasFooter.hint(
                  key: TrainingKeys.exerciseHint,
                  label: l.exerciseHintFree,
                  onPressed: cubit.hint,
                )
              : null,
          secondary: result && !state.displayedCorrect
              ? TrainingCanvasFooter.button(
                  key: TrainingKeys.secondary,
                  label: l.trainingSeeSolution,
                  onPressed: cubit.showSolution,
                )
              : null,
          primary: state.error
              ? TrainingCanvasFooter.button(
                  key: TrainingKeys.exerciseRetry,
                  label: l.lessonRetry,
                  primary: true,
                  onPressed: state.phase == TrainingExercisePhase.playing
                      ? cubit.hint
                      : cubit.save,
                )
              : state.canRetryPractice
              ? TrainingCanvasFooter.button(
                  key: TrainingKeys.exercisePracticeRetry,
                  label: l.lessonRetry,
                  primary: true,
                  onPressed: cubit.retryPractice,
                )
              : result
              ? TrainingCanvasFooter.button(
                  key: TrainingKeys.nextGoal,
                  label: cubit.historicalPractice
                      ? l.trainingViewProgress
                      : l.trainingNextGoal,
                  primary: true,
                  onPressed: () {
                    if (cubit.next()) onNextGoal();
                  },
                )
              : null,
        ),
      ),
    );
  }
}
