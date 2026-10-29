import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/complete_training_goal.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/domain/use_cases/training/double_training_goals.dart';
import 'package:lucena/domain/use_cases/training/exercise_picker.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/domain/use_cases/training/opening_trecho_rules.dart';
import 'package:lucena/domain/use_cases/training/reminder_text.dart';
import 'package:lucena/domain/use_cases/training/theme_cycle_rules.dart';

import '../../../../testing/fakes/fake_now.dart';

const config = TrainingCourseConfig.pilares;
const first = TrainingLesson(
  id: 'theme1',
  kind: TrainingLessonKind.theme,
  title: 'Tema 1',
);
const second = TrainingLesson(
  id: 'theme2',
  kind: TrainingLessonKind.theme,
  title: 'Tema 2',
);
const openingLesson = TrainingLesson(
  id: 'opening',
  kind: TrainingLessonKind.opening,
  title: 'Abertura',
);
TrainingExercise exercise(String id, int stars, {bool mock = false}) =>
    TrainingExercise(
      id: id,
      stars: stars,
      fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
      solution: ['a1a8'],
      mock: mock,
    );
List<TrainingExercise> bank({bool mock = false}) => [
  for (var stars = 1; stars <= 3; stars++)
    for (var i = 0; i < [0, 6, 5, 3][stars]; i++)
      exercise('$stars-$i', stars, mock: mock),
];
TrainingState initial() => TrainingState(
  course: TrainingCourse.pilares,
  installSeed: 'installation',
  onboardingDone: true,
);
TrainingResources resources({bool mock = false}) => TrainingResources(
  lessons: [first, second, openingLesson],
  banks: {
    'theme1': bank(mock: mock),
    'theme2': bank(mock: mock),
  },
  openings: {
    'opening': [
      OpeningTrecho(
        id: 't1',
        title: 'Linha 1',
        moves: ['d2d4', 'd7d5', 'c1f4'],
      ),
      OpeningTrecho(id: 't2', title: 'Linha 2', moves: ['d2d4', 'g8f6']),
    ],
  },
);

