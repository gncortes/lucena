import '../../models/training/day_goals.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'opening_trecho_rules.dart';
import 'theme_cycle_rules.dart';
import 'training_date.dart';

final class CompleteTrainingGoal {
  const CompleteTrainingGoal(this.now);
  final Now now;

  TrainingState exercise(
    TrainingState state,
    TrainingResources resources,
    String goalKey, {
    required bool correct,
    bool hint = false,
    int? elapsedMs,
    TrainingExerciseError? exerciseError,
  }) {
    final goal = _pending(state, goalKey);
    if (goal == null) return state;
    if (goal.kind != GoalKind.exercise && goal.kind != GoalKind.reinforce) {
      throw ArgumentError('Goal is not an exercise');
    }
    final bank = resources.banks[goal.ref] ?? [];
    final exercise = bank.where((e) => e.id == goal.itemId).firstOrNull;
    if (exercise == null) return state;
    final cycle = state.cycles[goal.ref];
    if (cycle == null) return state;
    final updated = ThemeCycleRules(now).record(
      cycle,
      exercise,
      correct: correct,
      hint: hint,
      elapsedMs: elapsedMs,
      bank: bank,
      installSeed: state.installSeed,
    );
    return _done(
      state.copyWith(cycles: {...state.cycles, goal.ref: updated}),
      exerciseError == null ? goal : goal.withExerciseError(exerciseError),
    );
  }

  TrainingState opening(
    TrainingState state,
    TrainingResources resources,
    String lessonId,
    List<bool> firstTry,
  ) {
    final goal = state.day?.goals
        .where((g) => g.kind == GoalKind.openings && !g.done)
        .firstOrNull;
    if (goal == null || _pending(state, goal.key) == null) return state;
    final id = goal.items[lessonId];
    final track = state.openings[lessonId];
    final item = resources.openings[lessonId]
        ?.where((t) => t.id == id)
        .firstOrNull;
    if (track == null ||
        item == null ||
        track.doneTrechos[id] == state.day!.date) {
      return state;
    }
    final updated = OpeningTrechoRules(now).complete(track, item, firstTry);
    final next = state.copyWith(
      openings: {...state.openings, lessonId: updated},
      lastActivityAt: now(),
    );
    final allDone = goal.items.entries.every(
      (e) => next.openings[e.key]?.doneTrechos[e.value] == state.day!.date,
    );
    return allDone ? _done(next, goal) : next;
  }

  TrainingGoal? _pending(TrainingState state, String key) {
    if (state.day?.date != trainingDate(now())) return null;
    return state.day?.goals.where((g) => g.key == key && !g.done).firstOrNull;
  }

  TrainingState _done(TrainingState state, TrainingGoal goal) => state.copyWith(
    lastActivityAt: now(),
    day: state.day!.copyWith(
      goals: [
        for (final g in state.day!.goals)
          if (g.key == goal.key) goal.complete() else g,
      ],
    ),
  );
}
