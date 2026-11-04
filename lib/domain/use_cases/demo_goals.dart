import '../models/training/day_goals.dart';
import '../models/training/training_course.dart';
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
}
