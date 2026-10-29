import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  test(
    'conclusão observada durante gravação de aba é enfileirada e persistida',
    () async {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final repository = scenario.repository(scenario.large());
      final cubit = CourseGuideCubit(
        repository: repository,
        config: scenario.config,
        now: scenario.now,
      );
      addTearDown(cubit.close);
      addTearDown(repository.dispose);
      await cubit.load();
      final gate = Completer<void>();
      repository.beforeSave = gate.future;
      final tab = cubit.selectTab(CourseGuideTab.catalog);
      final observed = cubit.observeLesson(
        scenario.content.lessons.firstWhere((l) => l.id == 'theme9'),
      );
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await tab;
      expect(await observed, isTrue);
      final saved = await repository.load(TrainingCourse.pilares);
      expect(saved.tab, CourseGuideTab.catalog);
      expect(saved.completedLessons.containsKey('theme9'), isTrue);
    },
  );

  test(
    'boas-vindas não congela metas antes de escolher o plano inicial',
    () async {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final repository = FakeTrainingRepository(
        content: {TrainingCourse.pilares: scenario.content},
      );
      final cubit = CourseGuideCubit(
        repository: repository,
        config: TrainingCourseConfig.pilares,
        now: scenario.now,
      );
      addTearDown(cubit.close);
      addTearDown(repository.dispose);
      await cubit.load();
      expect(cubit.state.training!.onboardingDone, isFalse);
      expect(cubit.state.training!.day, isNull);
      expect(repository.writes, 0);
      await cubit.start(const TrainingPlan(minutes: 240));
      expect(cubit.state.training!.day!.goals, hasLength(2));
      expect(cubit.state.training!.day!.plan.minutes, 240);
    },
  );

  test(
    'seleção de aba só termina depois de gravar e sobrevive reabrir',
    () async {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final repository = scenario.repository(scenario.large());
      final cubit = CourseGuideCubit(
        repository: repository,
        config: TrainingCourseConfig.pilares,
        now: scenario.now,
      );
      addTearDown(cubit.close);
      addTearDown(repository.dispose);
      await cubit.load();
      final gate = Completer<void>();
      repository.beforeSave = gate.future;
      var finished = false;
      final saving = cubit
          .selectTab(CourseGuideTab.catalog)
          .then((_) => finished = true);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.saving, isTrue);
      expect(finished, isFalse);
      gate.complete();
      await saving;
      expect(cubit.state.training!.tab, CourseGuideTab.catalog);
      final reopened = CourseGuideCubit(
        repository: repository,
        config: TrainingCourseConfig.pilares,
        now: scenario.now,
      );
      addTearDown(reopened.close);
      await reopened.load();
      expect(reopened.state.training!.tab, CourseGuideTab.catalog);
    },
  );

  test(
    'erro de persistência conserva estado visível e permite tentar novamente',
    () async {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final repository = scenario.repository(scenario.large());
      final cubit = CourseGuideCubit(
        repository: repository,
        config: TrainingCourseConfig.pilares,
        now: scenario.now,
      );
      addTearDown(cubit.close);
      addTearDown(repository.dispose);
      await cubit.load();
      repository.writeError = StateError('disk');
      expect(await cubit.selectTab(CourseGuideTab.goals), isFalse);
      expect(cubit.state.failed, isTrue);
      expect(cubit.state.training!.tab, CourseGuideTab.lesson);
      repository.writeError = null;
      expect(await cubit.selectTab(CourseGuideTab.goals), isTrue);
      expect(cubit.state.failed, isFalse);
    },
  );

  test('curso ausente não inventa metas nem perde plano', () async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = FakeTrainingRepository(
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'x',
          onboardingDone: true,
        ),
      },
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: scenario.now,
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    expect(cubit.state.failed, isFalse);
    expect(cubit.state.nextLesson, isNull);
    expect(cubit.state.training!.day!.goals, isEmpty);
  });
}
