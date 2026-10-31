import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/learning/learning_repository.dart';
import 'package:lucena/data/repositories/learning/learning_lesson_source.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/repositories/training/training_learning_bridge.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/learning_unit_completion.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_course_training_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/training/mock_exercise_bank.dart';

void main() {
  late FakeNow now;
  late FakeTrainingRepository repository;
  late TrainingLearningBridge bridge;
  const config = TrainingCourseConfig.pilares;
  const topic = TrainingLesson(
    id: 'pilares.c1.topic',
    kind: TrainingLessonKind.theme,
    title: 'Tema',
  );
  const chapterTest = TrainingLesson(
    id: 'pilares.c1',
    kind: TrainingLessonKind.test,
    title: 'Teste',
  );
  final resources = TrainingResources(
    lessons: [topic, chapterTest],
    banks: {topic.id: MockExerciseBank.forLesson(topic.id)},
  );
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = FakeNow(DateTime(2026, 10, 26, 12));
    final state = BuildDayGoals(now, config)(
      TrainingState(
        course: config.course,
        installSeed: 'x',
        onboardingDone: true,
      ),
      resources,
    );
    repository = FakeTrainingRepository(
      states: {config.course: state},
      content: {config.course: resources},
    );
    bridge = TrainingLearningBridge(repository);
  });
  tearDown(() async {
    await repository.dispose();
  });

  test('conclusão real de parte atualiza aula e agenda ciclo para amanhã uma só vez', () async {
    final event = LearningUnitCompletion(
      kind: 'endgame_lesson',
      unitId: 'pilares.c1/topic',
      at: now(),
    );
    await bridge(event);
    await bridge(event);
    final state = await repository.load(config.course);
    expect(state.day!.goals.single.done, isTrue);
    expect(state.cycles[topic.id]!.startedOn, '2026-10-26');
    expect(state.cycles[topic.id]!.days, isEmpty);
    expect(repository.writes, 1);
    now.advance(const Duration(days: 1));
    final next = BuildDayGoals(now, config)(state, resources);
    expect(
      next.day!.goals.any(
        (g) => g.kind == GoalKind.exercise && g.ref == topic.id,
      ),
      isTrue,
    );
  });

  test('teste de capítulo só conclui no treino quando foi aprovado', () async {
    await bridge(
      LearningUnitCompletion(
        kind: 'endgame_chapter',
        unitId: chapterTest.id,
        at: now(),
      ),
    );
    expect(
      (await repository.load(config.course)).completedLessons
          .containsKey(chapterTest.id),
      isFalse,
    );
    await bridge(
      LearningUnitCompletion(
        kind: 'endgame_chapter',
        unitId: chapterTest.id,
        at: now(),
        testPassed: true,
      ),
    );
    expect(
      (await repository.load(config.course)).completedLessons
          .containsKey(chapterTest.id),
      isTrue,
    );
  });

  test(
    'curso não iniciado e tipo desconhecido não ganham progresso inventado',
    () async {
      await bridge(
        LearningUnitCompletion(kind: 'unknown', unitId: topic.id, at: now()),
      );
      expect(repository.writes, 0);
      final unopened = FakeTrainingRepository(
        content: {config.course: resources},
      );
      addTearDown(unopened.dispose);
      await TrainingLearningBridge(unopened)(
        LearningUnitCompletion(
          kind: 'endgame_lesson',
          unitId: 'pilares.c1/topic',
          at: now(),
        ),
      );
      expect(unopened.writes, 0);
    },
  );

  test(
    'refazer aula reinicia somente o tema que estava aguardando refazer',
    () async {
      await repository.update(
        config.course,
        (s) => s.copyWith(
          completedLessons: {topic.id: '2026-10-20'},
          cycles: {
            topic.id: ThemeCycle(
              lessonId: topic.id,
              startedOn: '2026-10-20',
              phase: ThemePhase.redo,
              level: 2,
            ),
          },
        ),
      );
      await bridge(
        LearningUnitCompletion(
          kind: 'endgame_lesson',
          unitId: 'pilares.c1/topic',
          at: now(),
        ),
      );
      final cycle = (await repository.load(config.course)).cycles[topic.id]!;
      expect(cycle.phase, ThemePhase.cycle);
      expect(cycle.level, 1);
      expect(cycle.startedOn, '2026-10-26');
    },
  );

  test(
    'transação reserva a conclusão antes da leitura que cruza meia-noite',
    () async {
      now.value = DateTime(2026, 10, 26, 23, 59);
      final event = LearningUnitCompletion(
        kind: 'endgame_lesson',
        unitId: 'pilares.c1/topic',
        at: now(),
      );
      final gate = Completer<void>();
      repository.beforeResources = gate.future;
      final completion = bridge(event);
      await Future<void>.delayed(Duration.zero);
      now.value = DateTime(2026, 10, 27, 0, 0);
      final nextDay = repository.update(
        config.course,
        (s) => BuildDayGoals(now, config)(s, resources),
      );
      gate.complete();
      await completion;
      await nextDay;
      final state = await repository.load(config.course);
      expect(state.day!.date, '2026-10-27');
      expect(state.completedLessons[topic.id], '2026-10-26');
      expect(
        state.day!.goals.any(
          (g) => g.kind == GoalKind.exercise && g.ref == topic.id,
        ),
        isTrue,
      );
    },
  );

  test('LearningLessonSource aguarda observador local sem criar registro de conta para convidado', () async {
    final entered = Completer<void>(), gate = Completer<void>();
    final observed = <LearningUnitCompletion>[];
    final learning = LearningRepository(
      PreferencesService(),
      now,
      currentUid: () => null,
      versionOf: (_, _) async => 'v1',
      onUnitCompleted: (event) async {
        observed.add(event);
        entered.complete();
        await gate.future;
      },
    );
    final source = LearningLessonSource(
      SchoolLessonSource(
        FakeLessonRepository(),
        FakeSchoolProgressRepository(),
      ),
      learning: learning,
    );
    var finished = false;
    final completing = source
        .complete('mates.queen')
        .then((_) => finished = true);
    await entered.future;
    expect(finished, isFalse);
    expect(observed.single.kind, 'school_lesson');
    gate.complete();
    await completing;
    expect(finished, isTrue);
    expect(await learning.load('account'), isEmpty);
  });

  test(
    'mudança de conta rejeita conclusão de sessão antiga antes do observador',
    () async {
      String? uid = 'a';
      var observed = 0;
      final learning = LearningRepository(
        PreferencesService(),
        now,
        currentUid: () => uid,
        versionOf: (_, _) async => 'v1',
        onUnitCompleted: (_) async {
          observed++;
        },
      );
      final source = LearningLessonSource(
        SchoolLessonSource(
          FakeLessonRepository(),
          FakeSchoolProgressRepository(),
        ),
        learning: learning,
      );
      uid = 'b';
      await source.complete('mates.queen');
      expect(observed, 0);
    },
  );
}
