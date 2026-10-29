import '../../models/training/day_goals.dart';
import '../../models/training/training_content.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'build_day_goals.dart';
import 'training_date.dart';
import 'training_goal_order.dart';

/// Called for observed completions from LearningRepository, never for a visit.
final class CompleteTrainingLesson {
  const CompleteTrainingLesson(this.now, this.config);
  final Now now;
  final TrainingCourseConfig config;

  TrainingState call(
    TrainingState state,
    TrainingResources resources,
    TrainingLesson lesson, {
    bool redo = false,
  }) {
    if (!lesson.visible ||
        state.completedLessons.containsKey(lesson.id) && !redo) {
      return state;
    }
    final today = BuildDayGoals(now, config)(state, resources);
    final date = trainingDate(now());
    var next = config.followUps.lessonCompleted(today, lesson, date);
    next = next.copyWith(
      completedLessons: {...next.completedLessons, lesson.id: date},
      lastActivityAt: now(),
    );
    final day = next.day!;
    if (!day.studyDay) {
      return next.copyWith(offDayCredits: {...next.offDayCredits, lesson.id});
    }
    final matches = day.goals.any(
      (g) =>
          g.ref == lesson.id &&
          (g.kind == GoalKind.lesson || g.kind == GoalKind.redo),
    );
    var goals = [
      for (final g in day.goals)
        if (g.ref == lesson.id &&
            (g.kind == GoalKind.lesson || g.kind == GoalKind.redo))
          g.complete()
        else
          g,
    ];
    if (!matches) {
      final insertion = goals.indexWhere(
        (g) => g.kind != GoalKind.lesson && g.kind != GoalKind.extraLesson,
      );
      goals.insert(
        insertion < 0 ? goals.length : insertion,
        TrainingGoal(kind: GoalKind.extraLesson, ref: lesson.id, done: true),
      );
    }
    // Course strategies decide which follow-ups can begin on the completion day.
    final keys = goals.map((g) => g.key).toSet();
    goals = [
      ...goals,
      ...config.followUps
          .build(next, resources, now)
          .where((g) => g.ref == lesson.id && !keys.contains(g.key)),
    ];
    goals = orderTrainingGoals(goals, config.sections);
    return next.copyWith(day: day.copyWith(goals: goals));
  }
}