void main() {
  late FakeNow now;
  setUp(() {
    now = FakeNow(DateTime(2026, 10, 26, 12));
  }); // Monday

  test('ciclo limpo percorre 1 1 2 2 3 3 3 e fica firme com 100%', () {
    var cycle = ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-23');
    final levels = <int>[];
    for (var i = 0; i < 7; i++) {
      levels.add(cycle.level);
      cycle = ThemeCycleRules(now).record(
        cycle,
        exercise('e$i', cycle.level),
        correct: true,
        bank: bank(),
      );
      now.advance(const Duration(days: 1));
    }
    expect(levels, [1, 1, 2, 2, 3, 3, 3]);
    expect(cycle.score, 100);
    expect(cycle.phase, ThemePhase.firm);
  });

  test('DIAS_AD percorre 1 1 2 1 2 3 2 e nota 47%', () {
    var cycle = ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-23');
    final levels = <int>[];
    for (final correct in [true, true, false, true, true, false, true]) {
      levels.add(cycle.level);
      cycle = ThemeCycleRules(now).record(
        cycle,
        exercise('e${levels.length}', cycle.level),
        correct: correct,
        bank: bank(),
      );
      now.advance(const Duration(days: 1));
    }
    expect(levels, [1, 1, 2, 1, 2, 3, 2]);
    expect(cycle.score, 47);
    expect(cycle.phase, ThemePhase.reinforce);
  });

  test('dica guarda o acerto visual mas desce nível e não soma nota', () {
    final cycle = ThemeCycle(
      lessonId: 'theme1',
      startedOn: '2026-10-23',
      level: 3,
    );
    final next = ThemeCycleRules(now)
        .record(cycle, exercise('hint', 3), correct: true, hint: true);
    expect(next.days.single.correct, isTrue);
    expect(next.days.single.hint, isTrue);
    expect(next.days.single.earned, isFalse);
    expect(next.level, 2);
    expect(next.hadError, isTrue);
    expect(next.score, 0);
  });

  test(
    'resultado da nota respeita os limites e reforço 4 de 7 pede refazer',
    () {
      expect(ThemeCycleRules.result(47), ThemePhase.reinforce);
      expect(ThemeCycleRules.result(73), ThemePhase.firm);
      expect(ThemeCycleRules.result(27), ThemePhase.redo);
      expect(ThemeCycleRules.result(30), ThemePhase.reinforce);
      expect(ThemeCycleRules.result(70), ThemePhase.firm);
      var cycle = ThemeCycle(
        lessonId: 'theme1',
        startedOn: '2026-10-23',
        phase: ThemePhase.reinforce,
        reinforcement: [for (var i = 0; i < 7; i++) 'e$i'],
      );
      for (var i = 0; i < 7; i++) {
        cycle = ThemeCycleRules(now)
            .record(cycle, exercise('e$i', 1), correct: i < 4);
      }
      expect(cycle.reinforceScore, 57);
      expect(cycle.phase, ThemePhase.redo);
    },
  );

  test('reforço só usa não vistos e deixa três estrelas por último', () {
    final cycle = ThemeCycle(
      lessonId: 'theme1',
      startedOn: '2026-10-23',
      days: [
        const ThemeDay(
          date: '2026-10-23',
          exerciseId: '1-0',
          stars: 1,
          correct: true,
        ),
      ],
    );
    final ids = const ExercisePicker().reinforcement(bank(), cycle, 'seed');
    expect(ids, hasLength(13));
    expect(ids, isNot(contains('1-0')));
    expect(
      ids.take(11).any((id) => id.startsWith('3-')),
      isTrue,
    ); // starts at slot 11
    expect(ids.skip(10).every((id) => id.startsWith('3-')), isTrue);
  });

  test('picker é estável com banco em outra ordem e não repete inéditos', () {
    var cycle = ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-23');
    const picker = ExercisePicker();
    final first = picker(bank: bank(), cycle: cycle, installSeed: 'fixed')!;
    final reversed = picker(
      bank: bank().reversed,
      cycle: cycle,
      installSeed: 'fixed',
    )!;
    expect(first.id, reversed.id);
    final selected = <String>{};
    for (var i = 0; i < 6; i++) {
      final e = picker(bank: bank(), cycle: cycle, installSeed: 'fixed')!;
      expect(selected.add(e.id), isTrue);
      cycle = cycle.copyWith(
        days: [
          ...cycle.days,
          ThemeDay(
            date: '2026-10-${20 + i}',
            exerciseId: e.id,
            stars: 1,
            correct: false,
          ),
        ],
      );
    }
  });

  test('sem inéditos repete primeiro errado e então o mais antigo', () {
    final cycle = ThemeCycle(
      lessonId: 'theme1',
      startedOn: '2026-10-23',
      days: [
        const ThemeDay(
          date: '2026-10-21',
          exerciseId: 'old',
          stars: 1,
          correct: true,
        ),
        const ThemeDay(
          date: '2026-10-22',
          exerciseId: 'wrong',
          stars: 1,
          correct: false,
        ),
        const ThemeDay(
          date: '2026-10-23',
          exerciseId: 'new',
          stars: 1,
          correct: false,
        ),
      ],
    );
    expect(
      const ExercisePicker()(
        bank: [exercise('old', 1), exercise('wrong', 1), exercise('new', 1)],
        cycle: cycle,
        installSeed: 'x',
      )!.id,
      'wrong',
    );
  });

  test('metas são congeladas e plano alterado só vale amanhã', () {
    final data = resources();
    final build = BuildDayGoals(now, config);
    final state = build(initial(), data);
    final edited = state.copyWith(plan: const TrainingPlan(minutes: 240));
    expect(identical(build(edited, data), edited), isTrue);
    expect(edited.day!.goals, hasLength(1));
    now.advance(const Duration(days: 1));
    expect(
      build(edited, data).day!.goals.where((g) => g.kind == GoalKind.lesson),
      hasLength(2),
    );
  });

  test('meia-noite vira o dia local e conserva o exercício sem tentativa', () {
    now.value = DateTime(2026, 10, 26, 23, 59);
    final data = resources();
    final state = BuildDayGoals(now, config)(
      initial().copyWith(
        completedLessons: {'theme1': '2026-10-23'},
        cycles: {
          'theme1': ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-23'),
        },
      ),
      data,
    );
    final oldId = state.day!.goals
        .firstWhere((g) => g.kind == GoalKind.exercise)
        .itemId;
    now.advance(const Duration(minutes: 1));
    final next = BuildDayGoals(now, config)(state, data);
    expect(next.day!.date, '2026-10-27');
    expect(
      next.day!.goals.firstWhere((g) => g.kind == GoalKind.exercise).itemId,
      oldId,
    );
    expect(next.cycles['theme1']!.days, isEmpty);
  });

  test('dia perdido não acumula aula nem avança ciclo ou dificuldade', () {
    final data = resources();
    final build = BuildDayGoals(now, config);
    final state = build(
      initial().copyWith(
        cycles: {
          'theme2': ThemeCycle(
            lessonId: 'theme2',
            startedOn: '2026-10-23',
            level: 2,
          ),
        },
        completedLessons: {'theme2': '2026-10-23'},
      ),
      data,
    );
    now.advance(const Duration(days: 3));
    final next = build(state, data);
    expect(
      next.day!.goals.map((g) => g.key),
      state.day!.goals.map((g) => g.key),
    );
    expect(next.cycles['theme2']!.level, 2);
    expect(next.cycles['theme2']!.hadError, isFalse);
  });

  test(
    'plano 15 min alterna dias de estudo e plano 240 oferece duas aulas',
    () {
      final data = resources();
      var state = BuildDayGoals(now, config)(
        initial().copyWith(plan: const TrainingPlan(minutes: 15)),
        data,
      );
      state = CompleteTrainingLesson(now, config)(state, data, first);
      now.advance(const Duration(days: 1));
      state = BuildDayGoals(now, config)(state, data);
      expect(state.day!.goals.where((g) => g.kind == GoalKind.lesson), isEmpty);
      now.advance(const Duration(days: 1));
      state = BuildDayGoals(now, config)(state, data);
      expect(
        state.day!.goals.where((g) => g.kind == GoalKind.lesson).single.ref,
        second.id,
      );
      expect(
        BuildDayGoals(now, config)(
          initial().copyWith(plan: const TrainingPlan(minutes: 240)),
          data,
        ).day!.goals.where((g) => g.kind == GoalKind.lesson),
        hasLength(2),
      );
    },
  );

  test('aula extra vira meta cumprida e tema só aparece no dia seguinte', () {
    final data = resources();
    var state = CompleteTrainingLesson(now, config)(initial(), data, first);
    state = CompleteTrainingLesson(now, config)(state, data, second);
    expect(
      state.day!.goals.where((g) => g.kind == GoalKind.extraLesson).single.done,
      isTrue,
    );
    expect(state.day!.goals.where((g) => g.kind == GoalKind.exercise), isEmpty);
    now.advance(const Duration(days: 1));
    state = BuildDayGoals(now, config)(state, data);
    expect(
      state.day!.goals
          .where((g) => g.kind == GoalKind.exercise)
          .map((g) => g.ref),
      ['theme1', 'theme2'],
    );
  });

  test(
    'folga não tem metas e aula feita vira crédito no próximo dia de estudo',
    () {
      now.value = DateTime(2026, 10, 24, 12); // Saturday
      final data = resources();
      var state = CompleteTrainingLesson(now, config)(initial(), data, first);
      expect(state.day!.goals, isEmpty);
      expect(state.day!.studyDay, isFalse);
      now.advance(const Duration(days: 2));
      state = BuildDayGoals(now, config)(state, data);
      expect(state.day!.goals.first.ref, first.id);
      expect(state.day!.goals.first.done, isTrue);
      expect(
        state.day!.goals.where((g) => g.kind == GoalKind.lesson),
        hasLength(1),
      );
      expect(
        state.day!.goals.where((g) => g.kind == GoalKind.exercise),
        hasLength(1),
      );
    },
  );

  test('dobrar adianta aula e dia do ciclo, sem repetir aberturas e sem dobrar duas vezes', () {
    final data = resources();
    var state = initial().copyWith(
      completedLessons: {'theme1': '2026-10-23'},
      cycles: {
        'theme1': ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-23'),
      },
    );
    state = CompleteTrainingLesson(now, config)(state, data, second);
    final goal = state.day!.goals.firstWhere(
      (g) => g.kind == GoalKind.exercise,
    );
    state = CompleteTrainingGoal(now)
        .exercise(state, data, goal.key, correct: true);
    // An extra observed lesson is needed before doubling is offered.
    const extra = TrainingLesson(
      id: 'extra',
      kind: TrainingLessonKind.test,
      title: 'Extra',
    );
    state = CompleteTrainingLesson(now, config)(state, data, extra);
    final doubled = DoubleTrainingGoals(now, config)(state, data);
    expect(doubled.day!.doubled, isTrue);
    expect(
      doubled.day!.goals
          .where((g) => !g.done && g.kind == GoalKind.lesson)
          .single
          .ref,
      'opening',
    );
    expect(
      doubled.day!.goals
          .where((g) => !g.done && g.kind == GoalKind.exercise)
          .single
          .itemId,
      isNot(goal.itemId),
    );
    expect(
      identical(DoubleTrainingGoals(now, config)(doubled, data), doubled),
      isTrue,
    );
  });

  test(
    'resultado da meta é idempotente e meta antiga não pode ser concluída',
    () {
      final data = resources(mock: true);
      final state = BuildDayGoals(now, config)(
        initial().copyWith(
          cycles: {
            'theme1': ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-23'),
          },
          completedLessons: {'theme1': '2026-10-23'},
        ),
        data,
      );
      final goal = state.day!.goals.firstWhere(
        (g) => g.kind == GoalKind.exercise,
      );
      expect(state.mock, isTrue);
      final done = CompleteTrainingGoal(now)
          .exercise(state, data, goal.key, correct: true);
      expect(done.cycles['theme1']!.days.single.mock, isTrue);
      expect(
        identical(
          CompleteTrainingGoal(now)
              .exercise(done, data, goal.key, correct: true),
          done,
        ),
        isTrue,
      );
      now.advance(const Duration(days: 1));
      expect(
        identical(
          CompleteTrainingGoal(now)
              .exercise(state, data, goal.key, correct: true),
          state,
        ),
        isTrue,
      );
    },
  );

  test('sem arquivo a meta ausente não impede outras metas', () {
    final data = TrainingResources(
      lessons: [first, second],
      banks: {'theme2': bank()},
    );
    final state = BuildDayGoals(now, config)(
      initial().copyWith(
        completedLessons: {'theme1': '2026-10-23', 'theme2': '2026-10-23'},
        cycles: {
          for (final l in [first, second])
            l.id: ThemeCycle(lessonId: l.id, startedOn: '2026-10-23'),
        },
      ),
      data,
    );
    expect(state.day!.goals.single.ref, 'theme2');
  });

  test('trecho novo só amanhã e depois revisão do mais antigo', () {
    final segments = resources().openings['opening']!;
    var track = OpeningTrack(lessonId: 'opening', startedOn: '2026-10-23');
    var rules = OpeningTrechoRules(now);
    expect(rules.next(track, segments)!.id, 't1');
    track = rules.complete(track, segments[0], [true, false]);
    expect(rules.next(track, segments), isNull);
    now.advance(const Duration(days: 1));
    rules = OpeningTrechoRules(now);
    expect(rules.next(track, segments)!.id, 't2');
    track = rules.complete(track, segments[1], [true]);
    now.advance(const Duration(days: 1));
    expect(rules.next(track, segments)!.id, 't1');
    expect(track.firmMoves, 2);
    expect(track.seenMoves, 3);
  });

  test('meta única de aberturas termina quando todos os trechos congelados terminam', () {
    final data = resources();
    var state = BuildDayGoals(now, config)(
      initial().copyWith(
        openings: {
          'opening': OpeningTrack(lessonId: 'opening', startedOn: '2026-10-23'),
        },
      ),
      data,
    );
    state = CompleteTrainingGoal(now)
        .opening(state, data, 'opening', [true, false]);
    expect(
      state.day!.goals.firstWhere((g) => g.kind == GoalKind.openings).done,
      isTrue,
    );
  });

  test('lembrete retorna chave e argumentos ICU sem texto fixo', () {
    for (final n in [1, 3]) {
      final goals = [
        for (var i = 0; i < n; i++)
          TrainingGoal(kind: GoalKind.exercise, ref: 'e$i'),
      ];
      final without = reminderText(
        DayGoals(date: '2026-10-26', studyDay: true, goals: goals),
      )!;
      expect(without.key, 'trainingNotifGoals');
      expect(without.arguments, {'n': n});
      final withLesson = reminderText(
        DayGoals(
          date: '2026-10-26',
          studyDay: true,
          goals: [
            TrainingGoal(kind: GoalKind.lesson, ref: 'aula'),
            ...goals,
          ],
        ),
      )!;
      expect(withLesson.key, 'trainingNotifLesson');
      expect(withLesson.arguments, {'aula': 'aula', 'n': n});
    }
    expect(reminderText(DayGoals(date: '2026-10-26', studyDay: false)), isNull);
  });

  test('Home cobre aula, exercício, abertura, feito e folga', () {
    final data = resources();
    for (final sample in [
      (
        TrainingGoal(kind: GoalKind.lesson, ref: 'theme1'),
        HomeCourseStatus.lesson,
      ),
      (
        TrainingGoal(kind: GoalKind.exercise, ref: 'theme1'),
        HomeCourseStatus.exercise,
      ),
      (
        TrainingGoal(
          kind: GoalKind.openings,
          ref: 'openings',
          items: {'opening': 't1'},
        ),
        HomeCourseStatus.opening,
      ),
    ]) {
      final state = initial().copyWith(
        day: DayGoals(date: '2026-10-26', studyDay: true, goals: [sample.$1]),
      );
      expect(homeCourseCard(state, data)!.status, sample.$2);
    }
    expect(
      homeCourseCard(
        initial().copyWith(day: DayGoals(date: '2026-10-26', studyDay: true)),
        data,
      )!.status,
      HomeCourseStatus.done,
    );
    expect(
      homeCourseCard(
        initial().copyWith(day: DayGoals(date: '2026-10-26', studyDay: false)),
        data,
      )!.status,
      HomeCourseStatus.dayOff,
    );
    expect(
      homeCourseCard(
        TrainingState(course: TrainingCourse.pilares, installSeed: 'x'),
        data,
      ),
      isNull,
    );
  });

  test('Home retoma a primeira abertura ainda pendente', () {
    final state = initial().copyWith(
      day: DayGoals(
        date: '2026-10-26',
        studyDay: true,
        goals: [
          TrainingGoal(
            kind: GoalKind.openings,
            ref: 'openings',
            items: {'a': 't1', 'b': 't1'},
          ),
        ],
      ),
      openings: {
        'a': OpeningTrack(
          lessonId: 'a',
          startedOn: '2026-10-23',
          doneTrechos: {'t1': '2026-10-26'},
        ),
      },
    );
    expect(homeCourseCard(state, resources())!.ref, 'b');
  });

  test('editar plano não muda a quantidade de aulas ao dobrar hoje', () {
    final data = TrainingResources(
      lessons: [
        first,
        second,
        openingLesson,
        const TrainingLesson(
          id: 'fourth',
          kind: TrainingLessonKind.test,
          title: 'Teste',
        ),
      ],
    );
    final day = DayGoals(
      date: '2026-10-26',
      studyDay: true,
      plan: const TrainingPlan(minutes: 30),
      goals: [
        TrainingGoal(kind: GoalKind.lesson, ref: first.id, done: true),
        TrainingGoal(kind: GoalKind.extraLesson, ref: second.id, done: true),
      ],
    );
    final state = initial().copyWith(
      plan: const TrainingPlan(minutes: 240),
      day: day,
      completedLessons: {first.id: day.date, second.id: day.date},
    );
    final result = DoubleTrainingGoals(now, config)(state, data);
    expect(result.day!.goals.where((g) => !g.done), hasLength(1));
    expect(result.day!.plan.minutes, 30);
    expect(result.plan.minutes, 240);
  });

  test('JSON preserva tentativas com dica e resultados por lance', () {
    final state = initial().copyWith(
      cycles: {
        'theme1': ThemeCycle(
          lessonId: 'theme1',
          startedOn: '2026-10-23',
          level: 1,
          hadError: true,
          days: [
            const ThemeDay(
              date: '2026-10-26',
              exerciseId: 'mock-1',
              stars: 2,
              correct: true,
              hint: true,
              mock: true,
            ),
          ],
        ),
      },
      openings: {
        'opening': OpeningTrack(
          lessonId: 'opening',
          startedOn: '2026-10-23',
          doneTrechos: {'t1': '2026-10-26'},
          firstTry: {
            't1': [true, false],
          },
          lastNewDate: '2026-10-26',
        ),
      },
    );
    final result = TrainingState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
    );
    expect(result.toJson(), state.toJson());
    expect(result.cycles['theme1']!.days.single.hint, isTrue);
    expect(result.openings['opening']!.firstTry['t1'], [true, false]);
  });

  test('Home entre cursos usa última meta feita', () {
    final old = initial().copyWith(lastActivityAt: DateTime(2026, 10, 26));
    final recent = TrainingState(
      course: TrainingCourse.escola,
      installSeed: 'x',
      onboardingDone: true,
      lastActivityAt: DateTime(2026, 10, 27),
    );
    expect(latestTrainingCourse([recent, old])!.course, TrainingCourse.escola);
  });

  test('JSON ida e volta preserva retrato, dica, mock, plano e aba; versão desconhecida é recusada', () {
    final data = resources(mock: true);
    final state = BuildDayGoals(now, config)(
      initial().copyWith(
        tab: CourseGuideTab.goals,
        tourSeen: true,
        cycles: {
          'theme1': ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-23'),
        },
        openings: {
          'opening': OpeningTrack(lessonId: 'opening', startedOn: '2026-10-23'),
        },
      ),
      data,
    );
    final result = TrainingState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
    );
    expect(result.toJson(), state.toJson());
    expect(
      () => TrainingState.fromJson({...state.toJson(), 'version': 99}),
      throwsFormatException,
    );
    expect(() => result.cycles.clear(), throwsUnsupportedError);
    expect(() => result.day!.goals.clear(), throwsUnsupportedError);
  });
}
