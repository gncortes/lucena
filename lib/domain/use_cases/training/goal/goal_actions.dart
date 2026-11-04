import '../../../models/training/goal/study_plan.dart';
import '../../../models/training/goal/tournament_record.dart';
import '../../../models/training/goal/training_diagnostic.dart';
import '../../../models/training/goal/training_objective.dart';
import '../../../models/training/training_resources.dart';
import '../../../models/training/training_state.dart';
import 'diagnostic_test_size.dart';
import 'generate_study_plan.dart';
import 'plan_chapters.dart';
import 'plan_status.dart';
import 'tournament_rules.dart';

/// Funções puras `TrainingState -> TrainingState` do treino por meta. O
/// repositório aplica cada uma dentro de uma transação, então cada resposta
/// fica salva antes de a tela seguir (fechar à força não perde nada).

/// Novo objetivo: o anterior vai para o histórico e plano e diagnóstico recomeçam.
TrainingState applyObjective(TrainingState state, TrainingObjective objective) {
  final previous = state.objective;
  if (previous == objective) return state;
  return state.copyWith(
    objective: objective,
    objectiveHistory: [?previous, ...state.objectiveHistory],
    studyPlan: null,
    diagnostic: null,
    tournamentPushFor: null,
  );
}

/// Começa o teste de nível com [size] posições espaçadas pelo curso.
TrainingState startDiagnosticTest(
  TrainingState state,
  List<PlanChapter> chapters,
  int size,
) => state.copyWith(
  diagnostic: TrainingDiagnostic(
    method: DiagnosticMethod.test,
    testChapterIds: [for (final c in diagnosticChapters(chapters, size)) c.id],
  ),
);

TrainingState restartDiagnostic(TrainingState state) =>
    state.copyWith(diagnostic: null);

/// Grava uma resposta do teste; "Não sei" chega como `false`.
TrainingState answerDiagnosticTest(TrainingState state, bool correct) {
  final d = state.diagnostic;
  if (d == null || d.method != DiagnosticMethod.test || d.testComplete) {
    return state;
  }
  return state.copyWith(
    diagnostic: d.copyWith(testAnswers: [...d.testAnswers, correct]),
  );
}

TrainingState startQuestionnaire(TrainingState state) {
  final d = state.diagnostic;
  if (d?.method == DiagnosticMethod.questionnaire) return state;
  return state.copyWith(
    diagnostic: TrainingDiagnostic(method: DiagnosticMethod.questionnaire),
  );
}

TrainingState answerQuestionnaire(
  TrainingState state,
  String partId,
  TopicLevel level,
) {
  final d = state.diagnostic;
  if (d == null || d.method != DiagnosticMethod.questionnaire) return state;
  return state.copyWith(
    diagnostic: d.copyWith(topics: {...d.topics, partId: level}),
  );
}

/// Fecha o diagnóstico e gera o plano (teste concluído ou "Montar o plano").
TrainingState finishDiagnostic(
  TrainingState state,
  TrainingResources resources,
  String today,
) {
  final objective = state.objective;
  final d = state.diagnostic;
  if (objective == null || d == null) return state;
  final chapters = planChapters(resources);
  final byId = {for (final c in chapters) c.id: c};
  final levels = d.method == DiagnosticMethod.test
      ? levelsFromTest([
          for (final id in d.testChapterIds) ?byId[id],
        ], d.testAnswers)
      : d.topics;
  final done = d.copyWith(topics: levels, finished: true);
  return state.copyWith(
    diagnostic: done,
    studyPlan: generateStudyPlan(
      chapters: chapters,
      levels: levels,
      completedLessons: state.completedLessons,
      time: state.plan,
      objective: objective,
      today: today,
    ),
  );
}

/// Ajustar ou replanejar: refaz as semanas de hoje com o que já foi feito.
TrainingState replan(
  TrainingState state,
  TrainingResources resources,
  String today,
) {
  final objective = state.objective;
  if (objective == null) return state;
  final levels = state.diagnostic?.topics ?? const <String, TopicLevel>{};
  return state.copyWith(
    studyPlan: generateStudyPlan(
      chapters: planChapters(resources),
      levels: levels,
      completedLessons: state.completedLessons,
      time: state.plan,
      objective: objective,
      today: today,
    ),
    missedDayNoticeOn: null,
    missedDayMinutes: null,
  );
}

/// "Agora não" no capítulo atrasado: o plano não muda; só some a pergunta.
TrainingState dismissLate(TrainingState state, Iterable<String> keys) {
  final plan = state.studyPlan;
  if (plan == null) return state;
  return state.copyWith(
    studyPlan: plan.copyWith(
      dismissedLate: {...plan.dismissedLate, ...keys}.toList(),
    ),
  );
}

/// Marca o dia de hoje como estudado (usado ao fechar as metas).
TrainingState markStudied(TrainingState state, String date) =>
    state.studiedDates.contains(date)
    ? state
    : state.copyWith(studiedDates: [...state.studiedDates, date]);

