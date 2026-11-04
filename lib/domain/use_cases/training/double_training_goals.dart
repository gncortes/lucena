import '../../models/training/day_goals.dart';
import '../../models/training/training_content.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'build_day_goals.dart';
import 'training_goal_order.dart';

final class DoubleTrainingGoals {
  const DoubleTrainingGoals(this.now, this.config);
  final Now now;
  final TrainingCourseConfig config;

  TrainingState call(TrainingState state, TrainingResources resources) {
    final current = BuildDayGoals(now, config)(state, resources);
    final day = current.day!;
    if (!day.allDone ||
        day.doubled ||
        (config.doubleRequiresExtraLesson &&
            !day.goals.any((g) => g.kind == GoalKind.extraLesson))) {
      return current;
    }
    final count = config.option(day.plan.minutes).lessonsPerDay;
    final keys = [
      ...day.goals,
      ...current.deferredGoals,
    ].map((g) => g.key).toSet();
    // Mesma regra do dia normal: segue a ordem do curso e para na primeira
    // lição ainda não publicada, sem deixar uma posterior passar na frente.
    final lessons = <TrainingLesson>[];
    final wanted = count == 0 ? 1 : count;
    for (final lesson in resources.lessons.where(
      (l) => l.visible || !l.published,
    )) {
      if (!lesson.inCourseOrder) continue;
      if (!lesson.published || lessons.length >= wanted) break;
      if (state.completedLessons.containsKey(lesson.id)) continue;
      lessons.add(lesson);
    }
    final followUps = config.followUps
        .build(current, resources, now)
        .where(
          (g) =>
              g.kind != GoalKind.openings &&
              g.kind != GoalKind.reinforce &&
              g.kind != GoalKind.redo,
        )
        .where((g) => !keys.contains(g.key));
    final added = [
      for (final lesson in lessons)
        TrainingGoal(kind: GoalKind.lesson, ref: lesson.id),
      ...followUps,
    ];
    return current.copyWith(
      day: day.copyWith(
        doubled: true,
        goals: orderTrainingGoals([...day.goals, ...added], config.sections),
      ),
    );
  }
}
