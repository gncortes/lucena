import '../../models/training/day_goals.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_state.dart';

/// Tempo estimado das metas, para a meta do dia acompanhar o plano de estudo
/// (minutos por dia). Lição vale [TrainingCourseConfig.lessonMinutes]; o resto
/// vem dos valores fixos do config.
final class GoalMinutes {
  const GoalMinutes(this.config);
  final TrainingCourseConfig config;

  int ofGoal(TrainingGoal goal) => switch (goal.kind) {
    GoalKind.lesson ||
    GoalKind.extraLesson ||
    GoalKind.redo => config.lessonMinutes,
    GoalKind.exercise || GoalKind.reinforce => config.exerciseMinutes,
    GoalKind.openings =>
      (goal.items.isEmpty ? 1 : goal.items.length) * config.openingMinutes,
    GoalKind.stars || GoalKind.bot || GoalKind.speedrun => config.lessonMinutes,
  };

  int ofGoals(Iterable<TrainingGoal> goals) =>
      goals.fold(0, (sum, goal) => sum + ofGoal(goal));

  /// Minutos que "Dobrar a meta" soma: só o que entra de novo no dia.
  int addedByDoubling(TrainingState before, TrainingState doubled) {
    final old = {...?before.day?.goals.map((g) => g.key)};
    return ofGoals([...?doubled.day?.goals].where((g) => !old.contains(g.key)));
  }
}
