import 'dart:async';

import 'package:dartchess/dartchess.dart';

import '../../../domain/use_cases/game_rules.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/use_cases/training/training_analytics.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/day_goals.dart';
import '../../../domain/models/training/theme_cycle.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/complete_training_goal.dart';
import '../../../domain/use_cases/training/build_day_goals.dart';
import '../../../domain/use_cases/training/play_training_exercise.dart';
import '../../../domain/use_cases/training/theme_cycle_rules.dart';
import '../../../domain/use_cases/training/training_date.dart';

enum TrainingExercisePhase {
  loading,
  playing,
  hintSaving,
  saving,
  result,
  end,
  unavailable,
  expired,
}

final class _ExpiredExercise implements Exception {
  const _ExpiredExercise();
}

final class _AttemptNow implements Now {
  const _AttemptNow(this.value);
  final DateTime value;
  @override
  DateTime call() => value;
}

final class TrainingExerciseState {
  const TrainingExerciseState({
    this.phase = TrainingExercisePhase.loading,
    this.exercise,
    this.goal,
    this.cycle,
    this.fen,
    this.lastMove,
    this.cursor = 0,
    this.hint = false,
    this.correct = false,
    this.reinforcement = false,
    this.error = false,
    this.errorFeedback,
    this.errorSnapshot,
    this.practicing = false,
    this.practiceCorrect = false,
    this.solving = false,
  });
  final TrainingExercisePhase phase;
  final TrainingExercise? exercise;
  final TrainingGoal? goal;
  final ThemeCycle? cycle;
  final String? fen, lastMove;
  final int cursor;
  final bool hint, correct, reinforcement, error;
  final String? errorFeedback;
  final TrainingExerciseError? errorSnapshot;
  final bool practicing, practiceCorrect, solving;
  bool get displayedCorrect => practicing ? practiceCorrect : correct;
  bool get canRetryPractice =>
      phase == TrainingExercisePhase.result &&
      !displayedCorrect &&
      errorSnapshot != null;

  /// The actual continuation for notation and analysis, including accepted
  /// alternatives. A main-line continuation is never attributed to a branch.
  List<String> get playedMoves {
    final source = exercise;
    if (source == null) return const [];
    final snapshot = errorSnapshot;
    if (phase == TrainingExercisePhase.result &&
        !displayedCorrect &&
        snapshot != null) {
      return [...source.solution.take(snapshot.cursor), snapshot.wrongMove];
    }
    if (lastMove != null) {
      for (var index = 0; index < source.solution.length; index += 2) {
        if (!source.alternativesAt(index).contains(lastMove)) continue;
        final candidate = [...source.solution.take(index), lastMove!];
        var position = GameRules.fromFen(source.fen);
        for (final uci in candidate) {
          final move = Move.parse(uci);
          position = position == null || move == null
              ? null
              : GameRules.play(position, move)?.position;
        }
        if (position?.fen == fen) return candidate;
      }
    }
    return source.solution.take(cursor).toList();
  }

  TrainingExerciseState copyWith({
    TrainingExercisePhase? phase,
    ThemeCycle? cycle,
    String? fen,
    String? lastMove,
    int? cursor,
    bool? hint,
    bool? correct,
    bool error = false,
    String? errorFeedback,
    bool clearFeedback = false,
    TrainingExerciseError? errorSnapshot,
    bool? practicing,
    bool? practiceCorrect,
    bool? solving,
  }) => TrainingExerciseState(
    phase: phase ?? this.phase,
    exercise: exercise,
    goal: goal,
    cycle: cycle ?? this.cycle,
    fen: fen ?? this.fen,
    lastMove: lastMove ?? this.lastMove,
    cursor: cursor ?? this.cursor,
    hint: hint ?? this.hint,
    correct: correct ?? this.correct,
    reinforcement: reinforcement,
    error: error,
    errorFeedback: clearFeedback ? null : errorFeedback ?? this.errorFeedback,
    errorSnapshot: errorSnapshot ?? this.errorSnapshot,
    practicing: practicing ?? this.practicing,
    practiceCorrect: practiceCorrect ?? this.practiceCorrect,
    solving: solving ?? this.solving,
  );
}

final class TrainingExerciseCubit extends Cubit<TrainingExerciseState> {
  TrainingExerciseCubit({
    required this.repository,
    required this.config,
    required this.now,
    this.analytics = const NoAnalyticsRepository(),
    this.trainingAnalytics,
    required this.goalKey,
    this.origin = 'metas',
    this.practiceTheme,
    this.practiceExerciseId,
  }) : super(const TrainingExerciseState());
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final AnalyticsRepository analytics;
  final TrainingAnalytics? trainingAnalytics;
  DateTime? _openedAt;
  Now get _attemptNow => _AttemptNow(_openedAt ?? now());
  Timer? _saveRetry;

