import '../domain/models/training/day_goals.dart';
import '../domain/models/training/training_content.dart';
import '../domain/models/training/training_course.dart';
import 'routes.dart';

String trainingLessonDestination(
  TrainingLesson lesson, {
  required String origin,
}) => switch (lesson.kind) {
  TrainingLessonKind.test => Routes.endgameExercisesIntro(lesson.id),
  TrainingLessonKind.school => Routes.lessonScript(lesson.id, origin: origin),
  _ => Routes.trainingLesson(lesson.id, origin: origin),
};

/// Destinations already owned by Escola, Jornada and speedrun.
String? trainingChallengeDestination(TrainingGoal goal, {String? course}) {
  final path = switch (goal.kind) {
    GoalKind.stars => Routes.starChallenge(
      goal.ref.split('.').last,
      goal.itemId!,
    ),
    GoalKind.bot => Routes.journeyChallenge(goal.items['rung']!, goal.itemId!),
    GoalKind.speedrun => Routes.speedrun(goal.itemId!),
    _ => null,
  };
  return path == null || course == null
      ? path
      : Uri.parse(path)
            .replace(queryParameters: {'treino': course, 'meta': goal.key})
            .toString();
}
