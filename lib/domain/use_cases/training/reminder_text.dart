import '../../models/training/day_goals.dart';
import '../../models/training/training_course.dart';

final class TrainingReminderText {
  TrainingReminderText(this.key, Map<String, Object> arguments)
    : arguments = Map.unmodifiable(arguments);
  final String key;
  final Map<String, Object> arguments;
}

TrainingReminderText? reminderText(DayGoals day, {int? remaining}) {
  if (!day.studyDay || day.allDone) return null;
  final lesson = day.goals
      .where((g) => g.kind == GoalKind.lesson && !g.done)
      .firstOrNull;
  final count = remaining ?? day.remaining;
  return lesson == null
      ? TrainingReminderText('trainingNotifGoals', {'n': count})
      : TrainingReminderText('trainingNotifLesson', {
          'aula': lesson.ref,
          'n': count - 1,
        });
}