  @override
  Future<void> close() async {
    _saveRetry?.cancel();
    await super.close();
  }

  Future<void> _log(AnalyticsEvent event) {
    unawaited(
      Future<void>.sync(() => analytics.log(event)).catchError((Object _) {}),
    );
    return Future<void>.value();
  }

  final String goalKey;
  final String origin;

  /// Explicit history mode; loading and playing never mutate course progress.
  final String? practiceTheme, practiceExerciseId;
  bool get historicalPractice => practiceTheme != null;
  DateTime? _started;
  Duration? _finished;
  Map<String, String> _feedback = const {};
  String? _feedbackFor(
    TrainingExerciseError snapshot,
    TrainingExercise exercise,
  ) => exercise.mock
      ? null
      : _feedback['${exercise.id}.${snapshot.cursor ~/ 2 + 1}.${snapshot.wrongMove}'];
  Duration get elapsed =>
      _finished ??
      (_started == null ? Duration.zero : now().difference(_started!));

  Future<void> load() async {
    try {
      final resources = await repository.resources(config.course);
      if (historicalPractice) {
        final saved = await repository.load(config.course);
        final cycle = saved.cycles[practiceTheme];
        final exercise = resources.banks[practiceTheme]
            ?.where((e) => e.id == practiceExerciseId)
            .firstOrNull;
        if (cycle == null ||
            exercise == null ||
            !cycle.days.any((d) => d.exerciseId == practiceExerciseId)) {
          throw StateError('Historical exercise unavailable');
        }
        PlayTrainingExercise(exercise);
        _openedAt = now();
        _started = now();
        _feedback = resources.errorFeedback[practiceTheme] ?? const {};
        emit(
          TrainingExerciseState(
            phase: TrainingExercisePhase.playing,
            exercise: exercise,
            goal: TrainingGoal(
              kind: GoalKind.exercise,
              ref: practiceTheme!,
              itemId: exercise.id,
              stars: exercise.stars,
            ),
            cycle: cycle,
            fen: exercise.fen,
            lastMove: exercise.lastMove,
            practicing: true,
          ),
        );
        return;
      }
      final saved = await repository.transact(
        config.course,
        (current) => BuildDayGoals(now, config)(current, resources),
      );
      if (isClosed) return;
      final goal = saved.day?.goals.where((g) => g.key == goalKey).firstOrNull;
      final exercise = resources.banks[goal?.ref]
          ?.where((e) => e.id == goal?.itemId)
          .firstOrNull;
      final cycle = saved.cycles[goal?.ref];
      if (goal == null ||
          exercise == null ||
          cycle == null ||
          (goal.kind != GoalKind.exercise && goal.kind != GoalKind.reinforce)) {
        throw StateError('Exercise unavailable');
      }
      PlayTrainingExercise(exercise); // Validate before accepting any attempt.
      _openedAt = now();
      _feedback = resources.errorFeedback[goal.ref] ?? const {};
      final snapshot = goal.exerciseError;
      final feedback = snapshot == null
          ? null
          : _feedbackFor(snapshot, exercise);
      final result = goal.done
          ? cycle.days
                .where(
                  (d) =>
                      d.exerciseId == exercise.id && d.date == saved.day!.date,
                )
                .lastOrNull
          : null;
      await trainingAnalytics?.restore(config.course, state: saved);
      if (!goal.done) {
        await trainingAnalytics?.startGoal(saved, goal, origin: origin);
      }
      _started =
          trainingAnalytics?.attempt(config.course, goal.key)?.started ?? now();
      _finished = goal.done
          ? (result?.elapsedMs == null
                ? Duration.zero
                : Duration(milliseconds: result!.elapsedMs!))
          : null;
      emit(
        TrainingExerciseState(
          phase: goal.done
              ? TrainingExercisePhase.result
              : TrainingExercisePhase.playing,
          exercise: exercise,
          goal: goal,
          cycle: cycle,
          fen: feedback != null ? snapshot!.fen : exercise.fen,
          lastMove: feedback != null ? snapshot!.lastMove : exercise.lastMove,
          cursor: snapshot?.cursor ?? 0,
          hint: result?.hint ?? goal.hintUsed,
          correct: result?.correct ?? false,
          reinforcement: goal.kind == GoalKind.reinforce,
          errorFeedback: feedback,
          errorSnapshot: snapshot,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const TrainingExerciseState(phase: TrainingExercisePhase.unavailable),
      );
    }
  }

  Future<void> hint() async {
    if (state.phase != TrainingExercisePhase.playing || state.hint) return;
    if (state.practicing) {
      emit(state.copyWith(hint: true));
      return;
    }
    emit(state.copyWith(phase: TrainingExercisePhase.hintSaving));
    try {
      final saved = await repository.transact(config.course, (current) async {
        final refreshed = current;
        final goal = refreshed.day?.goals
            .where((g) => g.key == goalKey && !g.done)
            .firstOrNull;
        if (goal == null ||
            refreshed.day?.date != trainingDate(_attemptNow())) {
          throw const _ExpiredExercise();
        }
        if (goal.hintUsed) return refreshed;
        final changed = refreshed.copyWith(
          day: refreshed.day!.copyWith(
            goals: [
              for (final g in refreshed.day!.goals)
                if (g.key == goalKey) g.withHint() else g,
            ],
          ),
        );
        return trainingAnalytics?.attach(changed) ?? changed;
      });
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: TrainingExercisePhase.playing,
          hint: saved.day!.goals.firstWhere((g) => g.key == goalKey).hintUsed,
        ),
      );
    } on _ExpiredExercise {
      if (!isClosed) {
        emit(state.copyWith(phase: TrainingExercisePhase.expired));
      }
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(phase: TrainingExercisePhase.playing, error: true));
      _saveRetry?.cancel();
      _saveRetry = Timer(const Duration(seconds: 1), () {
        if (!isClosed) unawaited(hint());
      });
    }
  }

  Future<void> play(String uci) async {
    if (state.phase != TrainingExercisePhase.playing) return;
    final before = state;
    if (before.solving && uci != before.exercise!.solution[before.cursor]) {
      return;
    }
    final step = PlayTrainingExercise(state.exercise!)
        .play(state.fen!, state.cursor, uci);
    TrainingExerciseError? snapshot;
    String? feedback;
    if (step.done && !step.correct) {
      snapshot = TrainingExerciseError(
        fen: before.fen!,
        cursor: before.cursor,
        wrongMove: uci,
        lastMove: before.lastMove,
        feedbackShown:
            !before.exercise!.mock &&
            _feedback.containsKey(
              '${before.exercise!.id}.${before.cursor ~/ 2 + 1}.$uci',
            ),
      );
      feedback = _feedbackFor(snapshot, before.exercise!);
    }
    emit(
      state.copyWith(
        fen: feedback == null ? step.fen : before.fen,
        cursor: step.cursor,
        lastMove: feedback == null ? step.lastMove : before.lastMove,
        correct: before.practicing ? before.correct : step.correct,
        practiceCorrect: before.practicing ? step.correct : false,
        errorSnapshot: snapshot,
        errorFeedback: feedback,
        clearFeedback: feedback == null,
        phase: step.done
            ? (before.practicing
                  ? TrainingExercisePhase.result
                  : TrainingExercisePhase.saving)
            : TrainingExercisePhase.playing,
      ),
    );
    if (step.done && before.practicing) _finished = elapsed;
    if (step.done && !before.practicing) {
      _finished = elapsed;
      await save();
    }
  }

  /// Practice follows a persisted failure; it cannot change the scored attempt.
  void retryPractice() {
    if (!state.canRetryPractice) return;
    final snapshot = state.errorSnapshot!;
    emit(
      TrainingExerciseState(
        phase: TrainingExercisePhase.playing,
        exercise: state.exercise,
        goal: state.goal,
        cycle: state.cycle,
        fen: snapshot.fen,
        lastMove: snapshot.lastMove,
        cursor: snapshot.cursor,
        hint: false,
        correct: state.correct,
        reinforcement: state.reinforcement,
        practicing: true,
        errorSnapshot: snapshot,
      ),
    );
  }

  /// Guided replay uses only the authored line and never rewrites the attempt.
  void showSolution() {
    if (state.phase != TrainingExercisePhase.result || state.exercise == null) {
      return;
    }
    emit(
      TrainingExerciseState(
        phase: TrainingExercisePhase.playing,
        exercise: state.exercise,
        goal: state.goal,
        cycle: state.cycle,
        fen: state.exercise!.fen,
        lastMove: state.exercise!.lastMove,
        correct: state.correct,
        reinforcement: state.reinforcement,
        practicing: true,
        solving: true,
        errorSnapshot: state.errorSnapshot,
      ),
    );
  }

  Future<void> save() async {
    if (historicalPractice || state.phase != TrainingExercisePhase.saving) {
      return;
    }
    try {
      final saved = await repository.transact(config.course, (current) async {
        final resources = await repository.resources(config.course);
        final refreshed = current;
        if (refreshed.day?.date != trainingDate(_attemptNow())) {
          throw const _ExpiredExercise();
        }
        if (!(refreshed.day?.goals.any((g) => g.key == goalKey) ?? false)) {
          throw const _ExpiredExercise();
        }
        trainingAnalytics?.result(
          config.course,
          goalKey,
          correct: state.correct,
          hints:
              state.hint ||
                  (refreshed.day?.goals
                          .where((g) => g.key == goalKey)
                          .firstOrNull
                          ?.hintUsed ??
                      false)
              ? 1
              : 0,
        );
        final completed = CompleteTrainingGoal(_attemptNow).exercise(
          refreshed,
          resources,
          goalKey,
          correct: state.correct,
          exerciseError: state.errorSnapshot,
          elapsedMs: elapsed.inMilliseconds.clamp(0, 1 << 53),
          hint:
              state.hint ||
              (refreshed.day?.goals
                      .where((g) => g.key == goalKey)
                      .firstOrNull
                      ?.hintUsed ??
                  false),
        );
        return trainingAnalytics?.attach(completed) ?? completed;
      });
      if (!(saved.day?.goals.any((g) => g.key == goalKey && g.done) ?? false)) {
        throw const _ExpiredExercise();
      }
      final cycle = saved.cycles[state.goal!.ref];
      final recorded = cycle?.days
          .where(
            (d) =>
                d.exerciseId == state.exercise!.id && d.date == saved.day!.date,
          )
          .lastOrNull;
      if (recorded == null) throw const _ExpiredExercise();
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: TrainingExercisePhase.result,
          cycle: cycle,
          correct: recorded.correct,
          hint: recorded.hint,
        ),
      );
    } on _ExpiredExercise {
      if (!isClosed) {
        emit(state.copyWith(phase: TrainingExercisePhase.expired));
      }
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(error: true));
      _saveRetry?.cancel();
      _saveRetry = Timer(const Duration(seconds: 1), () {
        if (!isClosed) unawaited(save());
      });
    }
  }

  /// Returns true only when navigation may leave the exercise.
  bool next() {
    if (state.phase != TrainingExercisePhase.result) return false;
    if (historicalPractice) return true;
    final cycle = state.cycle!;
    final finished = state.reinforcement
        ? cycle.phase != ThemePhase.reinforce
        : cycle.cycleDays.length == 7;
    if (finished) {
      final reinforcement = state.reinforcement;
      awaitCycleEnd(cycle, reinforcement);
      emit(state.copyWith(phase: TrainingExercisePhase.end));
      return false;
    }
    return true;
  }

  void awaitCycleEnd(ThemeCycle cycle, bool reinforcement) {
    _log(
      AnalyticsEvents.treinoCicloFim(
        curso: config.course.name,
        aulaId: cycle.lessonId,
        fase: reinforcement ? 'reforco' : 'ciclo',
        nota: reinforcement ? cycle.reinforceScore : cycle.score,
        resultado: switch (cycle.phase) {
          ThemePhase.firm => 'segue',
          ThemePhase.reinforce => 'reforco',
          _ => 'refazer',
        },
        exerciciosMock: cycle.days.any((d) => d.mock),
      ),
    );
  }

  Future<bool> reinforceFirst() async {
    if (state.phase != TrainingExercisePhase.end ||
        state.cycle?.phase != ThemePhase.redo ||
        state.reinforcement) {
      return false;
    }
    try {
      var accepted = false;
      await repository.transact(config.course, (current) async {
        final resources = await repository.resources(config.course);
        final cycle = current.cycles[state.goal!.ref];
        if (cycle == null ||
            cycle.phase != ThemePhase.redo ||
            cycle.startedOn != state.cycle!.startedOn) {
          return current;
        }
        final next = ThemeCycleRules(now).reinforceFirst(
          cycle,
          resources.banks[cycle.lessonId] ?? [],
          current.installSeed,
        );
        if (next.reinforcement.isEmpty) {
          throw StateError('No reinforcement content');
        }
        accepted = true;
        return current.copyWith(
          cycles: {...current.cycles, cycle.lessonId: next},
        );
      });
      if (!accepted && !isClosed) {
        emit(state.copyWith(phase: TrainingExercisePhase.expired));
      }
      return accepted;
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(error: true));
      }
      return false;
    }
  }
}
