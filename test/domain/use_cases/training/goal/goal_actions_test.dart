import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/goal/study_plan.dart';
import 'package:lucena/domain/models/training/goal/tournament_record.dart';
import 'package:lucena/domain/models/training/goal/training_diagnostic.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/goal/goal_actions.dart';
import 'package:lucena/domain/use_cases/training/goal/goal_view.dart';
import 'package:lucena/domain/use_cases/training/goal/plan_chapters.dart';
import 'package:lucena/domain/use_cases/training/goal/plan_status.dart';

import 'goal_rules_test.dart' show course;

TrainingState base() =>
    TrainingState(course: TrainingCourse.pilares, installSeed: 's');

TrainingObjective tournament(String date) => TrainingObjective(
  kind: ObjectiveKind.tournament,
  setOn: '2026-11-04',
  tournamentDate: date,
);

TrainingState roundTrip(TrainingState s) => TrainingState.fromJson(
  jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
);

void main() {
  final resources = course();
  planOrderTests();

  test('objetivo novo manda o anterior para o histórico', () {
    final a = applyObjective(base(), tournament('2026-12-14'));
    final b = applyObjective(a, tournament('2026-12-20'));
    expect(b.objective!.tournamentDate, '2026-12-20');
    expect(b.objectiveHistory.single.tournamentDate, '2026-12-14');
    expect(b.studyPlan, isNull);
  });

  test('estado sem os campos novos abre (migração tolerante)', () {
    final json = base().toJson()
      ..remove('objective')
      ..remove('studyPlan')
      ..remove('tournaments');
    final s = TrainingState.fromJson(json);
    expect(s.objective, isNull);
    expect(s.tournaments, isEmpty);
  });

  test('objetivo ilegível vira nulo em vez de derrubar o estado', () {
    final json = base().toJson()..['objective'] = {'kind': 'xyz', 'setOn': 3};
    expect(TrainingState.fromJson(json).objective, isNull);
  });

  test('cada resposta do teste sobrevive a fechar o app (ida e volta)', () {
    final chapters = planChapters(resources);
    var s = applyObjective(base(), tournament('2026-12-14'));
    s = startDiagnosticTest(s, chapters, 5);
    s = answerDiagnosticTest(s, true);
    s = answerDiagnosticTest(s, false);
    s = answerDiagnosticTest(s, false);
    final back = roundTrip(s);
    expect(back.diagnostic!.testAnswered, 3);
    expect(back.diagnostic!.testSize, 5);
    expect(back.diagnostic!.testComplete, isFalse);
    expect(restartDiagnostic(back).diagnostic, isNull);
  });

  test('questionário grava a cada área', () {
    var s = applyObjective(base(), tournament('2026-12-14'));
    s = startQuestionnaire(s);
    s = answerQuestionnaire(s, 'p1', TopicLevel.mastered);
    s = answerQuestionnaire(s, 'p2', TopicLevel.learning);
    expect(roundTrip(s).diagnostic!.topics, {
      'p1': TopicLevel.mastered,
      'p2': TopicLevel.learning,
    });
  });

  test('terminar o diagnóstico gera o plano e o plano persiste', () {
    var s = applyObjective(base(), tournament('2026-11-25'));
    s = s.copyWith(plan: const TrainingPlan(minutes: 60));
    s = startQuestionnaire(s);
    s = answerQuestionnaire(s, 'p1', TopicLevel.mastered);
    s = answerQuestionnaire(s, 'p2', TopicLevel.learning);
    s = finishDiagnostic(s, resources, '2026-11-04');
    final back = roundTrip(s);
    expect(back.diagnostic!.finished, isTrue);
    expect(back.studyPlan!.chapterIds, isNot(contains('c1')));
    expect(back.studyPlan!.weeks, isNotEmpty);
  });

  test('H-TRE-09: voltar ao plano anterior desfaz o último ajuste', () {
    var s = applyObjective(base(), tournament('2026-11-25'));
    s = s.copyWith(plan: const TrainingPlan(minutes: 60));
    s = startQuestionnaire(s);
    s = answerQuestionnaire(s, 'p1', TopicLevel.mastered);
    s = finishDiagnostic(s, resources, '2026-11-04');
    expect(s.previousStudyPlan, isNull);
    expect(undoAdjust(s), same(s));
    final original = s.studyPlan!;
    s = roundTrip(
      replan(
        s.copyWith(plan: const TrainingPlan(minutes: 30)),
        resources,
        '2026-11-06',
      ),
    );
    expect(s.previousStudyPlan!.toJson(), original.toJson());
    expect(s.studyPlan!.toJson(), isNot(original.toJson()));
    final back = roundTrip(undoAdjust(s));
    expect(back.studyPlan!.toJson(), original.toJson());
    expect(back.previousStudyPlan, isNull);
  });

  test('caso 23: Agora não não muda o plano', () {
    var s = applyObjective(base(), tournament('2026-11-25'));
    s = s.copyWith(
      studyPlan: StudyPlan(
        createdOn: '2026-11-04',
        weeks: [
          PlanWeek(start: '2026-11-04', end: '2026-11-10', chapterIds: ['c1']),
        ],
        chapterIds: ['c1'],
      ),
    );
    final view = GoalView.of(s, resources, '2026-11-12');
    expect(view.late.single.chapter.id, 'c1');
    final after = dismissLate(s, ['c1@1']);
    expect(after.studyPlan!.weeks.single.chapterIds, ['c1']);
    expect(GoalView.of(after, resources, '2026-11-12').late, isEmpty);
  });

  test('caso 26: sem registro do dia anterior, o aviso pede mais minutos', () {
    var s = applyObjective(base(), tournament('2026-11-25'));
    s = s.copyWith(
      plan: const TrainingPlan(minutes: 30),
      studyPlan: StudyPlan(
        createdOn: '2026-11-01',
        weeks: [
          PlanWeek(
            start: '2026-11-02',
            end: '2026-11-08',
            chapterIds: ['c1', 'c2', 'c3'],
          ),
        ],
        chapterIds: ['c1', 'c2', 'c3'],
      ),
    );
    final view = GoalView.of(s, resources, '2026-11-05');
    expect(view.missedDay, isTrue);
    expect(view.streak, 0);
    expect(view.minutesNeeded, greaterThan(0));
    final noted = noteMissedDay(s, '2026-11-05', view.minutesNeeded);
    expect(roundTrip(noted).missedDayNoticeOn, '2026-11-05');
  });

  test('caso 27: continuar com o tempo tira o último capítulo', () {
    var s = applyObjective(base(), tournament('2026-11-12'));
    s = s.copyWith(
      plan: const TrainingPlan(minutes: 30),
      studyPlan: StudyPlan(
        createdOn: '2026-11-01',
        weeks: [
          PlanWeek(
            start: '2026-11-04',
            end: '2026-11-10',
            chapterIds: ['c1', 'c2', 'c3', 'c4', 'c5', 'c6'],
          ),
        ],
        chapterIds: ['c1', 'c2', 'c3', 'c4', 'c5', 'c6'],
      ),
    );
    final kept = confirmKeepTime(s, resources, '2026-11-04');
    expect(kept.studyPlan!.deferredIds, contains('c6'));
    expect(kept.studyPlan!.chapterIds, isNot(contains('c6')));
    expect(kept.missedDayNoticeOn, isNull);
  });

  group('caso 35: registro', () {
    test('sem pontos não grava', () {
      final r = registerTournament(
        base(),
        TournamentDraft(rounds: '7', date: '2026-12-15'),
        'x',
      );
      expect(r, isNull);
      expect(draftError(TournamentDraft(rounds: '7')), DraftError.points);
    });
    test('pontos acima das rodadas não gravam', () {
      expect(
        draftError(TournamentDraft(points: '8', rounds: '7')),
        DraftError.pointsTooHigh,
      );
    });
    test('salvo vai ao topo e o rascunho some; não muda o plano', () {
      var s = base().copyWith(
        studyPlan: StudyPlan(createdOn: '2026-11-04', chapterIds: ['c1']),
      );
      s = saveTournamentDraft(
        s,
        TournamentDraft(
          name: 'A',
          points: '3,5',
          rounds: '5',
          date: '2026-10-11',
        ),
      );
      expect(roundTrip(s).tournamentDraft!.points, '3,5');
      s = registerTournament(s, s.tournamentDraft!, 'a')!;
      s = registerTournament(
        s,
        TournamentDraft(
          name: 'B',
          points: '4,5',
          rounds: '7',
          date: '2026-12-15',
        ),
        'b',
      )!;
      final back = roundTrip(s);
      expect(back.tournaments.map((t) => t.id), ['b', 'a']);
      expect(back.tournaments.last.tenthsPoints, 35);
      expect(back.tournamentDraft, isNull);
      expect(back.studyPlan!.chapterIds, ['c1']);
    });
    test('pontos só em meios', () {
      expect(parseTenths('4,5'), 45);
      expect(parseTenths('4.0'), 40);
      expect(parseTenths('4,3'), isNull);
      expect(parseTenths(''), isNull);
    });
  });
}

