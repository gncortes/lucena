import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/training/training_scenario_builder.dart';

class _SavedProgress extends EndgameProgressRepository {
  _SavedProgress(this.value);
  EndgameProgress value;
  @override
  Future<EndgameProgress> load() async => value;
  @override
  Future<void> save(EndgameProgress progress) async => value = progress;
}

void main() {
  test('retomada prioriza uma lição publicada do próprio curso', () async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = scenario.repository(
      scenario.large().copyWith(completedLessons: {}),
    );
    final lesson = scenario.content.lessons.lastWhere(
      (l) => l.visible && l.published,
    );
    final progress = _SavedProgress(
      EndgameProgress(
        ongoing: LessonCheckpoint(
          lessonId: lesson.id,
          step: 1,
          scriptExample: 0,
          open: false,
        ),
      ),
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: scenario.now,
      testProgress: progress,
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    expect(cubit.state.resumedLesson?.id, lesson.id);
    expect(cubit.state.nextLesson?.id, lesson.id);
    progress.value = const EndgameProgress(
      ongoing: LessonCheckpoint(
        lessonId: 'outro.curso',
        step: 1,
        scriptExample: 0,
      ),
    );
    await cubit.load();
    expect(cubit.state.resumedLesson, isNull);
  });
  test(
    'Progresso usa apenas respostas do último teste de nível concluído',
    () async {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final repository = scenario.repository(scenario.large());
      final placement = FakePlacementRepository();
      final cubit = CourseGuideCubit(
        repository: repository,
        config: TrainingCourseConfig.pilares,
        now: scenario.now,
        placement: placement,
      );
      addTearDown(cubit.close);
      addTearDown(repository.dispose);
      await cubit.load();
      expect(cubit.state.levelTestProgress, isNull);
      placement.saveResultValue = PlacementResult(
        theta: 1500,
        low: 1400,
        high: 1600,
        nodes: const {},
        takenAt: scenario.now(),
        answers: [
          for (var i = 0; i < 20; i++)
            PlacementAnswer(
              itemId: 'item$i',
              node: 'node',
              difficulty: 1500,
              outcome: i < 13
                  ? PlacementOutcome.correct
                  : PlacementOutcome.wrong,
              phase: PlacementPhase.of(i),
            ),
        ],
      );
      await cubit.load();
      expect(cubit.state.levelTestProgress, (
        score: 13,
        maxScore: 20,
        solved: 20,
        total: 20,
      ));
      await cubit.selectTab(CourseGuideTab.progress);
      expect(cubit.state.levelTestProgress?.score, 13);
    },
  );
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

  test('plano editado não troca retrato de hoje; nova leitura amanhã usa novo plano', () async {
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
    final day = cubit.state.training!.day!.toJson();
    await cubit.savePlan(const TrainingPlan(minutes: 240, weekdays: 127));
    expect(cubit.state.training!.day!.toJson(), day);
    scenario.now.advance(const Duration(days: 1));
    await cubit.load();
    expect(cubit.state.training!.day!.plan.minutes, 240);
  });

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
