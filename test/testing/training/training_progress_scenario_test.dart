import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/training_date.dart';

import '../../../testing/training/training_scenario_builder.dart';

void main() {
  test('progress history stays in the past with the native January clock', () {
    final builder = TrainingScenarioBuilder(
      TrainingCourse.pilares,
      date: DateTime.utc(2026, 1, 1, 12),
    );
    final state = builder.progress();
    final today = trainingDate(builder.now());
    expect(state.day!.date, today);
    expect(
      state.cycles.values.every((c) => c.startedOn.compareTo(today) < 0),
      isTrue,
    );
    expect(
      state.completedLessons.values.every((d) => d.compareTo(today) < 0),
      isTrue,
    );
    expect(
      state.openings.values.every(
        (o) => o.startedOn.compareTo(o.lastNewDate!) <= 0,
      ),
      isTrue,
    );
  });
  test(
    'progress scenario covers weighted scores, hint, incomplete and openings',
    () {
      final builder = TrainingScenarioBuilder(TrainingCourse.pilares);
      final state = builder.progress();
      final themes = builder.content.lessons
          .where((l) => state.cycles.containsKey(l.id))
          .take(4)
          .map((l) => state.cycles[l.id]!)
          .toList();
      expect(themes.take(3).map((t) => t.score), [47, 73, 100]);
      expect(themes.last.cycleDays, hasLength(6));
      expect(themes.first.days.any((d) => d.hint && !d.earned), isTrue);
      expect(themes.first.days.any((d) => !d.correct), isTrue);
      expect(state.openings.values.fold(0, (n, t) => n + t.firmMoves), 8);
      expect(state.openings.values.fold(0, (n, t) => n + t.seenMoves), 12);
      for (final goal in state.day!.goals.where(
        (g) => g.kind == GoalKind.exercise || g.kind == GoalKind.reinforce,
      )) {
        final cycle = state.cycles[goal.ref]!;
        expect(cycle.phase, isNot(ThemePhase.firm));
        expect(cycle.seen.contains(goal.itemId), isFalse);
      }
      for (final theme in themes) {
        final bank = builder.content.banks[theme.lessonId]!;
        expect(
          theme.days.every((d) => bank.any((e) => e.id == d.exerciseId)),
          isTrue,
        );
        expect(theme.seen, hasLength(theme.days.length));
      }
    },
  );
}
