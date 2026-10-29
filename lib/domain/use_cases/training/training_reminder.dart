import '../../models/training/training_state.dart';
import '../now.dart';
import 'reminder_text.dart';
import 'training_date.dart';

final class TrainingReminder {
  const TrainingReminder(this.at, this.text);
  final DateTime at;
  final TrainingReminderText text;
}

TrainingReminder? trainingReminder(TrainingState state, Now now) {
  final at = now();
  final day = state.day;
  if (!state.onboardingDone ||
      day == null ||
      day.date != trainingDate(at) ||
      !day.plan.reminderOn) {
    return null;
  }
  final text = reminderText(day);
  if (text == null) return null;
  final scheduled = DateTime(
    at.year,
    at.month,
    at.day,
    day.plan.reminderHour,
    day.plan.reminderMinute,
  );
  if (!scheduled.isAfter(at)) return null;
  return TrainingReminder(scheduled, text);
}
