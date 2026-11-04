import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/goal/study_plan.dart';
import 'package:lucena/domain/models/training/goal/training_diagnostic.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/goal/diagnostic_test_size.dart';
import 'package:lucena/domain/use_cases/training/goal/generate_study_plan.dart';
import 'package:lucena/domain/use_cases/training/goal/plan_chapters.dart';
import 'package:lucena/domain/use_cases/training/goal/plan_status.dart';
import 'package:lucena/domain/use_cases/training/goal/tournament_rules.dart';

TrainingResources course({int chapters = 6, int lessonsEach = 3}) {
  final lessons = <TrainingLesson>[];
  for (var c = 1; c <= chapters; c++) {
    final part = c <= 3 ? 'p1' : 'p2';
    for (var l = 1; l <= lessonsEach; l++) {
      lessons.add(
        TrainingLesson(
          id: 'c$c.l$l',
          kind: TrainingLessonKind.theme,
          title: 'Lição $l',
          group: 'Capítulo $c',
          groupId: 'c$c',
          partId: part,
          partTitle: 'Parte $part',
        ),
      );
    }
    lessons.add(
      TrainingLesson(
        id: 'c$c.test',
        kind: TrainingLessonKind.test,
        title: 'Teste',
        group: 'Capítulo $c',
        groupId: 'c$c',
        partId: part,
        partTitle: 'Parte $part',
      ),
    );
  }
  return TrainingResources(lessons: lessons);
}

