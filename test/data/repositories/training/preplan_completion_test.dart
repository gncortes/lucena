import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/training_learning_bridge.dart';
import 'package:lucena/domain/models/learning_unit_completion.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/start_training_plan.dart';
import 'package:lucena/domain/use_cases/training/double_training_goals.dart';
import 'package:lucena/ui/course_guide/view_models/training_plan_cubit.dart';

import '../../../../testing/fakes/fake_course_training_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_push_repository.dart';
import '../../../../testing/training/mock_exercise_bank.dart';
import '../../../../testing/training/training_scenario_builder.dart';

const theme = TrainingLesson(
  id: 'pilares.c1.topic',
  kind: TrainingLessonKind.theme,
  title: 'Tema',
);
final content = TrainingResources(
  lessons: [theme],
  banks: {theme.id: MockExerciseBank.forLesson(theme.id)},
);

Future<void> savePlan(
  FakeTrainingRepository repository,
  FakeNow now,
  TrainingCourseConfig config,
) async {
  final cubit = TrainingPlanCubit(
    repository: repository,
    config: config,
    now: now,
    push: FakePushRepository(allowed: true),
  );
  try {
    await cubit.load();
    expect(await cubit.save(), isTrue);
  } finally {
    await cubit.close();
  }
}

void main() {
  test('primeiro plano agenda abertura antiga para amanhã; editar não reinicia trilhos', () {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final lesson = scenario.content.lessons.firstWhere(
      (l) => l.kind == TrainingLessonKind.opening,
    );
    final before = TrainingState(
      course: scenario.course,
      installSeed: 'seed',
      completedLessons: {lesson.id: '2026-10-20'},
      openings: {
        lesson.id: OpeningTrack(lessonId: lesson.id, startedOn: '2026-10-20'),
      },
    );
    final start = StartTrainingPlan(scenario.now, scenario.config);
    final started = start(before, scenario.content, const TrainingPlan());
    expect(started.openings[lesson.id]!.startedOn, '2026-10-26');
    expect(started.day!.goals.any((g) => g.kind == GoalKind.openings), isFalse);
    scenario.now.advance(const Duration(days: 1));
    final tomorrow = BuildDayGoals(scenario.now, scenario.config)(
      started,
      scenario.content,
    );
    expect(tomorrow.day!.goals.any((g) => g.kind == GoalKind.openings), isTrue);
    final edited = start(
      tomorrow,
      scenario.content,
      const TrainingPlan(minutes: 60),
    );
    expect(edited.day, same(tomorrow.day));
    expect(edited.openings[lesson.id], same(tomorrow.openings[lesson.id]));
    expect(edited.plan.minutes, 60);
  });

  test('aula observada antes do plano fica guardada e revisa só no dia seguinte ao plano', () async {
    const config = TrainingCourseConfig.pilares;
    final now = FakeNow(DateTime(2026, 10, 20, 12));
    final repository = FakeTrainingRepository(
      content: {config.course: content},
    );
    addTearDown(repository.dispose);
    final bridge = TrainingLearningBridge(repository);
    final completion = LearningUnitCompletion(
      kind: 'endgame_lesson',
      unitId: 'pilares.c1/topic',
      at: now(),
    );
    await bridge(completion);
    final before = await repository.load(config.course);
    expect(before.completedLessons[theme.id], '2026-10-20');
    expect(before.onboardingDone, isFalse);
    expect(before.day, isNull);
    final writes = repository.writes;
    await bridge(completion);
    expect(repository.writes, writes);

    now.value = DateTime(2026, 10, 26, 12);
    await savePlan(repository, now, config);
    final started = await repository.load(config.course);
    expect(started.completedLessons[theme.id], '2026-10-20');
    expect(started.cycles[theme.id]!.startedOn, '2026-10-26');
    expect(
      started.day!.goals.where((g) => g.kind == GoalKind.exercise),
      isEmpty,
    );
    now.advance(const Duration(days: 1));
    final tomorrow = BuildDayGoals(now, config)(started, content);
    expect(
      tomorrow.day!.goals.any(
        (g) => g.kind == GoalKind.exercise && g.ref == theme.id,
      ),
      isTrue,
    );
  });

  test('histórico importado antigo não antecipa a revisão para o dia do primeiro plano', () async {
    const config = TrainingCourseConfig.pilares;
    final now = FakeNow(DateTime(2026, 10, 26, 12));
    final repository = FakeTrainingRepository(
      content: {config.course: content},
      states: {
        config.course: TrainingState(
          course: config.course,
          installSeed: 'seed',
          completedLessons: {theme.id: '2026-10-20'},
          cycles: {
            theme.id: ThemeCycle(lessonId: theme.id, startedOn: '2026-10-20'),
          },
        ),
      },
    );
    addTearDown(repository.dispose);
    await savePlan(repository, now, config);
    final state = await repository.load(config.course);
    expect(state.day!.goals.where((g) => g.kind == GoalKind.exercise), isEmpty);
    expect(state.cycles[theme.id]!.startedOn, '2026-10-26');
  });

  test('Escola adia só revisões anteriores ao plano, inclusive após outra aula no mesmo dia', () async {
    const config = TrainingCourseConfig.escola;
    const rook = TrainingLesson(
      id: 'pieces.rook',
      kind: TrainingLessonKind.school,
      title: 'Torre',
    );
    const queen = TrainingLesson(
      id: 'pieces.queen',
      kind: TrainingLessonKind.school,
      title: 'Dama',
    );
    final resources = TrainingResources(lessons: [rook, queen]);
    final repository = FakeTrainingRepository(
      content: {config.course: resources},
    );
    addTearDown(repository.dispose);
    final now = FakeNow(DateTime(2026, 10, 20, 12));
    final bridge = TrainingLearningBridge(repository, courses: [config]);
    await bridge(
      LearningUnitCompletion(kind: 'school_lesson', unitId: rook.id, at: now()),
    );
    expect(
      (await repository.load(config.course)).completedLessons[rook.id],
      '2026-10-20',
    );
    now.value = DateTime(2026, 10, 26, 12);
    await savePlan(repository, now, config);
    var state = await repository.load(config.course);
    expect(
      state.day!.goals.any((g) => g.kind == GoalKind.stars && g.ref == rook.id),
      isFalse,
    );
    final completeDay = state.copyWith(
      day: state.day!.copyWith(
        goals: state.day!.goals.map((g) => g.complete()),
      ),
    );
    final doubled = DoubleTrainingGoals(now, config)(completeDay, resources);
    expect(
      doubled.day!.goals.any(
        (g) => g.kind == GoalKind.stars && g.ref == rook.id,
      ),
      isFalse,
    );
    await bridge(
      LearningUnitCompletion(
        kind: 'school_lesson',
        unitId: queen.id,
        at: now(),
      ),
    );
    state = await repository.load(config.course);
    expect(
      state.day!.goals.any((g) => g.kind == GoalKind.stars && g.ref == rook.id),
      isFalse,
    );
    expect(
      state.day!.goals.any(
        (g) => g.kind == GoalKind.stars && g.ref == queen.id,
      ),
      isTrue,
    );
    now.advance(const Duration(days: 1));
    state = BuildDayGoals(now, config)(state, resources);
    expect(
      state.day!.goals.any((g) => g.kind == GoalKind.stars && g.ref == rook.id),
      isTrue,
    );
  });
}
