import '../../models/training/theme_cycle.dart';
import '../../models/training/training_content.dart';
import '../../models/training/training_course.dart';
import '../now.dart';
import 'exercise_picker.dart';
import 'training_date.dart';

final class ThemeCycleRules {
  const ThemeCycleRules(this.now);
  final Now now;
  static ThemePhase result(int score) => score >= 70
      ? ThemePhase.firm
      : score >= 30
      ? ThemePhase.reinforce
      : ThemePhase.redo;

  ThemeCycle record(
    ThemeCycle cycle,
    TrainingExercise exercise, {
    required bool correct,
    bool hint = false,
    Iterable<TrainingExercise> bank = const [],
    String installSeed = '',
  }) {
    if (cycle.phase != ThemePhase.cycle &&
        cycle.phase != ThemePhase.reinforce) {
      throw StateError('Theme is not accepting attempts');
    }
    if (cycle.phase == ThemePhase.cycle && exercise.stars != cycle.level) {
      throw StateError('Exercise difficulty differs from frozen cycle');
    }
    final earned = correct && !hint;
    final days = [
      ...cycle.days,
      ThemeDay(
        date: trainingDate(now()),
        exerciseId: exercise.id,
        stars: exercise.stars,
        correct: correct,
        hint: hint,
        mock: exercise.mock,
        phase: cycle.phase,
      ),
    ];
    if (cycle.phase == ThemePhase.reinforce) {
      var next = cycle.copyWith(days: days);
      if (next.reinforceDays.length >= cycle.reinforcement.length) {
        next = next.copyWith(
          phase: next.reinforceScore >= 70 ? ThemePhase.firm : ThemePhase.redo,
        );
      }
      return next;
    }
    final streak = earned ? cycle.streak + 1 : 0;
    final hadError = cycle.hadError || !earned;
    final rises = earned && (hadError || streak >= 2);
    final level = earned
        ? (rises ? minLevel(cycle.level + 1) : cycle.level)
        : minLevel(cycle.level - 1);
    var next = cycle.copyWith(
      days: days,
      level: level,
      hadError: hadError,
      streak: rises ? 0 : streak,
    );
    if (next.cycleDays.length == 7) {
      final phase = result(next.score);
      final remaining = const ExercisePicker().reinforcement(
        bank,
        next,
        installSeed,
      );
      next = next.copyWith(phase: phase, reinforcement: remaining);
      // Missing bank content is never interpreted as a successful reinforcement.
    }
    return next;
  }

  static int minLevel(int level) => level.clamp(1, 3);
  ThemeCycle redo(ThemeCycle cycle) =>
      ThemeCycle(lessonId: cycle.lessonId, startedOn: trainingDate(now()));
  ThemeCycle reinforceFirst(
    ThemeCycle cycle,
    Iterable<TrainingExercise> bank,
    String seed,
  ) => cycle.copyWith(
    phase: ThemePhase.reinforce,
    reinforcement: const ExercisePicker().reinforcement(bank, cycle, seed),
  );
}
