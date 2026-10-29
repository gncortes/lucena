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
  });
  final TrainingExercisePhase phase;
  final TrainingExercise? exercise;
  final TrainingGoal? goal;
  final ThemeCycle? cycle;
  final String? fen, lastMove;
  final int cursor;
  final bool hint, correct, reinforcement, error;

  TrainingExerciseState copyWith({
    TrainingExercisePhase? phase,
    ThemeCycle? cycle,
    String? fen,
    String? lastMove,
    int? cursor,
    bool? hint,
    bool? correct,
    bool error = false,
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
  );
}

final class TrainingExerciseCubit extends Cubit<TrainingExerciseState> {
  TrainingExerciseCubit({
    required this.repository,
    required this.config,
    required this.now,
    required this.goalKey,
  }) : super(const TrainingExerciseState());
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final String goalKey;
  DateTime? _started;
  Duration? _finished;
  Duration get elapsed =>
      _finished ??
      (_started == null ? Duration.zero : now().difference(_started!));

  Future<void> load() async {
    try {
      final resources = await repository.resources(config.course);
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
      final result = goal.done
          ? cycle.days
                .where(
                  (d) =>
                      d.exerciseId == exercise.id && d.date == saved.day!.date,
                )
                .lastOrNull
          : null;
      _started = now();
      _finished = goal.done ? Duration.zero : null;
      emit(
        TrainingExerciseState(
          phase: goal.done
              ? TrainingExercisePhase.result
              : TrainingExercisePhase.playing,
          exercise: exercise,
          goal: goal,
          cycle: cycle,
          fen: exercise.fen,
          lastMove: exercise.lastMove,
          hint: result?.hint ?? goal.hintUsed,
          correct: result?.correct ?? false,
          reinforcement: goal.kind == GoalKind.reinforce,
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
    emit(state.copyWith(phase: TrainingExercisePhase.hintSaving));
    try {
      final saved = await repository.transact(config.course, (current) async {
        final resources = await repository.resources(config.course);
        final refreshed = BuildDayGoals(now, config)(current, resources);
        final goal = refreshed.day?.goals
            .where((g) => g.key == goalKey && !g.done)
            .firstOrNull;
        if (goal == null || refreshed.day?.date != trainingDate(now())) {
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
        return changed;
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
    }
  }

  Future<void> play(String uci) async {
    if (state.phase != TrainingExercisePhase.playing) return;
    final step = PlayTrainingExercise(state.exercise!)
        .play(state.fen!, state.cursor, uci);
    emit(
      state.copyWith(
        fen: step.fen,
        cursor: step.cursor,
        lastMove: step.lastMove,
        correct: step.correct,
        phase: step.done
            ? TrainingExercisePhase.saving
            : TrainingExercisePhase.playing,
      ),
    );
    if (step.done) {
      _finished = elapsed;
      await save();
    }
  }

  Future<void> save() async {
    if (state.phase != TrainingExercisePhase.saving) return;
    try {
      final saved = await repository.transact(config.course, (current) async {
        final resources = await repository.resources(config.course);
        final refreshed = BuildDayGoals(now, config)(current, resources);
        if (!(refreshed.day?.goals.any((g) => g.key == goalKey) ?? false)) {
          throw const _ExpiredExercise();
        }
        final completed = CompleteTrainingGoal(now).exercise(
          refreshed,
          resources,
          goalKey,
          correct: state.correct,
          hint:
              state.hint ||
              (refreshed.day?.goals
                      .where((g) => g.key == goalKey)
                      .firstOrNull
                      ?.hintUsed ??
                  false),
        );
        return completed;
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
    }
  }

  /// Returns true only when navigation may leave the exercise.
  bool next() {
    if (state.phase != TrainingExercisePhase.result) return false;
    final cycle = state.cycle!;
    final finished = state.reinforcement
        ? cycle.phase != ThemePhase.reinforce
        : cycle.cycleDays.length == 7;
    if (finished) {
      emit(state.copyWith(phase: TrainingExercisePhase.end));
      return false;
    }
    return true;
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
