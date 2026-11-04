import '../../models/training/lesson_end.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import 'goal/goal_view.dart';
import 'goal/tournament_rules.dart';

/// Rótulo do capítulo ("Capítulo 8 · Recursos defensivos"); vem da tela, que
/// tem as traduções.
typedef ChapterLabel = String Function(int number, String title);

/// A meta do dia que aparece depois do último exercício do dia (H-LIC-50,
/// canvas `PropV2LicaoFimMetaDia`). Nulo quando não há o que mostrar: meta do
/// dia ainda aberta, aluno sem plano de estudo ou plano já todo concluído.
DayGoalSummary? dayGoalSummary(
  TrainingState state,
  TrainingResources resources,
  String today, {
  required ChapterLabel chapterLabel,
}) {
  if (state.day?.allDone != true) return null;
  final view = GoalView.of(state, resources, today);
  final plan = view.plan;
  final current = view.current;
  if (!view.hasPlan || plan == null || plan.weeks.isEmpty || current == null) {
    return null;
  }
  final week = view.weekIndex;
  final progress = view.progress(current);
  final planned = [
    for (final id in plan.chapterIds)
      if (view.chapter(id) case final c?) view.progress(c),
  ];
  return DayGoalSummary(
    week: week + 1,
    weekCount: plan.weeks.length,
    daysLeft: daysUntil(today, plan.weeks[week].end).clamp(0, 6),
    currentChapter: chapterLabel(view.chapterNumber(current.id), current.title),
    lessonsDone: progress.lessonsDone,
    lessonsTotal: progress.lessonsTotal,
    testPending:
        current.testId != null &&
        !progress.testDone &&
        progress.lessonsDone >= progress.lessonsTotal,
    chapterProgress: [
      for (final p in planned)
        p.chapter.itemCount == 0
            ? 1.0
            : ((p.lessonsDone + (p.testDone ? 1 : 0)) / p.chapter.itemCount),
    ],
    chaptersDone: planned.where((p) => p.complete).length,
  );
}

/// O resultado da lição para a oferta da demonstração (H-LIC-51, canvas
/// `PropV2LicaoFimDemoOferta`): número do capítulo e acertos do ciclo.
typedef DemoOfferFacts = ({int chapter, int correct, int total});

DemoOfferFacts? demoOfferFacts(
  TrainingState state,
  TrainingResources resources,
  String lessonId,
) {
  final view = GoalView.of(state, resources, '');
  final index = view.chapters.indexWhere((c) => c.lessonIds.contains(lessonId));
  final days = state.cycles[lessonId]?.days ?? const [];
  if (index < 0 || days.isEmpty) return null;
  return (
    chapter: index + 1,
    correct: days.where((d) => d.correct).length,
    total: days.length,
  );
}
