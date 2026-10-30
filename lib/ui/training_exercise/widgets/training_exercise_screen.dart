import '../../core/theme/app_icon_size.dart';

import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../routing/routes.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/training_canvas_layout.dart';
import '../../lesson_script/widgets/script_move_list.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/course/training_badge.dart';
import '../../core/widgets/game_board_hero.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/script_speech_sheet.dart';
import '../../core/widgets/lesson_sound_dialog.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../endgames/widgets/grade_widgets.dart';
import '../../endgames/widgets/stars_row.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/training_exercise_cubit.dart';

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
    this.homeHero = false,
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
  final bool homeHero;

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
  ChessboardController? _controller;

  void _cycleAction(
    TrainingExerciseState state,
    String action,
    VoidCallback next,
  ) {
    unawaited(
      context.analytics
          .log(
            AnalyticsEvents.treinoCicloAcao(
              curso: widget.screen.config.course.name,
              aulaId: state.goal!.ref,
              acao: action,
            ),
          )
          .catchError((Object _) {}),
    );
    next();
  }

  @override
  void dispose() {
    _controller?.dispose();
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
      if (state.phase == TrainingExercisePhase.end) return _end(context, state);
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
                        : l.trainingFixedPrompt));
      final moves = state.playedMoves;
      final sans = exercise == null
          ? <String>[]
          : GameRules.sanLine(GameRules.fromFen(exercise.fen)!, moves);
      final start = exercise == null ? null : GameRules.fromFen(exercise.fen)!;
      return Scaffold(
        key: TrainingKeys.exerciseScreen,
        appBar: LucenaAppBar(
          toolbarHeight: 64,
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
          actions: [
            if (exercise != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Semantics(
                  key: TrainingKeys.exerciseTitleDifficulty,
                  label: TrainingBadge.difficultyLabel(context, exercise.stars),
                  child: Icon(
                    CanvasSymbols.star,
                    size: AppIconSize.standard,
                    fill:
                        state.hint ||
                            state.solving ||
                            state.errorSnapshot != null ||
                            (result && !state.correct)
                        ? 0
                        : 1,
                    color: StarsRow.colorFor(exercise.stars),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: !ready
              ? Center(
                  child:
                      state.phase == TrainingExercisePhase.unavailable ||
                          state.phase == TrainingExercisePhase.expired
                      ? Text(
                          state.phase == TrainingExercisePhase.expired
                              ? l.trainingExerciseExpired
                              : l.exerciseMissing,
                        )
                      : const CircularProgressIndicator(),
                )
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
                    notation: Column(
                      children: [
                        ScriptMoveList(
                          moves: [
                            for (var i = 0; i < sans.length; i++)
                              ScriptMoveEntry(
                                id: '$i',
                                san: sans[i],
                                number:
                                    start!.fullmoves +
                                    (i + (start.turn == Side.black ? 1 : 0)) ~/
                                        2,
                                side: i.isEven
                                    ? start.turn
                                    : start.turn.opposite,
                                variant: false,
                              ),
                          ],
                          currentId: sans.isEmpty ? null : '${sans.length - 1}',
                          onTap: (_) {},
                        ),
                        if (state.error)
                          Text(
                            l.trainingExerciseSaveError,
                            key: TrainingKeys.exerciseSaveError,
                          ),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: !ready
            ? null
            : SafeArea(
                child: IgnorePointer(
                  ignoring: loading,
                  child: TrainingCanvasFooter(
                    leading: result
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
                        : state.phase == TrainingExercisePhase.playing &&
                              !state.solving
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
                            onPressed:
                                state.phase == TrainingExercisePhase.playing
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
                              if (cubit.next()) widget.screen.onNextGoal();
                            },
                          )
                        : null,
                  ),
                ),
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
    if (_controller == null) {
      _controller = ChessboardController(game: data);
    } else {
      _controller!.updatePosition(data, animate: true, resetPremove: true);
    }
    final settings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    final hint = (state.hint || state.solving) && playing
        ? Move.parse(state.exercise!.solution[state.cursor])
        : null;
    Widget board = Directionality(
      textDirection: TextDirection.ltr,
      child: Chessboard(
        key: TrainingKeys.exerciseBoard,
        size: size,
        controller: _controller!,
        orientation: side,
        settings: settings.chessground,
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
    );
    if (widget.screen.homeHero) {
      board = GameBoardHero(orientation: side, child: board);
    } else if (widget.screen.heroTag case final tag?) {
      board = Hero(tag: tag, child: board);
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

  Widget _end(BuildContext context, TrainingExerciseState state) {
    final l = context.l10n;
    final cubit = context.read<TrainingExerciseCubit>();
    final cycle = state.cycle!;
    final firm = cycle.phase == ThemePhase.firm;
    final reinforce = cycle.phase == ThemePhase.reinforce;
    final redoAfter = !firm && state.reinforcement;
    final days = state.reinforcement ? cycle.reinforceDays : cycle.cycleDays;
    final score = state.reinforcement ? cycle.reinforceScore : cycle.score;
    final title = firm
        ? l.trainingEndFirmTitle(widget.screen.title)
        : reinforce
        ? l.trainingEndReinforceTitle
        : redoAfter
        ? l.trainingEndRedoAfterTitle
        : l.trainingEndRedoTitle;
    final body = firm
        ? l.trainingEndFirmBody
        : reinforce
        ? l.trainingEndReinforceBody(
            cycle.reinforcement.length,
            widget.screen.title,
          )
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
    final theme = Theme.of(context);
    return Scaffold(
      key: TrainingKeys.exerciseEnd,
      appBar: LucenaAppBar(
        toolbarHeight: 64,
        leading: CloseButton(
          onPressed: () =>
              _cycleAction(state, 'voltar_metas', widget.screen.onNextGoal),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              GradeMedal(
                grade: firm
                    ? ExerciseGrade.good
                    : reinforce
                    ? ExerciseGrade.passed
                    : ExerciseGrade.below,
              ),
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
                state.reinforcement
                    ? l.trainingEndReinforceScore(
                        days.where((d) => d.earned).length,
                        days.length,
                        score,
                      )
                    : l.trainingEndCycleScore(score),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  height: 24 / 16,
                  letterSpacing: 0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
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
              ),
              const SizedBox(height: 12),
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
                    bodyLarge: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                child: TeacherSpeech(
                  showSpeedBadge: false,
                  canvasTrainingBalloon: true,
                  teacher: widget.screen.teacher,
                  avatarSize: 56,
                  text: viktor,
                  speechContext: SpeechContext.teaching,
                ),
              ),
              if (state.error)
                Text(
                  l.trainingExerciseSaveError,
                  key: TrainingKeys.exerciseSaveError,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionsFooter(
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
            onPressed: () => _cycleAction(
              state,
              firm
                  ? 'voltar_metas'
                  : reinforce
                  ? 'ver_metas'
                  : 'refazer_aula',
              firm || reinforce
                  ? widget.screen.onNextGoal
                  : () => widget.screen.onRedoLesson(state.goal!.ref),
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
                  ? () => _cycleAction(
                      state,
                      'rever_aula',
                      () => widget.screen.onRedoLesson(state.goal!.ref),
                    )
                  : redoAfter
                  ? () => _cycleAction(
                      state,
                      'agora_nao',
                      widget.screen.onNextGoal,
                    )
                  : () async {
                      if (await cubit.reinforceFirst() && mounted) {
                        _cycleAction(
                          state,
                          'reforco_antes',
                          widget.screen.onNextGoal,
                        );
                      }
                    },
            ),
        ],
      ),
    );
  }
}
