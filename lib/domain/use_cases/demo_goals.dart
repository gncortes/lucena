import '../models/course_access.dart';
import '../models/training/day_goals.dart';
import '../models/training/training_course.dart';
import '../models/training/training_resources.dart';
import '../models/training/training_state.dart';
import 'ad_policy.dart';

/// As metas na demonstração do Pilares (H-VEN-12): só as lições do
/// Capítulo 1 (o teste do capítulo entra, porque também é lição) ficam
/// abertas. Exercício, reforço, refazer, aberturas, estrelas e robôs vêm com
/// cadeado, porque fazem parte do curso completo.
abstract final class DemoGoals {
  static bool isLocked(TrainingGoal goal) =>
      (goal.kind != GoalKind.lesson && goal.kind != GoalKind.extraLesson) ||
      DemoAdPolicy.chapterOf(goal.ref) != 1;

  /// O que falta hoje sem contar as metas trancadas: é o número do selo da
  /// barra e do resumo "Hoje" na demo (1, ou 0 quando a lição do dia saiu).
  static ({int total, int remaining}) counts(TrainingState state) {
    final open = [...?state.day?.goals.where((goal) => !isLocked(goal))];
    return (
      total: open.length,
      remaining: open.where((goal) => !goal.done).length,
    );
  }

  /// O conteúdo do curso como o [access] de hoje o vê: só o Pilares tem
  /// demonstração; com o curso completo, nada fica trancado.
  static TrainingResources forAccess(
    TrainingCourse course,
    CourseAccess access,
    TrainingResources resources,
  ) => course == TrainingCourse.pilares && !access.hasFullCourse
      ? restrict(resources)
      : resources;

  /// O conteúdo como a demonstração o vê: as lições de fora do Capítulo 1
  /// ficam em [TrainingResources.lockedLessons], e a meta do dia as pula.
  static TrainingResources restrict(TrainingResources resources) =>
      resources.withLockedLessons([
        for (final lesson in resources.lessons)
          if (DemoAdPolicy.chapterOf(lesson.id) != 1) lesson.id,
      ]);

  /// Todas as lições publicadas do Capítulo 1 já feitas: na demo, a meta do
  /// dia fica sem lição e o resumo mostra "Capítulo 1 concluído".
  static bool chapterOneDone(TrainingState state, TrainingResources resources) {
    final chapter = [
      for (final lesson in resources.lessons)
        if (lesson.published && DemoAdPolicy.chapterOf(lesson.id) == 1) lesson,
    ];
    return chapter.isNotEmpty &&
        chapter.every((l) => state.completedLessons.containsKey(l.id));
  }
}
