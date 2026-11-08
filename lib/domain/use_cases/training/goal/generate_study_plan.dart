import '../../../models/training/goal/study_plan.dart';
import '../../../models/training/goal/training_diagnostic.dart';
import '../../../models/training/goal/training_objective.dart';
import '../../../models/training/training_plan.dart';
import 'plan_chapters.dart';
import 'tournament_rules.dart';

/// Monta o plano por capítulos inteiros (H-TRE-07).
///
/// - Capítulo já concluído e tema "Domino" ficam fora; o que o aluno já fez continua contando.
/// - "Aprendendo" entra primeiro; "Praticando" só entra se couber no prazo.
/// - Com torneio: semanas de 7 dias a partir de [today]; a última é só revisão
///   (a partir de 3 semanas; com 1 dia, o plano todo é revisão). O que não cabe vai
///   para depois do torneio. Sem torneio: fila na ordem do curso.
StudyPlan generateStudyPlan({
  required List<PlanChapter> chapters,
  required Map<String, TopicLevel> levels,
  required Map<String, String> completedLessons,
  required TrainingPlan time,
  required TrainingObjective objective,
  required String today,
}) {
  TopicLevel levelOf(PlanChapter c) => levels[c.partId] ?? TopicLevel.learning;
  final open = [
    for (final c in chapters)
      if (!chapterProgress(c, completedLessons).complete) c,
  ];
  final candidates = [
    for (final c in open)
      if (levelOf(c) != TopicLevel.mastered) c,
  ];
  if (!objective.hasTournament) {
    return StudyPlan(
      createdOn: today,
      chapterIds: [for (final c in candidates) c.id],
    );
  }
  final end = objective.tournamentDate!;
  final totalDays = daysUntil(today, end);
  final windows = <(String, String)>[];
  for (var d = today; d.compareTo(end) <= 0; d = addDays(d, 7)) {
    final last = addDays(d, 6);
    windows.add((d, last.compareTo(end) > 0 ? end : last));
  }
  if (windows.isEmpty) windows.add((end, end));
  final reviewLast = totalDays <= 1 || windows.length >= 3;
  final studyWindows = reviewLast
      ? windows.take(windows.length - 1).toList()
      : windows;
  int capacity((String, String) w) =>
      studyDaysBetween(
        time,
        w.$1,
        w.$2.compareTo(end) >= 0 ? end : addDays(w.$2, 1),
      ) *
      time.minutes;
  final caps = [for (final w in studyWindows) capacity(w)];
  final total = caps.fold<int>(0, (a, b) => a + b);

  final chosen = <String>{};
  var used = 0;
  for (final level in [TopicLevel.learning, TopicLevel.practicing]) {
    for (final c in candidates.where((c) => levelOf(c) == level)) {
      final cost = chapterProgress(c, completedLessons).minutesLeft;
      if (used + cost <= total) {
        chosen.add(c.id);
        used += cost;
      }
    }
  }
  final selected = [
    for (final c in candidates)
      if (chosen.contains(c.id)) c,
  ];
  final byWeek = List.generate(studyWindows.length, (_) => <String>[]);
  if (byWeek.isNotEmpty) {
    var week = 0;
    var remaining = caps[0];
    for (final c in selected) {
      final cost = chapterProgress(c, completedLessons).minutesLeft;
      while (week < byWeek.length - 1 &&
          remaining < cost &&
          remaining < caps[week]) {
        week++;
        remaining = caps[week];
      }
      byWeek[week].add(c.id);
      remaining -= cost;
    }
  }
  final weeks = [
    for (final (i, w) in studyWindows.indexed)
      PlanWeek(start: w.$1, end: w.$2, chapterIds: byWeek[i]),
    if (reviewLast)
      PlanWeek(start: windows.last.$1, end: windows.last.$2, review: true),
  ];
  return StudyPlan(
    createdOn: today,
    weeks: weeks,
    chapterIds: [for (final c in selected) c.id],
    deferredIds: [
      for (final c in candidates)
        if (!chosen.contains(c.id)) c.id,
    ],
  );
}
