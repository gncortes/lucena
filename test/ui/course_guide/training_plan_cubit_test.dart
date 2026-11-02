import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/ui/course_guide/view_models/training_plan_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  late TrainingScenarioBuilder scenario;
  late FakeTrainingRepository repository;
  late FakePushRepository push;
  late TrainingPlanCubit cubit;
  setUp(() {
    scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: scenario.content},
    );
    push = FakePushRepository(allowed: true);
    cubit = TrainingPlanCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: scenario.now,
      push: push,
    );
  });
  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test(
    'defaults load without freezing a day or requesting system permission',
    () async {
      await cubit.load();
      expect(repository.writes, 0);
      expect((await repository.load(TrainingCourse.pilares)).day, isNull);
      expect(cubit.state.draft.toJson(), const TrainingPlan().toJson());
      expect(push.permissionRequests, 0);
    },
  );

  for (final minutes in [15, 240]) {
    test(
      'onboarding $minutes freezes the selected plan only after save',
      () async {
        await cubit.load();
        cubit.selectMinutes(minutes);
        expect((await repository.load(TrainingCourse.pilares)).day, isNull);
        expect(await cubit.save(), isTrue);
        final saved = await repository.load(TrainingCourse.pilares);
        expect(saved.onboardingDone, isTrue);
        expect(saved.day!.plan.minutes, minutes);
        expect(saved.day!.goals.length, minutes == 240 ? 2 : 1);
        if (minutes == 15) {
          scenario.now.value = DateTime(2026, 10, 27, 12);
          final tomorrow =
              BuildDayGoals(scenario.now, TrainingCourseConfig.pilares)(
                saved.copyWith(
                  day: saved.day!.copyWith(
                    goals: saved.day!.goals.map((goal) => goal.complete()),
                  ),
                  completedLessons: {
                    saved.day!.goals.single.ref: saved.day!.date,
                  },
                ),
                scenario.content,
              );
          expect(tomorrow.day!.goals, isEmpty);
          scenario.now.value = DateTime(2026, 10, 28, 12);
          expect(
            BuildDayGoals(scenario.now, TrainingCourseConfig.pilares)(
              tomorrow,
              scenario.content,
            ).day!.goals,
            hasLength(1),
          );
        }
      },
    );
  }

  test(
    'editing changes tomorrow and preserves the exact frozen snapshot today',
    () async {
      final current = scenario.large();
      await repository.update(
        TrainingCourse.pilares,
        (before) => TrainingState.fromJson({
          ...current.toJson(),
          'installSeed': before.installSeed,
        }),
      );
      await cubit.load();
      cubit.selectMinutes(240);
      expect(await cubit.save(), isTrue);
      final saved = await repository.load(TrainingCourse.pilares);
      expect(saved.day!.toJson(), current.day!.toJson());
      expect(saved.plan.minutes, 240);
      scenario.now.value = DateTime(2026, 10, 27, 12);
      final tomorrow = BuildDayGoals(
        scenario.now,
        TrainingCourseConfig.pilares,
      )(saved, scenario.content);
      expect(tomorrow.day!.plan.minutes, 240);
    },
  );

  test('durable write blocks mutations and duplicate save; callback sees persisted state', () async {
    await cubit.close();
    var callback = false;
    cubit = TrainingPlanCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: scenario.now,
      push: push,
      afterSave: (saved) async {
        expect(
          (await repository.load(TrainingCourse.pilares)).toJson(),
          saved.toJson(),
        );
        callback = true;
      },
    );
    await cubit.load();
    final gate = Completer<void>();
    repository.beforeSave = gate.future;
    final saving = cubit.save();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.saving, isTrue);
    expect(callback, isFalse);
    expect(await cubit.save(), isFalse);
    cubit.selectMinutes(240);
    cubit.toggleWeekday(0);
    cubit.setTime(10, 30);
    expect(cubit.state.draft.toJson(), const TrainingPlan().toJson());
    gate.complete();
    expect(await saving, isTrue);
    expect(callback, isTrue);
    expect(repository.writes, 1);
  });

  test(
    'write error keeps draft and supports retry without callback on failure',
    () async {
      await cubit.load();
      cubit.selectMinutes(15);
      cubit.toggleWeekday(0);
      cubit.setTime(23, 45);
      repository.writeError = StateError('disk unavailable');
      expect(await cubit.save(), isFalse);
      expect(cubit.state.failed, isTrue);
      expect(cubit.state.saving, isFalse);
      expect(cubit.state.draft.minutes, 15);
      expect(cubit.state.draft.weekdays, 63);
      expect(cubit.state.draft.reminderHour, 23);
      repository.writeError = null;
      expect(await cubit.save(), isTrue);
    },
  );

  test(
    'permission is checked before consent, and requested only after allow',
    () async {
      push.allowed = false;
      await cubit.load();
      expect(await cubit.save(), isFalse);
      expect(await cubit.enableReminder(), isFalse);
      expect(push.permissionRequests, 0);
      cubit.disableReminder();
      expect(cubit.state.draft.reminderOn, isFalse);
      push.granted = true;
      await cubit.allowPermission();
      expect(push.permissionRequests, 1);
      expect(cubit.state.draft.reminderOn, isTrue);
      expect(await cubit.save(), isTrue);
    },
  );

  test(
    'denied permission exposes settings and resumes after external grant',
    () async {
      push.allowed = false;
      await cubit.load();
      await cubit.allowPermission();
      expect(cubit.state.denied, isTrue);
      expect(cubit.state.draft.reminderOn, isFalse);
      await cubit.openSettings();
      expect(push.settingsOpened, 1);
      push.allowed = true;
      await cubit.refreshPermission();
      expect(cubit.state.denied, isFalse);
      expect(cubit.state.draft.reminderOn, isTrue);
    },
  );

  test(
    'an existing blocked reminder loads denied without a system prompt',
    () async {
      await repository.update(
        TrainingCourse.pilares,
        (before) => before.copyWith(onboardingDone: true),
      );
      push.allowed = false;
      await cubit.load();
      expect(cubit.state.denied, isTrue);
      expect(cubit.state.draft.reminderOn, isFalse);
      expect(push.permissionRequests, 0);
      expect(await cubit.save(), isTrue);
    },
  );
}
