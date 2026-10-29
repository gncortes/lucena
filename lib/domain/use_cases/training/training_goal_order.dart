import '../../models/training/day_goals.dart';
import '../../models/training/training_course.dart';

/// Stable section grouping used when same-day completions append new work.
List<TrainingGoal> orderTrainingGoals(
  Iterable<TrainingGoal> goals,
  List<GoalSection> sections,
) {
  GoalSection section(TrainingGoal goal) => switch (goal.kind) {
    GoalKind.lesson || GoalKind.extraLesson => GoalSection.lessons,
    GoalKind.reinforce || GoalKind.redo => GoalSection.reinforce,
    GoalKind.exercise => GoalSection.exercises,
    GoalKind.openings => GoalSection.openings,
    GoalKind.bot || GoalKind.speedrun => GoalSection.bots,
    GoalKind.stars => GoalSection.stars,
  };
  return [
    for (final group in sections) ...goals.where((g) => section(g) == group),
  ];
}
