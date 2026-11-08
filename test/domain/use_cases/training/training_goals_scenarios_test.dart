import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';

import '../../../../testing/training/training_scenario_builder.dart';

void main() {
  final source = TrainingScenarioBuilder(TrainingCourse.pilares).content;
  final ids = {for (final (i, l) in source.lessons.indexed) l.id: 'index.$i'};
  final content = TrainingResources(
    lessons: [
      for (final l in source.lessons)
        TrainingLesson(
          id: ids[l.id]!,
          kind: l.kind,
          title: l.title,
          summary: l.summary,
          partId: l.partId,
          partTitle: l.partTitle,
          groupId: l.groupId,
          group: l.group,
        ),
    ],
    banks: {for (final e in source.banks.entries) ids[e.key]!: e.value},
    openings: {for (final e in source.openings.entries) ids[e.key]!: e.value},
  );
  TrainingScenarioBuilder builder() =>
      TrainingScenarioBuilder(TrainingCourse.pilares, resources: content);
  final samples = [
    'first',
    'second',
    'middle',
    'goalDone',
    'extraLesson',
    'nextDay',
    'doneExtra',
    'dayOff',
    'doubled',
    'large',
    'scrolled',
    'done',
  ];
  for (final sample in samples) {
    test(
      'shared goals scenario $sample uses injected index IDs and survives JSON',
      () {
        final scenario = builder();
        final state = scenario.goalsScenario(sample);
        final known = ids.values.toSet();
        for (final goal in state.day!.goals) {
          if (goal.kind == GoalKind.openings) {
            expect(known.containsAll(goal.items.keys), isTrue);
          } else {
            expect(known, contains(goal.ref));
          }
        }
        expect(state.day!.date, scenario.date);
        expect(TrainingState.fromJson(state.toJson()).toJson(), state.toJson());
        final again = builder();
        expect(again.goalsScenario(sample).toJson(), state.toJson());
      },
    );
  }
  test(
    'middle, goalDone and extraLesson represent their actual completion steps',
    () {
      final middle = builder().goalsScenario('middle');
      expect(middle.day!.goals.length, 5);
      expect(middle.day!.remaining, 3);
      expect(
        middle.day!.goals
            .where((g) => g.kind == GoalKind.exercise && g.done)
            .length,
        1,
      );
      expect(
        middle.day!.goals.where((g) => g.kind == GoalKind.reinforce),
        isEmpty,
      );
      final completed = builder().goalsScenario('goalDone');
      expect(completed.day!.goals.length, 5);
      expect(completed.day!.remaining, 2);
      expect(
        completed.day!.goals
            .where((g) => g.kind == GoalKind.exercise && g.done)
            .length,
        2,
      );
      final extra = builder().goalsScenario('extraLesson');
      expect(extra.day!.goals.length, 6);
      expect(extra.day!.remaining, 3);
      expect(
        extra.day!.goals
            .where((g) => g.kind == GoalKind.extraLesson && g.done)
            .length,
        1,
      );
    },
  );
  test('nextDay follows extraLesson with the shared advanced clock', () {
    final scenario = builder();
    final before = scenario.now();
    final state = scenario.goalsScenario('nextDay');
    expect(scenario.now(), before.add(const Duration(days: 1)));
    expect(state.day!.remaining, state.day!.goals.length);
    final extra = builder().goalsScenario('extraLesson');
    expect(
      state.completedLessons.keys,
      containsAll(extra.completedLessons.keys),
    );
  });
  test(
    'doneExtra, doubled, scrolled and invalid sample retain their contracts',
    () {
      final extra = builder().goalsScenario('doneExtra');
      expect(extra.day!.allDone, isTrue);
      expect(
        extra.day!.goals.where((g) => g.kind == GoalKind.extraLesson).length,
        1,
      );
      expect(builder().goalsScenario('doubled').day!.doubled, isTrue);
      expect(
        builder().goalsScenario('scrolled').toJson(),
        builder().goalsScenario('large').toJson(),
      );
      expect(() => builder().goalsScenario('unknown'), throwsArgumentError);
    },
  );
}
