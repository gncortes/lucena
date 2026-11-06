import '../../../models/training/goal/goal_undo.dart';
import '../../../models/training/goal/study_plan.dart';
import '../../../models/training/goal/tournament_record.dart';
import '../../../models/training/goal/training_objective.dart';
import '../../../models/training/training_resources.dart';
import '../../../models/training/training_state.dart';
import 'goal_actions.dart';
import 'goal_limits.dart';
import 'plan_chapters.dart';
import 'plan_status.dart';
import 'tournament_rules.dart';

/// Capítulo atrasado: o capítulo e a semana (1 a partir de 1) em que devia estar.
typedef LateChapter = ({PlanChapter chapter, int week});

/// O que salvar em "Seu objetivo" faz com o objetivo de agora.
enum ObjectiveChange {
  /// Mesma escolha: nada a gravar (G3).
  none,

  /// Primeiro objetivo: sem confirmação nem desfazer.
  first,

  /// Só o nome do torneio: o plano fica (G5).
  rename,

  /// Outro tipo ou outra data: o plano recomeça, com desfazer (G2).
  change,
}

/// Tudo o que as telas do treino por meta mostram, calculado do estado salvo
/// e do dia de hoje (Dart puro, sem relógio próprio).
final class GoalView {
  GoalView._({
    required this.today,
    required this.objective,
    required this.plan,
    required this.chapters,
    required this.state,
  }) : byId = {for (final c in chapters) c.id: c};

  factory GoalView.of(
    TrainingState state,
    TrainingResources resources,
    String today,
  ) => GoalView._(
    today: today,
    objective: state.objective,
    plan: state.studyPlan,
    chapters: planChapters(resources),
    state: state,
  );

  final String today;
  final TrainingObjective? objective;
  final StudyPlan? plan;
  final List<PlanChapter> chapters;
  final Map<String, PlanChapter> byId;
  final TrainingState state;

  bool get hasObjective => objective != null;
  bool get hasPlan => plan != null && objective != null;
  bool get hasTournament => objective?.hasTournament ?? false;
  String? get tournamentDate => objective?.tournamentDate;

  /// Dias até o torneio; zero no dia; negativo depois.
  int? get daysLeft => hasTournament ? daysUntil(today, tournamentDate!) : null;
  TournamentPhase? get phase =>
      hasTournament ? tournamentPhase(today, tournamentDate!) : null;

  /// Já passou o dia do torneio e ainda não há registro dele.
  bool get awaitingRegister =>
      hasTournament &&
      canRegisterTournament(today, tournamentDate!) &&
      !state.tournaments.any((t) => t.date == tournamentDate);

  bool get tournamentRegistered =>
      hasTournament && state.tournaments.any((t) => t.date == tournamentDate);

  String get tournamentName => objective?.tournamentName ?? '';

  PlanChapter? chapter(String id) => byId[id];

  int chapterNumber(String id) => chapters.indexWhere((c) => c.id == id) + 1;

  ChapterProgress progress(PlanChapter c) =>
      chapterProgress(c, state.completedLessons);

  /// Capítulos do plano ainda abertos, na ordem do plano.
  List<PlanChapter> get openChapters => [
    for (final id in plan?.chapterIds ?? const <String>[])
      if (byId[id] != null && !progress(byId[id]!).complete) byId[id]!,
  ];

  /// O capítulo da vez (primeiro aberto do plano).
  PlanChapter? get current => openChapters.firstOrNull;

  int get weekIndex => plan == null ? 0 : currentWeekIndex(plan!, today);

  /// Semana (índice) em que o capítulo foi posto.
  int? weekOf(String chapterId) {
    final weeks = plan?.weeks ?? const <PlanWeek>[];
    for (final (i, w) in weeks.indexed) {
      if (w.chapterIds.contains(chapterId)) return i;
    }
    return null;
  }

  /// Semana concluída: todos os capítulos prontos (e já passou ou é a atual).
  bool weekDone(PlanWeek w) =>
      !w.review &&
      w.chapterIds.isNotEmpty &&
      w.chapterIds.every(
        (id) => byId[id] != null && progress(byId[id]!).complete,
      );

  /// Capítulos atrasados que ainda não foram dispensados com "Agora não".
  List<LateChapter> get late {
    final p = plan;
    if (p == null || !hasTournament) return const [];
    return [
      for (final id in lateChapterIds(p, byId, state.completedLessons, today))
        if (!p.dismissedLate.contains(lateKey(id, weekOf(id)! + 1)))
          (chapter: byId[id]!, week: weekOf(id)! + 1),
    ];
  }

  int get streak => studyStreak(state, today);

  List<TournamentRecord> get tournaments => state.tournaments;

  /// Minutos que faltam no que o plano ainda tem.
  int get minutesLeft =>
      openChapters.fold(0, (a, c) => a + progress(c).minutesLeft);

