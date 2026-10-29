import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';

import '../../../../testing/training/training_scenario_builder.dart';

void main() {
  test(
    'missed 15-minute day retains pending work through days off and restart',
    () {
      final scenario = TrainingScenarioBuilder(
        TrainingCourse.pilares,
        date: DateTime(2026, 10, 23, 12),
      );
      final build = BuildDayGoals(scenario.now, scenario.config);
      final friday = build(
        TrainingState(
          course: scenario.course,
          installSeed: 'weekend',
          onboardingDone: true,
          plan: const TrainingPlan(minutes: 15),
          completedLessons: {'theme1': '2026-10-20'},
          cycles: {
            'theme1': ThemeCycle(
              lessonId: 'theme1',
              startedOn: '2026-10-20',
              level: 2,
            ),
          },
        ),
        scenario.content,
      );
      scenario.now.advance(const Duration(days: 1));
      var weekend = build(friday, scenario.content);
      expect(weekend.day!.studyDay, isFalse);
      expect(weekend.day!.goals, isEmpty);
      expect(
        weekend.deferredGoals.map((g) => g.key),
        friday.day!.goals.map((g) => g.key),
      );
      weekend = TrainingState.fromJson(weekend.toJson());
      scenario.now.advance(const Duration(days: 1));
      weekend = build(weekend, scenario.content);
      expect(weekend.day!.goals, isEmpty);
      scenario.now.advance(const Duration(days: 1));
      final monday = build(weekend, scenario.content);
      expect(
        monday.day!.goals.map((g) => g.key),
        friday.day!.goals.map((g) => g.key),
      );
      expect(monday.deferredGoals, isEmpty);
      expect(monday.cycles['theme1']!.level, 2);
      expect(monday.cycles['theme1']!.days, isEmpty);
      expect(monday.cycles['theme1']!.hadError, isFalse);
    },
  );

  test('states saved before deferred goals default to an empty queue', () {
    final state = TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 'old',
    );
    final legacy = state.toJson()..remove('deferredGoals');
    expect(TrainingState.fromJson(legacy).deferredGoals, isEmpty);
  });
}