void planOrderTests() {
  final resources = course();
  group('metas seguem a ordem do plano (H-TRE-10)', () {
    TrainingState withPlan() => base().copyWith(
      studyPlan: StudyPlan(
        createdOn: '2026-11-04',
        chapterIds: const ['c3', 'c1'],
        weeks: [
          PlanWeek(
            start: '2026-11-02',
            end: '2026-11-08',
            chapterIds: const ['c3'],
          ),
          PlanWeek(
            start: '2026-11-09',
            end: '2026-11-15',
            chapterIds: const ['c1'],
          ),
        ],
      ),
    );

    test('sem plano, a ordem é a do curso', () {
      final ids = lessonOrderForPlan(base(), resources, '2026-11-04');
      expect(ids.first, 'c1.l1');
    });

    test('com plano, vêm primeiro os capítulos da semana atual', () {
      final ids = lessonOrderForPlan(withPlan(), resources, '2026-11-04');
      expect(ids.take(4), ['c3.l1', 'c3.l2', 'c3.l3', 'c3.test']);
      expect(
        ids.skip(4).first,
        'c1.l1',
        reason: 'depois, as semanas seguintes',
      );
    });

    test('o resto do curso vem depois do plano, na ordem do curso', () {
      final ids = lessonOrderForPlan(withPlan(), resources, '2026-11-04');
      expect(ids.indexOf('c2.l1'), greaterThan(ids.indexOf('c1.test')));
      expect(ids.toSet(), resources.lessons.map((l) => l.id).toSet());
    });
  });
}
