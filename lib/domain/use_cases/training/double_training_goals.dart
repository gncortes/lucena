import '../../models/training/day_goals.dart';
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
    final keys = day.goals.map((g) => g.key).toSet();
    final lessons = resources.lessons
        .where((l) => l.visible && !state.completedLessons.containsKey(l.id))
        .take(count == 0 ? 1 : count);
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
