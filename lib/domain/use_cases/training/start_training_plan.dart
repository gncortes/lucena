import '../../models/training/day_goals.dart';
import '../../models/training/opening_track.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_plan.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'build_day_goals.dart';
import 'training_date.dart';

/// Prior completions keep their real dates; reviews start after the first plan.
final class StartTrainingPlan {
  const StartTrainingPlan(this.now, this.config);
  final Now now;
  final TrainingCourseConfig config;

  TrainingState call(
    TrainingState current,
    TrainingResources resources,
    TrainingPlan plan,
  ) {
    final changed = current.copyWith(plan: plan, onboardingDone: true);
    if (current.onboardingDone) return changed;
    final date = trainingDate(now());
    final prepared = changed.copyWith(
      cycles: {
        for (final entry in changed.cycles.entries)
          entry.key: entry.value.days.isEmpty
              ? entry.value.copyWith(startedOn: date)
              : entry.value,
      },
      openings: {
        for (final entry in changed.openings.entries)
          entry.key: entry.value.doneTrechos.isEmpty
              ? OpeningTrack(
                  lessonId: entry.value.lessonId,
                  startedOn: date,
                  lastNewDate: entry.value.lastNewDate,
                  doneTrechos: entry.value.doneTrechos,
                  firstTry: entry.value.firstTry,
                  pendingMistakes: entry.value.pendingMistakes,
                )
              : entry.value,
      },
    );
    final started = BuildDayGoals(now, config)(prepared, resources);
    final day = started.day!;
    // School reviews are normally available on the completion day. Only these
    // pre-plan reviews wait until tomorrow; later lessons keep their own rule.
    bool defer(TrainingGoal goal) =>
        !goal.done &&
        goal.kind != GoalKind.lesson &&
        goal.kind != GoalKind.extraLesson;
    final deferred = {
      for (final goal in [...started.deferredGoals, ...day.goals.where(defer)])
        goal.key: goal,
    };
    return started.copyWith(
      day: day.copyWith(goals: day.goals.where((goal) => !defer(goal))),
      deferredGoals: deferred.values,
    );
  }
}
