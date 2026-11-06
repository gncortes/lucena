import '../../../models/training/goal/goal_undo.dart';
import '../../../models/training/goal/study_plan.dart';
import '../../../models/training/goal/tournament_record.dart';
import '../../../models/training/goal/training_diagnostic.dart';
import '../../../models/training/goal/training_objective.dart';
import '../../../models/training/training_resources.dart';
import '../../../models/training/training_state.dart';
import 'diagnostic_test_size.dart';
import 'generate_study_plan.dart';
import 'goal_limits.dart';
import 'plan_chapters.dart';
import 'plan_status.dart';
import 'tournament_rules.dart';

/// Funções puras `TrainingState -> TrainingState` do treino por meta. O
/// repositório aplica cada uma dentro de uma transação, então cada resposta
/// fica salva antes de a tela seguir (fechar à força não perde nada).

/// Novo objetivo: o anterior vai para o histórico e o plano recomeça. A mesma
/// escolha não grava (G3); só o nome novo não refaz o plano (G5). Trocar um
/// objetivo guarda a cópia para o "Desfazer" (G2).
TrainingState applyObjective(TrainingState state, TrainingObjective objective) {
  final next = objective.copyWith(
    tournamentName: objective.hasTournament
        ? clampText(objective.tournamentName, maxTournamentName)
        : '',
  );
  final previous = state.objective;
  if (previous != null &&
      previous.kind == next.kind &&
      previous.tournamentDate == next.tournamentDate) {
    return renameObjective(state, next.tournamentName);
  }
  return _leaveObjective(
    state,
    next,
    previous == null ? null : UndoKind.objectiveChanged,
  );
}

/// "Ficar sem objetivo" (G1): sai objetivo e plano; registros, rascunho e o
/// teste de nível concluído ficam (Pergunta 3).
TrainingState clearObjective(TrainingState state) => state.objective == null
    ? state
    : _leaveObjective(state, null, UndoKind.objectiveRemoved);

TrainingState _leaveObjective(
  TrainingState state,
  TrainingObjective? next,
  UndoKind? undo,
) {
  final previous = state.objective;
  final diagnostic = state.diagnostic;
  return state.copyWith(
    objective: next,
    objectiveHistory: [
      ?previous,
      ...state.objectiveHistory,
    ].take(maxObjectiveHistory).toList(),
    studyPlan: null,
    previousStudyPlan: null,
    diagnostic: diagnostic != null && diagnostic.finished ? diagnostic : null,
    tournamentPushFor: null,
    undoSlot: undo == null ? null : _snapshot(state, undo),
    objectiveDraft: null,
  );
}

/// Muda só o nome do torneio: o plano fica e o lembrete é refeito com o nome.
TrainingState renameObjective(TrainingState state, String name) {
  final objective = state.objective;
  final clean = state.objectiveDraft == null
      ? state
      : state.copyWith(objectiveDraft: null);
  if (objective == null || !objective.hasTournament) return clean;
  final next = clampText(name, maxTournamentName);
  if (next == objective.tournamentName) return clean;
  return clean.copyWith(
    objective: objective.copyWith(tournamentName: next),
    tournamentPushFor: null,
    undoSlot: null,
  );
}

GoalUndoSlot _snapshot(TrainingState state, UndoKind kind) => GoalUndoSlot(
  kind: kind,
  objective: state.objective,
  objectiveHistory: state.objectiveHistory,
  studyPlan: state.studyPlan,
  previousStudyPlan: state.previousStudyPlan,
  diagnostic: state.diagnostic,
  tournamentPushFor: state.tournamentPushFor,
  tournaments: state.tournaments,
);

/// "Desfazer": devolve o que a última troca de objetivo ou mexida num registro
/// mudou. A cópia some depois de usada.
TrainingState undoLast(TrainingState state) {
  final undo = state.undoSlot;
  if (undo == null) return state;
  return switch (undo.kind) {
    UndoKind.objectiveRemoved || UndoKind.objectiveChanged => state.copyWith(
      objective: undo.objective,
      objectiveHistory: undo.objectiveHistory,
      studyPlan: undo.studyPlan,
      previousStudyPlan: undo.previousStudyPlan,
      diagnostic: undo.diagnostic,
      tournamentPushFor: undo.tournamentPushFor,
      undoSlot: null,
    ),
    UndoKind.tournamentEdited || UndoKind.tournamentDeleted => state.copyWith(
      tournaments: undo.tournaments,
      tournamentPushFor: undo.tournamentPushFor,
      undoSlot: null,
    ),
  };
}

/// Guarda a escolha de "Seu objetivo" ainda não salva.
TrainingState saveObjectiveDraft(TrainingState state, ObjectiveDraft draft) =>
    state.copyWith(
      objectiveDraft: ObjectiveDraft(
        kind: draft.kind,
        date: draft.date,
        name: clampText(draft.name, maxTournamentName),
      ),
    );

TrainingState clearObjectiveDraft(TrainingState state) =>
    state.objectiveDraft == null ? state : state.copyWith(objectiveDraft: null);

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
    previousStudyPlan: state.studyPlan,
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

