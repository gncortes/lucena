import '../../../models/training/goal/study_plan.dart';
import '../../../models/training/goal/tournament_record.dart';
import '../../../models/training/goal/training_objective.dart';
import '../../../models/training/training_resources.dart';
import '../../../models/training/training_state.dart';
import 'goal_actions.dart';
import 'plan_chapters.dart';
import 'plan_status.dart';
import 'tournament_rules.dart';

/// Capítulo atrasado: o capítulo e a semana (1 a partir de 1) em que devia estar.
typedef LateChapter = ({PlanChapter chapter, int week});

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

  /// Rascunho pronto para o registro.
  TournamentDraft get registerDraft =>
      state.tournamentDraft ?? draftFromObjective(objective, today);
}