  /// Dia perdido: o último dia de estudo previsto ficou sem meta (H-TRE-11).
  /// Só vale com torneio e plano e se o plano é anterior a esse dia.
  bool get missedDay =>
      hasPlan &&
      hasTournament &&
      phase == TournamentPhase.before &&
      missedStudyDay(state, today, since: plan!.createdOn) != null;

  /// Minutos por dia que o plano pede agora.
  int get minutesNeeded => minutesPerDayNeeded(
    minutesLeft: minutesLeft,
    plan: state.plan,
    today: today,
    tournamentDate: tournamentDate ?? today,
  );

  /// Aviso de dia perdido guardado para hoje (some ao confirmar ou fazer a meta).
  bool get missedNoticeActive => state.missedDayNoticeOn == today;

  /// O tempo necessário passa do que o aluno tem por dia: abre a folha.
  bool get needsMoreThanPlanned => minutesNeeded > state.plan.minutes;

  /// Capítulo que sai se o aluno mantiver o tempo (o último do plano que não cabe).
  PlanChapter? get chapterToDefer {
    if (!hasTournament || plan == null) return null;
    final left = {for (final c in openChapters) c.id: progress(c).minutesLeft};
    final fit = fitPlanToMinutes(
      chapterIds: [for (final c in openChapters) c.id],
      minutesLeft: left,
      plan: state.plan,
      today: today,
      tournamentDate: tournamentDate!,
    );
    return fit.dropped.isEmpty ? null : byId[fit.dropped.first];
  }

  /// Dias de estudo e horas totais até o torneio com o plano atual.
  int get minutesUntilTournament =>
      hasTournament ? studyMinutesUntil(state.plan, today, tournamentDate!) : 0;

  /// Rascunho pronto para o registro. Rascunho antigo com data fora do
  /// intervalo (futura, de antes da G6) volta com a data inicial de hoje.
  TournamentDraft get registerDraft {
    final initial = draftFromObjective(objective, today);
    final saved = state.tournamentDraft;
    if (saved == null) return initial;
    return isValidRegisterDate(saved.date, today)
        ? saved
        : saved.copyWith(date: initial.date);
  }

  // ---- Torneio como meta (contrato T85-torneio-meta) ----

  /// "Registrar torneio" na Guia (G6/G11): com "melhorar" e sem registros, ou
  /// depois do torneio do objetivo já registrado. Antes do torneio, não.
  bool get offersRegisterTournament {
    if (!hasObjective || tournamentsFull) return false;
    if (!hasTournament) return state.tournaments.isEmpty;
    return canRegisterTournament(today, tournamentDate!) &&
        tournamentRegistered;
  }

  /// 100 registros no curso: o registro novo é recusado (§8).
  bool get tournamentsFull => state.tournaments.length >= maxTournaments;

  /// Há "Desfazer" guardado (vale até a próxima ação de objetivo ou registro).
  bool get canUndo => state.undoSlot != null;
  UndoKind? get undoKind => state.undoSlot?.kind;

  /// O que "Seu objetivo" mostra ao abrir: a escolha não salva ou a atual (G3).
  ObjectiveDraft get objectiveChoice =>
      state.objectiveDraft ??
      ObjectiveDraft(
        kind: objective?.kind,
        date: objective?.tournamentDate,
        name: objective?.tournamentName ?? '',
      );

  ObjectiveChange changeFor({
    required ObjectiveKind kind,
    String? date,
    String name = '',
  }) {
    final current = objective;
    if (current == null) return ObjectiveChange.first;
    final tournament = kind == ObjectiveKind.tournament;
    if (current.kind != kind ||
        (tournament && current.tournamentDate != date)) {
      return ObjectiveChange.change;
    }
    if (tournament &&
        clampText(name, maxTournamentName) != current.tournamentName) {
      return ObjectiveChange.rename;
    }
    return ObjectiveChange.none;
  }

  /// Trocar com plano pede confirmação (o plano recomeça); sem plano, não.
  bool confirmChange({
    required ObjectiveKind kind,
    String? date,
    String name = '',
  }) =>
      hasPlan &&
      changeFor(kind: kind, date: date, name: name) == ObjectiveChange.change;

  /// "Ficar sem objetivo" com plano pede confirmação.
  bool get confirmRemove => hasPlan;

  /// Datas aceitas no registro: de 2 anos atrás até hoje.
  ({String first, String last}) get registerDates => registerDateRange(today);

  /// Rascunho da edição de um registro: o em andamento ou o registro salvo.
  TournamentDraft editDraft(String id) {
    final edit = state.tournamentEdit;
    if (edit != null && edit.id == id) return edit.draft;
    for (final t in state.tournaments) {
      if (t.id == id) return draftFromRecord(t);
    }
    return const TournamentDraft();
  }

  /// O rascunho mudou do inicial: fechar pede "Descartar" (G8).
  bool draftChanged(TournamentDraft draft) =>
      draft.toJson().toString() !=
      draftFromObjective(objective, today).toJson().toString();
}