/// "Voltar ao plano anterior": desfaz o último ajuste (H-TRE-09).
TrainingState undoAdjust(TrainingState state) {
  final previous = state.previousStudyPlan;
  if (previous == null) return state;
  return state.copyWith(studyPlan: previous, previousStudyPlan: null);
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
      previousStudyPlan: plan,
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

/// "Descartar" o rascunho do registro (G8): reabrir vem vazio.
TrainingState discardTournamentDraft(TrainingState state) =>
    state.tournamentDraft == null
    ? state
    : state.copyWith(tournamentDraft: null);

/// Registro: sem pontos e rodadas válidos não grava. O registro não muda o plano
/// (G4). Com 100 registros no curso, recusa sem apagar nenhum antigo (§8).
TrainingState? registerTournament(
  TrainingState state,
  TournamentDraft draft,
  String id, {
  String? today,
}) {
  if (state.tournaments.length >= maxTournaments) return null;
  final record = recordFromDraft(draft, id, today: today);
  if (record == null) return null;
  return state.copyWith(
    tournaments: [record, ...state.tournaments],
    tournamentDraft: null,
    tournamentPushFor: null,
    undoSlot: null,
  );
}

/// Corrige um registro (G7): mesmo id e posição; guarda a cópia do desfazer.
TrainingState? editTournament(
  TrainingState state,
  String id,
  TournamentDraft draft, {
  String? today,
}) {
  final index = state.tournaments.indexWhere((t) => t.id == id);
  if (index < 0) return null;
  final record = recordFromDraft(draft, id, today: today);
  if (record == null) return null;
  return state.copyWith(
    tournaments: [...state.tournaments]..[index] = record,
    tournamentEdit: null,
    tournamentPushFor: null,
    undoSlot: _snapshot(state, UndoKind.tournamentEdited),
  );
}

/// Apaga um registro (G7); null se o id não existe.
TrainingState? deleteTournament(TrainingState state, String id) {
  if (!state.tournaments.any((t) => t.id == id)) return null;
  return state.copyWith(
    tournaments: [
      for (final t in state.tournaments)
        if (t.id != id) t,
    ],
    tournamentEdit: state.tournamentEdit?.id == id
        ? null
        : state.tournamentEdit,
    tournamentPushFor: null,
    undoSlot: _snapshot(state, UndoKind.tournamentDeleted),
  );
}

/// Grava a edição em andamento de um registro a cada campo.
TrainingState saveTournamentEdit(
  TrainingState state,
  String id,
  TournamentDraft draft,
) => state.copyWith(
  tournamentEdit: TournamentEdit(id: id, draft: draft),
);

TrainingState discardTournamentEdit(TrainingState state) =>
    state.tournamentEdit == null ? state : state.copyWith(tournamentEdit: null);

/// Rascunho com os campos de um registro salvo, como o aluno digitaria.
TournamentDraft draftFromRecord(TournamentRecord r) => TournamentDraft(
  name: r.name,
  date: r.date,
  points: formatTenths(r.tenthsPoints),
  rounds: '${r.rounds}',
  ratingBefore: r.ratingBefore?.toString() ?? '',
  ratingAfter: r.ratingAfter?.toString() ?? '',
  pace: r.pace,
  entity: r.entity,
  feeling: r.feeling,
  notes: r.notes,
);

/// 35 vira "3,5"; 40 vira "4".
String formatTenths(int tenths) =>
    tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths ~/ 10},${tenths % 10}';

/// Erro do campo do rascunho, ou null quando pode gravar. A data só é conferida
/// com [today]: de 2 anos atrás até hoje (G6).
enum DraftError { points, rounds, roundsTooMany, pointsTooHigh, date }

DraftError? draftError(TournamentDraft draft, {String? today}) {
  final points = parseTenths(draft.points);
  final rounds = int.tryParse(draft.rounds.trim());
  if (points == null) return DraftError.points;
  if (rounds == null || rounds <= 0) return DraftError.rounds;
  if (rounds > maxTournamentRounds) return DraftError.roundsTooMany;
  if (points > rounds * 10) return DraftError.pointsTooHigh;
  if (today != null && !isValidRegisterDate(draft.date, today)) {
    return DraftError.date;
  }
  return null;
}

TournamentRecord? recordFromDraft(
  TournamentDraft draft,
  String id, {
  String? today,
}) {
  if (draftError(draft, today: today) != null) return null;
  return TournamentRecord(
    id: id,
    name: clampText(draft.name, maxTournamentName),
    date: draft.date,
    tenthsPoints: parseTenths(draft.points)!,
    rounds: int.parse(draft.rounds.trim()),
    ratingBefore: int.tryParse(draft.ratingBefore.trim()),
    ratingAfter: int.tryParse(draft.ratingAfter.trim()),
    pace: draft.pace,
    entity: draft.entity,
    feeling: draft.feeling,
    notes: clampText(draft.notes, maxTournamentNotes),
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

/// Rascunho inicial: nome e data do torneio do objetivo só depois que ele
/// passou; antes disso, a data de hoje e sem nome (G6).
TournamentDraft draftFromObjective(TrainingObjective? objective, String today) {
  if (objective == null ||
      !objective.hasTournament ||
      !canRegisterTournament(today, objective.tournamentDate!)) {
    return TournamentDraft(date: today);
  }
  return TournamentDraft(
    name: objective.tournamentName,
    date: objective.tournamentDate!,
  );
}

/// Dia seguinte ao torneio: o push local sai às 9h (G19).
String tournamentPushDay(String tournamentDate) => addDays(tournamentDate, 1);
