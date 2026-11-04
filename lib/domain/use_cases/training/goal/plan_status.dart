import '../../../models/training/goal/study_plan.dart';
import '../../../models/training/training_plan.dart';
import '../../../models/training/training_resources.dart';
import '../../../models/training/training_state.dart';
import '../training_date.dart';
import 'plan_chapters.dart';
import 'tournament_rules.dart';

/// Índice da semana que contém [today] (antes do início = 0; depois do fim = última).
int currentWeekIndex(StudyPlan plan, String today) {
  if (plan.weeks.isEmpty) return 0;
  for (final (i, w) in plan.weeks.indexed) {
    if (today.compareTo(w.end) <= 0) return i;
  }
  return plan.weeks.length - 1;
}

/// Capítulos atrasados: de semanas que já passaram e ainda não concluídos (H-TRE-09).
List<String> lateChapterIds(
  StudyPlan plan,
  Map<String, PlanChapter> chapters,
  Map<String, String> completed,
  String today,
) => [
  for (final w in plan.weeks)
    if (w.end.compareTo(today) < 0)
      for (final id in w.chapterIds)
        if (chapters[id] != null &&
            !chapterProgress(chapters[id]!, completed).complete)
          id,
];

String lateKey(String chapterId, int week) => '$chapterId@$week';

/// Sequência de dias de estudo cumpridos, contando só os dias marcados no plano.
int studyStreak(TrainingState state, String today) {
  final done = {
    ...state.studiedDates,
    if (state.day?.allDone == true) state.day!.date,
  };
  var d = today;
  var count = 0;
  var skippedToday = false;
  for (var i = 0; i < 400; i++) {
    final studies = state.plan.studiesOn(civilDate(d));
    if (studies) {
      if (done.contains(d)) {
        count++;
      } else if (d == today && !skippedToday) {
        skippedToday = true;
      } else {
        break;
      }
    }
    d = addDays(d, -1);
  }
  return count;
}

/// Último dia de estudo antes de [today] sem meta cumprida, se houve (H-TRE-11).
/// Só vale depois de o plano existir: dias anteriores a [since] não contam.
String? missedStudyDay(
  TrainingState state,
  String today, {
  required String since,
}) {
  final done = {...state.studiedDates};
  var d = addDays(today, -1);
  for (var i = 0; i < 7; i++) {
    if (d.compareTo(since) <= 0) return null;
    if (state.plan.studiesOn(civilDate(d))) {
      return done.contains(d) ? null : d;
    }
    d = addDays(d, -1);
  }
  return null;
}

/// Minutos por dia que o plano pede agora para fechar o que falta até [tournamentDate],
/// em múltiplos de 5.
int minutesPerDayNeeded({
  required int minutesLeft,
  required TrainingPlan plan,
  required String today,
  required String tournamentDate,
}) {
  final days = studyDaysBetween(plan, today, tournamentDate);
  if (days <= 0) return minutesLeft;
  return ((minutesLeft / days) / 5).ceil() * 5;
}

/// Tira os últimos capítulos do plano até caber em [minutesPerDay] (H-TRE-11). Devolve os que saíram.
({List<String> kept, List<String> dropped}) fitPlanToMinutes({
  required List<String> chapterIds,
  required Map<String, int> minutesLeft,
  required TrainingPlan plan,
  required String today,
  required String tournamentDate,
}) {
  final kept = [...chapterIds];
  final dropped = <String>[];
  while (kept.length > 1 &&
      minutesPerDayNeeded(
            minutesLeft: kept.fold(0, (a, id) => a + (minutesLeft[id] ?? 0)),
            plan: plan,
            today: today,
            tournamentDate: tournamentDate,
          ) >
          plan.minutes) {
    dropped.insert(0, kept.removeLast());
  }
  return (kept: kept, dropped: dropped);
}

/// Ordem em que as lições entram nas metas do dia (H-TRE-10): com plano,
/// primeiro os capítulos da semana atual, depois os das semanas seguintes e,
/// por fim, o resto do curso na ordem dele. Sem plano, a ordem do curso.
List<String> lessonOrderForPlan(
  TrainingState state,
  TrainingResources resources,
  String today,
) {
  final all = [for (final l in resources.lessons) l.id];
  final plan = state.studyPlan;
  if (plan == null) return all;
  final chapters = {for (final c in planChapters(resources)) c.id: c};
  final from = currentWeekIndex(plan, today);
  final ordered = <String>[];
  void add(String chapterId) {
    final chapter = chapters[chapterId];
    if (chapter == null) return;
    for (final id in chapter.allIds) {
      if (!ordered.contains(id)) ordered.add(id);
    }
  }

  if (plan.weeks.isEmpty) {
    plan.chapterIds.forEach(add);
  } else {
    for (final week in plan.weeks.skip(from)) {
      week.chapterIds.forEach(add);
    }
  }
  return [
    ...ordered,
    for (final id in all)
      if (!ordered.contains(id)) id,
  ];
}