void main() {
  group('data do torneio (casos 4 e 5)', () {
    test('hoje e passado são bloqueados; amanhã é a primeira data', () {
      expect(earliestTournamentDate('2026-11-04'), '2026-11-05');
      expect(isValidTournamentDate('2026-11-04', '2026-11-04'), isFalse);
      expect(isValidTournamentDate('2026-11-03', '2026-11-04'), isFalse);
      expect(isValidTournamentDate(null, '2026-11-04'), isFalse);
      expect(isValidTournamentDate('2026-11-05', '2026-11-04'), isTrue);
    });
    test('amanhã falta 1 dia', () {
      expect(daysUntil('2026-11-04', '2026-11-05'), 1);
      expect(daysUntil('2026-11-04', '2026-12-14'), 40);
    });
  });

  test('caso 8: Até o torneio soma minutos x dias marcados', () {
    const plan = TrainingPlan(minutes: 60, weekdays: 62);
    // segunda 2 a segunda 9 de novembro: 5 dias de estudo.
    expect(studyMinutesUntil(plan, '2026-11-02', '2026-11-09'), 300);
    expect(studyMinutesUntil(plan, '2026-11-04', '2026-11-09'), 180);
  });

  group('caso 12: tamanho do teste', () {
    test('nunca sai de 5 a 20', () {
      expect(diagnosticTestSize(0), 5);
      expect(diagnosticTestSize(60), 5);
      expect(diagnosticTestSize(120), 5);
      expect(diagnosticTestSize(30 * 60), 20);
      expect(diagnosticTestSize(500 * 60), 20);
    });
    test('cresce com a capacidade', () {
      var last = 0;
      for (var m = 0; m <= 40 * 60; m += 60) {
        final size = diagnosticTestSize(m);
        expect(size, greaterThanOrEqualTo(last));
        last = size;
      }
    });
    test('grupo só com teste (sem lição de tema) não vira capítulo', () {
      final base = course(chapters: 2);
      final resources = TrainingResources(
        lessons: [
          ...base.lessons,
          const TrainingLesson(
            id: 'ab.test',
            kind: TrainingLessonKind.test,
            title: 'Teste',
            group: 'Aberturas',
            groupId: 'ab',
            partId: 'p',
            partTitle: 'Parte',
          ),
        ],
        banks: base.banks,
        openings: base.openings,
      );
      final chapters = planChapters(resources);
      expect(chapters.map((c) => c.id), isNot(contains('ab')));
      expect(chapters.every((c) => c.lessonIds.isNotEmpty), isTrue);
    });
    test('capítulos do teste não passam do que existe', () {
      final chapters = planChapters(course(chapters: 3));
      expect(diagnosticChapters(chapters, 20), hasLength(3));
      expect(diagnosticChapters(chapters, 2), hasLength(2));
    });
  });

  group('plano', () {
    final chapters = planChapters(course());
    final objective = TrainingObjective(
      kind: ObjectiveKind.tournament,
      setOn: '2026-11-04',
      tournamentDate: '2026-11-25',
    );
    const time = TrainingPlan(minutes: 60, weekdays: 62);

    test('capítulos inteiros: lições mais o teste', () {
      expect(chapters, hasLength(6));
      expect(chapters.first.lessonIds, hasLength(3));
      expect(chapters.first.testId, 'c1.test');
      expect(chapters.first.minutes, 60);
    });

    test('caso 17: tema Forte fica fora do plano', () {
      final plan = generateStudyPlan(
        chapters: chapters,
        levels: {'p1': TopicLevel.mastered, 'p2': TopicLevel.learning},
        completedLessons: const {},
        time: time,
        objective: objective,
        today: '2026-11-04',
      );
      expect(plan.chapterIds, isNot(contains('c1')));
      expect(plan.chapterIds, isNot(contains('c3')));
      expect(plan.chapterIds, containsAll(['c4', 'c5', 'c6']));
      expect(plan.deferredIds, isEmpty);
    });

    test(
      'o que não cabe vai para depois do torneio; última semana é revisão',
      () {
        final plan = generateStudyPlan(
          chapters: chapters,
          levels: const {},
          completedLessons: const {},
          time: const TrainingPlan(minutes: 15, weekdays: 62),
          objective: objective,
          today: '2026-11-04',
        );
        expect(plan.weeks.last.review, isTrue);
        expect(plan.weeks.where((w) => w.review), hasLength(1));
        expect(plan.deferredIds, isNotEmpty);
        final inWeeks = [for (final w in plan.weeks) ...w.chapterIds];
        expect(inWeeks.toSet(), plan.chapterIds.toSet());
        expect(plan.deferredIds.toSet().intersection(inWeeks.toSet()), isEmpty);
      },
    );

    test('torneio amanhã: o plano tem 1 dia de revisão', () {
      final plan = generateStudyPlan(
        chapters: chapters,
        levels: const {},
        completedLessons: const {},
        time: time,
        objective: TrainingObjective(
          kind: ObjectiveKind.tournament,
          setOn: '2026-11-04',
          tournamentDate: '2026-11-05',
        ),
        today: '2026-11-04',
      );
      expect(plan.weeks, hasLength(1));
      expect(plan.weeks.single.review, isTrue);
      expect(plan.chapterIds, isEmpty);
    });

    test('só melhorar: fila na ordem do curso, sem semanas', () {
      final plan = generateStudyPlan(
        chapters: chapters,
        levels: {'p1': TopicLevel.mastered},
        completedLessons: {
          for (final id in chapters[3].allIds) id: '2026-11-01',
        },
        time: time,
        objective: TrainingObjective(
          kind: ObjectiveKind.improve,
          setOn: '2026-11-04',
        ),
        today: '2026-11-04',
      );
      expect(plan.weeks, isEmpty);
      expect(plan.chapterIds, ['c5', 'c6']);
    });
  });

  group('caso 21: capítulo atrasado', () {
    final chapters = {for (final c in planChapters(course())) c.id: c};
    final plan = StudyPlan(
      createdOn: '2026-11-04',
      weeks: [
        PlanWeek(
          start: '2026-11-04',
          end: '2026-11-10',
          chapterIds: ['c1', 'c2'],
        ),
        PlanWeek(start: '2026-11-11', end: '2026-11-17', chapterIds: ['c3']),
      ],
      chapterIds: ['c1', 'c2', 'c3'],
    );
    test('semana passada com capítulo aberto atrasa', () {
      final done = {for (final id in chapters['c1']!.allIds) id: '2026-11-05'};
      expect(lateChapterIds(plan, chapters, done, '2026-11-12'), ['c2']);
    });
    test('semana atual não atrasa', () {
      expect(lateChapterIds(plan, chapters, const {}, '2026-11-09'), isEmpty);
    });
  });

  group('caso 26: dia perdido', () {
    TrainingState state(List<String> studied) => TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 's',
      studiedDates: studied,
    );
    test('dia de estudo sem registro é perdido', () {
      // quarta 4 é o último dia de estudo antes de quinta 5.
      expect(
        missedStudyDay(state(const []), '2026-11-05', since: '2026-11-01'),
        '2026-11-04',
      );
    });
    test('dia estudado não é perdido', () {
      expect(
        missedStudyDay(
          state(['2026-11-04']),
          '2026-11-05',
          since: '2026-11-01',
        ),
        isNull,
      );
    });
    test('fim de semana descansa: sexta feita, segunda sem perda', () {
      expect(
        missedStudyDay(
          state(['2026-11-06']),
          '2026-11-09',
          since: '2026-11-01',
        ),
        isNull,
      );
    });
    test('sequência zera quando falta um dia', () {
      expect(studyStreak(state(['2026-11-03', '2026-11-04']), '2026-11-05'), 2);
      expect(studyStreak(state(['2026-11-03']), '2026-11-05'), 0);
    });
    test('minutos por dia necessários', () {
      const plan = TrainingPlan(minutes: 30, weekdays: 62);
      // 5 dias de estudo restantes (seg 9 a sex 13) e 250 min: 50 por dia.
      expect(
        minutesPerDayNeeded(
          minutesLeft: 250,
          plan: plan,
          today: '2026-11-09',
          tournamentDate: '2026-11-14',
        ),
        50,
      );
    });
    test('continuar com o tempo do aluno tira o último capítulo', () {
      const plan = TrainingPlan(minutes: 30, weekdays: 62);
      final fit = fitPlanToMinutes(
        chapterIds: ['a', 'b', 'c'],
        minutesLeft: {'a': 60, 'b': 60, 'c': 60},
        plan: plan,
        today: '2026-11-09',
        tournamentDate: '2026-11-14',
      );
      expect(fit.dropped, ['c']);
      expect(fit.kept, ['a', 'b']);
    });
  });

  test('caso 33: dia do torneio e depois', () {
    expect(tournamentPhase('2026-12-13', '2026-12-14'), TournamentPhase.before);
    expect(tournamentPhase('2026-12-14', '2026-12-14'), TournamentPhase.day);
    expect(tournamentPhase('2026-12-15', '2026-12-14'), TournamentPhase.after);
    expect(canRegisterTournament('2026-12-14', '2026-12-14'), isFalse);
    expect(canRegisterTournament('2026-12-15', '2026-12-14'), isTrue);
  });
}
