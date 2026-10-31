import '../../models/training/training_course.dart';
import '../../models/training/training_state.dart';

/// One visible opening card is one goal, even when persistence groups the
/// repertoire in a single operation. A partial completion updates the count.
({int total, int remaining}) trainingGoalCounts(TrainingState state) {
  final day = state.day;
  if (day == null) return (total: 0, remaining: 0);
  var total = 0, remaining = 0;
  for (final goal in day.goals) {
    if (goal.kind == GoalKind.openings && goal.items.isNotEmpty) {
      total += goal.items.length;
      if (!goal.done) {
        remaining += goal.items.entries
            .where(
              (item) =>
                  state.openings[item.key]?.doneTrechos[item.value] != day.date,
            )
            .length;
      }
    } else {
      total++;
      if (!goal.done) remaining++;
    }
  }
  return (total: total, remaining: remaining);
}
