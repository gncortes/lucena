import '../../../domain/models/analytics_event.dart';
import '../../core/analytics/analytics_context.dart';

import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/course/training_badge.dart';
import '../../core/widgets/exercise_actions.dart';
import '../../core/widgets/game_board_hero.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../core/widgets/time_display.dart';
import '../../endgames/widgets/grade_widgets.dart';
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
    this.preview,
    this.homeHero = false,
    super.key,
  });
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final String goalKey, title;
  final Character teacher;
  final TrainingExerciseState? preview;
  final bool homeHero;
  final VoidCallback onNextGoal;
  final ValueChanged<String> onRedoLesson;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TrainingExerciseCubit(
      repository: repository,
      config: config,
      now: now,
      goalKey: goalKey,
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
  Timer? _timer;

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
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          context.read<TrainingExerciseCubit>().state.phase ==
              TrainingExercisePhase.playing) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TrainingExerciseCubit, TrainingExerciseState>(
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
      final boardCenter = BoardViewport.usefulHeightOf(context) / 2 - 64;
      final screen = MediaQuery.sizeOf(context);
      // Preserve the natural speech/header when a full-width board cannot fit.
      final fullWidthFits =
          boardCenter - screen.width / 2 >= (screen.height < 780 ? 80 : 112);
      return Scaffold(
        key: TrainingKeys.exerciseScreen,
        appBar: LucenaAppBar(
          toolbarHeight: 64,
          title: Text(widget.screen.title),
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
                  child: CenteredBoardLayout(
                    centerY: boardCenter,
                    minFraction: fullWidthFits ? 1 : 0,
                    reserveTop: 120,
                    reserveBottom: 72,
                    gap: 0,
                    shrinkSides: false,
                    top: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textTheme: Theme.of(context).textTheme.copyWith(
                            bodyLarge: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        child: TeacherSpeech(
                          teacher: widget.screen.teacher,
                          avatarSize: 40,
                          bubbleAboveHeader: true,
                          trainingLayout: true,
                          text: result
                              ? (state.correct
                                    ? l.exerciseSayCorrect
                                    : l.exerciseSayWrong)
                              : l.trainingFindMove(
                                  exercise.fen.split(' ')[1] == 'b'
                                      ? 'black'
                                      : 'white',
                                ),
                          speechContext: SpeechContext.teaching,
                        ),
                      ),
                    ),
                    board: LayoutBuilder(
                      builder: (context, box) =>
                          _board(context, state, box.maxWidth),
                    ),
                    bottom: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: result ? 56 : 48,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  if (result)
                                    Material(
                                      color: state.correct
                                          ? Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                          : Theme.of(context)
                                                .colorScheme
                                                .errorContainer,
                                      borderRadius: BorderRadius.circular(
                                        AppShape.full,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          spacing: 8,
                                          children: [
                                            Icon(
                                              state.correct
                                                  ? Icons.check_circle
                                                  : Icons.highlight_off,
                                              color: state.correct
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onErrorContainer,
                                            ),
                                            Text(
                                              state.correct
                                                  ? l.exerciseSolvedCorrect
                                                  : l.trainingWrongResult,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: state.correct
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .onPrimaryContainer
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onErrorContainer,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (!result || state.hint)
                                    TrainingBadge.difficulty(
                                      context,
                                      exercise.stars,
                                    ),
                                  if (state.hint)
                                    TrainingBadge.withHint(context),
                                ],
                              ),
                              if (result)
                                Text(
                                  state.hint || !state.correct
                                      ? l.trainingTomorrowEasier
                                      : l.trainingTomorrowHarder,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        if (state.error)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l.trainingExerciseSaveError,
                              key: TrainingKeys.exerciseSaveError,
                            ),
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
                  child: ExerciseActions(
                    hint: state.phase == TrainingExercisePhase.playing
                        ? ExerciseHintButton(
                            key: TrainingKeys.exerciseHint,
                            label: l.exerciseHintFree,
                            onPressed: cubit.hint,
                          )
                        : null,
                    leading: !result
                        ? TimeDisplay(
                            value: _time(cubit.elapsed),
                            semanticsLabel: _time(cubit.elapsed),
                          )
                        : null,
                    actions: [
                      if (result)
                        ExerciseAction(
                          label: state.correct
                              ? l.trainingSeeExplanation
                              : l.trainingSeeSolution,
                          key: TrainingKeys.secondary,
                          onPressed: () => _solution(context, state),
                        ),
                      if (result)
                        ExerciseAction(
                          label: l.trainingNextGoal,
                          primary: true,
                          key: TrainingKeys.nextGoal,
                          onPressed: () {
                            if (cubit.next()) widget.screen.onNextGoal();
                          },
                        ),
                      if (state.error)
                        ExerciseAction(
                          label: l.lessonRetry,
                          primary: true,
                          key: TrainingKeys.exerciseRetry,
                          onPressed:
                              state.phase == TrainingExercisePhase.playing
                              ? cubit.hint
                              : cubit.save,
                        ),
                    ],
                  ),
                ),
              ),
      );
    },
  );

  static String _time(Duration time) =>
      '${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _board(
    BuildContext context,
    TrainingExerciseState state,
    double size,
  ) {
    final cubit = context.read<TrainingExerciseCubit>();
    final position = GameRules.fromFen(state.fen!)!;
    final side = state.exercise!.fen.split(' ')[1] == 'b'
        ? Side.black
        : Side.white;
    final playing = state.phase == TrainingExercisePhase.playing;
    final data = GameData(
      fen: state.fen!,
      playerSide: !playing
          ? PlayerSide.none
          : side == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: position.turn,
      validMoves: playing ? GameRules.legalMoves(position) : const {},
      lastMove: state.lastMove == null ? null : Move.parse(state.lastMove!),
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
    final hint = state.hint && playing
        ? Move.parse(state.exercise!.solution[state.cursor])
        : null;
    final board = Directionality(
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
              color: Theme.of(context).colorScheme.primary,
              orig: hint.from,
              dest: hint.to,
            ),
        },
        onMove: (move, {viaDragAndDrop}) => cubit.play(move.uci),
      ),
    );
    return widget.screen.homeHero
        ? GameBoardHero(orientation: side, child: board)
        : board;
  }

  void _solution(BuildContext context, TrainingExerciseState state) {
    final exercise = state.exercise!;
    final san = GameRules.sanLine(
      GameRules.fromFen(exercise.fen)!,
      exercise.solution,
    );
    showLucenaSheet<void>(
      context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(san.join(' '), textDirection: TextDirection.ltr),
      ),
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
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  height: 28 / 22,
                  fontWeight: FontWeight.w800,
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
                      foregroundColor: AppColors.white,
                      child: Icon(
                        day.earned ? Icons.check : Icons.close,
                        size: 20,
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.copyWith(
                    bodyLarge: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                child: TeacherSpeech(
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