/// Dia perdido: guarda o aviso do dia e os minutos novos (H-TRE-11).
TrainingState noteMissedDay(TrainingState state, String today, int minutes) =>
    state.missedDayNoticeOn == today && state.missedDayMinutes == minutes
    ? state
    : state.copyWith(missedDayNoticeOn: today, missedDayMinutes: minutes);

TrainingState clearMissedNotice(TrainingState state) =>
    state.missedDayNoticeOn == null
    ? state
    : state.copyWith(missedDayNoticeOn: null, missedDayMinutes: null);

/// Confirma aumentar o tempo por dia.
TrainingState confirmMoreTime(TrainingState state, int minutes) =>
    clearMissedNotice(
      state.copyWith(plan: state.plan.copyWith(minutes: minutes)),
    );

/// "Continuar com X por dia": o último capítulo vai para depois do torneio.
TrainingState confirmKeepTime(
  TrainingState state,
  TrainingResources resources,
  String today,
) {
  final plan = state.studyPlan;
  final objective = state.objective;
  if (plan == null || objective?.tournamentDate == null) {
    return clearMissedNotice(state);
  }
  final byId = {for (final c in planChapters(resources)) c.id: c};
  final left = {
    for (final id in plan.chapterIds)
      if (byId[id] != null)
        id: chapterProgress(byId[id]!, state.completedLessons).minutesLeft,
  };
  final open = [
    for (final id in plan.chapterIds)
      if ((left[id] ?? 0) > 0) id,
  ];
  final fit = fitPlanToMinutes(
    chapterIds: open,
    minutesLeft: left,
    plan: state.plan,
    today: today,
    tournamentDate: objective!.tournamentDate!,
  );
  final dropped = fit.dropped.toSet();
  return clearMissedNotice(
    state.copyWith(
      studyPlan: plan.copyWith(
        chapterIds: [
          for (final id in plan.chapterIds)
            if (!dropped.contains(id)) id,
        ],
        deferredIds: [...dropped, ...plan.deferredIds],
        weeks: [
          for (final w in plan.weeks)
            PlanWeek(
              start: w.start,
              end: w.end,
              review: w.review,
              chapterIds: [
                for (final id in w.chapterIds)
                  if (!dropped.contains(id)) id,
              ],
            ),
        ],
      ),
    ),
  );
}

/// Rascunho do registro do torneio (G20): grava a cada campo.
TrainingState saveTournamentDraft(TrainingState state, TournamentDraft draft) =>
    state.copyWith(tournamentDraft: draft);

/// Registro: sem pontos e rodadas válidos não grava. O registro não muda o plano (G4).
TrainingState? registerTournament(
  TrainingState state,
  TournamentDraft draft,
  String id,
) {
  final record = recordFromDraft(draft, id);
  if (record == null) return null;
  return state.copyWith(
    tournaments: [record, ...state.tournaments],
    tournamentDraft: null,
    tournamentPushFor: null,
  );
}

/// Erro do campo do rascunho, ou null quando pode gravar.
enum DraftError { points, rounds, pointsTooHigh }

DraftError? draftError(TournamentDraft draft) {
  final points = parseTenths(draft.points);
  final rounds = int.tryParse(draft.rounds.trim());
  if (points == null) return DraftError.points;
  if (rounds == null || rounds <= 0) return DraftError.rounds;
  if (points > rounds * 10) return DraftError.pointsTooHigh;
  return null;
}

TournamentRecord? recordFromDraft(TournamentDraft draft, String id) {
  if (draftError(draft) != null) return null;
  return TournamentRecord(
    id: id,
    name: draft.name.trim(),
    date: draft.date,
    tenthsPoints: parseTenths(draft.points)!,
    rounds: int.parse(draft.rounds.trim()),
    ratingBefore: int.tryParse(draft.ratingBefore.trim()),
    ratingAfter: int.tryParse(draft.ratingAfter.trim()),
    pace: draft.pace,
    entity: draft.entity,
    feeling: draft.feeling,
    notes: draft.notes.trim(),
  );
}

/// "4,5" ou "4.5" viram 45; só meios pontos (",0" ou ",5").
int? parseTenths(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final value = double.tryParse(t);
  if (value == null || value < 0) return null;
  final tenths = (value * 10).round();
  return tenths % 5 == 0 ? tenths : null;
}

/// Rascunho inicial do plano: nome e data do torneio já preenchidos.
TournamentDraft draftFromObjective(TrainingObjective? objective, String today) {
  if (objective == null || !objective.hasTournament) {
    return TournamentDraft(date: today);
  }
  return TournamentDraft(
    name: objective.tournamentName,
    date: objective.tournamentDate!,
  );
}

/// Dia seguinte ao torneio: o push local sai às 9h (G19).
String tournamentPushDay(String tournamentDate) => addDays(tournamentDate, 1);
