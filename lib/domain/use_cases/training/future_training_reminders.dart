import '../../models/training/training_course_config.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'build_day_goals.dart';
import 'reminder_text.dart';
import 'training_goal_counts.dart';
import 'training_reminder.dart';

typedef FutureTrainingReminder = ({
  TrainingReminder request,
  bool repeatWeekly,
});

/// Project from the same real snapshot, without advancing persisted progress.
/// The first week can differ for plans with a lesson every two study days.
/// With current goal rules, the second occurrence is stable without new play.
List<FutureTrainingReminder> futureTrainingReminders(
  TrainingState state,
  TrainingResources resources,
  TrainingCourseConfig config,
  DateTime today,
) {
  if (!state.onboardingDone || !state.plan.reminderOn) return [];
  final result = <FutureTrainingReminder>[];
  for (var offset = 1; offset <= 7; offset++) {
    final first = DateTime(today.year, today.month, today.day + offset);
    if (!state.plan.studiesOn(first)) continue;
    final second = DateTime(first.year, first.month, first.day + 7);
    TrainingReminder? project(DateTime date) {
      final projection = BuildDayGoals(_FixedNow(date), config)(
        state,
        resources,
      );
      final text = reminderText(
        projection.day!,
        remaining: trainingGoalCounts(projection).remaining,
      );
      if (text == null) return null;
      return TrainingReminder(
        DateTime(
          date.year,
          date.month,
          date.day,
          state.plan.reminderHour,
          state.plan.reminderMinute,
        ),
        text,
      );
    }

    final d1 = project(first), d2 = project(second);
    final same =
        d1?.text.key == d2?.text.key &&
        (d1 == null ||
            d2 != null &&
                d1.text.arguments.length == d2.text.arguments.length &&
                d1.text.arguments.entries.every(
                  (entry) => d2.text.arguments[entry.key] == entry.value,
                ));
    if (same) {
      if (d1 != null) result.add((request: d1, repeatWeekly: true));
    } else {
      if (d1 != null) result.add((request: d1, repeatWeekly: false));
      if (d2 != null) result.add((request: d2, repeatWeekly: true));
    }
  }
  return result;
}

class _FixedNow implements Now {
  const _FixedNow(this.value);
  final DateTime value;
  @override
  DateTime call() => value;
}
