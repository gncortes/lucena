import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/future_training_reminders.dart';
import 'package:lucena/domain/use_cases/training/reminder_text.dart';
import 'package:lucena/domain/use_cases/training/training_goal_counts.dart';
import 'package:lucena/domain/use_cases/training/training_reminder.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/training/training_scenario_builder.dart';

void main() {
  const config = TrainingCourseConfig.pilares;
  final today = DateTime(2026, 10, 26, 12);
  final resources = TrainingResources(
    lessons: [
      const TrainingLesson(
        id: 'next',
        kind: TrainingLessonKind.theme,
        title: 'Next',
      ),
    ],
    openings: {
      'opening': [
        OpeningTrecho(id: 't1', title: 'Line', moves: ['e2e4'], mock: true),
      ],
    },
  );
  TrainingState state({int weekdays = 62, bool opening = false}) =>
      TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'test',
        onboardingDone: true,
        plan: TrainingPlan(minutes: 15, weekdays: weekdays),
        lastLessonDate: '2026-10-26',
        day: DayGoals(
          date: '2026-10-26',
          studyDay: true,
          plan: TrainingPlan(minutes: 15, weekdays: weekdays),
        ),
        openings: opening
            ? {
                'opening': OpeningTrack(
                  lessonId: 'opening',
                  startedOn: '2026-10-26',
                ),
              }
            : {},
      );

  test('15 minute plan skips empty d1 and starts weekly at d2', () {
    final real = state();
    final before = jsonEncode(real.toJson());
    final planned = futureTrainingReminders(real, resources, config, today);
    final tuesday = planned
        .where((p) => p.request.at.weekday == DateTime.tuesday)
        .single;
    expect(tuesday.repeatWeekly, isTrue);
    expect(tuesday.request.at, DateTime(2026, 11, 3, 19));
    expect(tuesday.request.text.key, 'trainingNotifLesson');
    expect(jsonEncode(real.toJson()), before);
  });

  test(
    'future resets partial day counts without mutating the real snapshot',
    () {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final initial = scenario.large();
      final real = initial.copyWith(
        day: initial.day!.copyWith(
          goals: [
            for (var i = 0; i < initial.day!.goals.length; i++)
              if (i == 0 || i == 1)
                initial.day!.goals[i]
              else
                initial.day!.goals[i].complete(),
          ],
        ),
      );
      final before = jsonEncode(real.toJson());
      expect(trainingGoalCounts(real).remaining, 2);
      final planned = futureTrainingReminders(
        real,
        scenario.content,
        config,
        today,
      );
      final tomorrow = planned.singleWhere((p) => p.request.at.day == 27);
      final projection = BuildDayGoals(FakeNow(DateTime(2026, 10, 27)), config)(
        real,
        scenario.content,
      );
      expect(trainingGoalCounts(projection).remaining, greaterThan(2));
      expect(
        tomorrow.request.text.arguments['n'],
        trainingGoalCounts(projection).remaining - 1,
      );
      expect(jsonEncode(real.toJson()), before);
      expect(planned.map((p) => p.request.at).toSet().length, planned.length);
      expect(planned.every((p) => p.request.at.day != today.day), isTrue);
    },
  );

  test('15 minute d1 follow-up differs from d2 lesson plus follow-up', () {
    final real = state(opening: true);
    // Make the real opening visible to the follow-up builder.
    final withOpening = TrainingResources(
      lessons: [
        ...resources.lessons,
        const TrainingLesson(
          id: 'opening',
          kind: TrainingLessonKind.opening,
          title: 'Opening',
        ),
      ],
      openings: resources.openings,
    );
    final planned = futureTrainingReminders(
      real,
      withOpening,
      config,
      today,
    ).where((p) => p.request.at.weekday == DateTime.tuesday).toList();
    expect(planned.length, 2);
    expect(planned[0].repeatWeekly, isFalse);
    expect(planned[0].request.text.key, 'trainingNotifGoals');
    expect(planned[0].request.text.arguments, {'n': 1});
    expect(planned[1].repeatWeekly, isTrue);
    expect(planned[1].request.text.key, 'trainingNotifLesson');
    expect(planned[1].request.text.arguments, {'aula': 'next', 'n': 1});
  });

  test(
    'd2 copy remains stable at +21, +28 and +90 without simulated progress',
    () {
      final real = state(weekdays: 127);
      final before = jsonEncode(real.toJson());
      for (final offset in [8, 21, 28, 90]) {
        final day = DateTime(today.year, today.month, today.day + offset);
        final projection = BuildDayGoals(FakeNow(day), config)(real, resources);
        final text = reminderText(
          projection.day!,
          remaining: trainingGoalCounts(projection).remaining,
        )!;
        expect(text.key, 'trainingNotifLesson');
        expect(text.arguments, {'aula': 'next', 'n': 0});
      }
      expect(jsonEncode(real.toJson()), before);
    },
  );

  test('one weekday, midnight, no day off and disabled plan', () {
    final real = state(weekdays: 1 << DateTime.monday).copyWith(
      plan: const TrainingPlan(minutes: 15, weekdays: 2, reminderHour: 0),
    );
    final planned = futureTrainingReminders(real, resources, config, today);
    expect(planned.length, 1);
    expect(planned.single.request.at, DateTime(2026, 11, 9));
    expect(planned.single.repeatWeekly, isTrue);
    for (final disabled in [
      real.copyWith(plan: real.plan.copyWith(reminderOn: false)),
      real.copyWith(plan: real.plan.copyWith(weekdays: 0)),
      real.copyWith(onboardingDone: false),
    ]) {
      expect(
        futureTrainingReminders(disabled, resources, config, today),
        isEmpty,
      );
    }
  });

  test(
    'partial today, all done, off day and past hour retain future goals',
    () {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      for (final real in [
        scenario.large(),
        scenario.allDone(),
        scenario
            .large(dayOff: true)
            .copyWith(plan: const TrainingPlan(weekdays: 60)),
      ]) {
        final before = jsonEncode(real.toJson());
        final planned = futureTrainingReminders(
          real,
          scenario.content,
          config,
          today,
        );
        expect(planned.where((p) => p.repeatWeekly), isNotEmpty);
        expect(planned.every((p) => p.request.at.isAfter(today)), isTrue);
        expect(jsonEncode(real.toJson()), before);
        final late = FakeNow(DateTime(2026, 10, 26, 23));
        expect(trainingReminder(real, late), isNull);
        expect(
          futureTrainingReminders(
            real,
            scenario.content,
            config,
            late(),
          ).length,
          planned.length,
        );
      }
    },
  );
}
