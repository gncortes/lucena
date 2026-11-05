import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/demo_goals.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';

import '../../../../testing/training/training_scenario_builder.dart';

void main() {
  // Gap da demo (T85, Proposta B): quem termina o Capítulo 1 na demonstração
  // recebia como meta do dia uma lição do Capítulo 2, trancada.
  final content = TrainingResources(
    lessons: const [
      TrainingLesson(
        id: 'pilares.c1.tema',
        kind: TrainingLessonKind.theme,
        title: 'Tema 1',
        groupId: 'pilares.c1',
      ),
      TrainingLesson(
        id: 'pilares.c1.teste',
        kind: TrainingLessonKind.test,
        title: 'Teste 1',
        groupId: 'pilares.c1',
      ),
      TrainingLesson(
        id: 'pilares.c2.tema',
        kind: TrainingLessonKind.theme,
        title: 'Tema 2',
        groupId: 'pilares.c2',
      ),
      TrainingLesson(
        id: 'pilares.c2.teste',
        kind: TrainingLessonKind.test,
        title: 'Teste 2',
        groupId: 'pilares.c2',
      ),
    ],
  );
  final scenario = TrainingScenarioBuilder(
    TrainingCourse.pilares,
    resources: content,
  );
  TrainingState chapterOneDone({List<TrainingGoal> deferred = const []}) =>
      TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'demo',
        onboardingDone: true,
        plan: TrainingPlan(weekdays: 127),
        completedLessons: const {
          'pilares.c1.tema': '2026-10-01',
          'pilares.c1.teste': '2026-10-01',
        },
        deferredGoals: deferred,
      );
  List<String> lessonsOfToday(TrainingState state, TrainingResources r) =>
      BuildDayGoals(scenario.now, scenario.config)(state, r).day!.goals
          .where((g) => g.kind == GoalKind.lesson)
          .map((g) => g.ref)
          .toList();

  test('com o curso completo, a meta do dia segue para o Capítulo 2', () {
    expect(lessonsOfToday(chapterOneDone(), content), ['pilares.c2.tema']);
  });

  test('na demo, a meta do dia não oferece lição trancada', () {
    final demo = DemoGoals.restrict(content);
    expect(demo.lockedLessons, {'pilares.c2.tema', 'pilares.c2.teste'});
    expect(lessonsOfToday(chapterOneDone(), demo), isEmpty);
    expect(DemoGoals.chapterOneDone(chapterOneDone(), demo), isTrue);
  });

  test('na demo, lição trancada que ficou de ontem não volta hoje', () {
    final state = chapterOneDone(
      deferred: [TrainingGoal(kind: GoalKind.lesson, ref: 'pilares.c2.tema')],
    );
    expect(lessonsOfToday(state, DemoGoals.restrict(content)), isEmpty);
  });

  test('Capítulo 1 em andamento ainda vira meta do dia na demo', () {
    final state = TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 'demo',
      onboardingDone: true,
      plan: TrainingPlan(weekdays: 127),
      completedLessons: const {'pilares.c1.tema': '2026-10-01'},
    );
    final demo = DemoGoals.restrict(content);
    expect(lessonsOfToday(state, demo), ['pilares.c1.teste']);
    expect(DemoGoals.chapterOneDone(state, demo), isFalse);
  });
  test('a compra no meio do dia completa a lição que faltava, sem refazer '
      'o resto', () {
    final build = BuildDayGoals(scenario.now, scenario.config);
    // O dia nasceu na demo: sem lição. Uma meta já foi feita antes da compra.
    final demoDay = build(chapterOneDone(), DemoGoals.restrict(content));
    final day = demoDay.day!;
    expect(day.goals.where((g) => g.kind == GoalKind.lesson), isEmpty);
    final started = demoDay.copyWith(
      day: day.copyWith(
        goals: [
          ...day.goals,
          TrainingGoal(kind: GoalKind.exercise, ref: 'feito', done: true),
        ],
      ),
    );
    final bought = build(started, content);
    expect(
      bought.day!.goals
          .where((g) => g.kind == GoalKind.lesson)
          .map((g) => g.ref),
      ['pilares.c2.tema'],
    );
    // O que já foi feito hoje fica como estava.
    expect(bought.day!.date, day.date);
    expect(
      bought.day!.goals.where((g) => g.kind != GoalKind.lesson),
      started.day!.goals,
    );
    expect(bought.lastLessonDate, day.date);
    // Recarregar de novo não muda nada.
    expect(build(bought, content).day!.goals, bought.day!.goals);
  });

  test('dia com lição já cumprida não ganha outra no recarregar', () {
    final build = BuildDayGoals(scenario.now, scenario.config);
    final owned = build(chapterOneDone(), content);
    final lesson = owned.day!.goals.first;
    final done = owned.copyWith(
      day: owned.day!.copyWith(
        goals: [
          TrainingGoal(kind: lesson.kind, ref: lesson.ref, done: true),
          ...owned.day!.goals.skip(1),
        ],
      ),
      completedLessons: {...owned.completedLessons, lesson.ref: '2026-10-26'},
    );
    expect(build(done, content).day!.goals, done.day!.goals);
  });

  test('só a demo do Pilares tranca: comprador e Escola veem tudo aberto', () {
    Set<String> locked(TrainingCourse course, CourseAccess access) =>
        DemoGoals.forAccess(course, access, content).lockedLessons;
    expect(locked(TrainingCourse.pilares, CourseAccess.owned), isEmpty);
    expect(locked(TrainingCourse.escola, CourseAccess.demo), isEmpty);
    expect(locked(TrainingCourse.pilares, CourseAccess.demo), {
      'pilares.c2.tema',
      'pilares.c2.teste',
    });
  });
}
