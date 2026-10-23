import '../models/attempt.dart';
import '../models/endgame_lesson.dart';
import '../models/lesson.dart';

/// Os contadores que o "Você pagaria?" e o pedido de avaliação olham
/// (E1.26), tirados do progresso que já existe.
abstract final class LessonCount {
  /// Aulas concluídas, da Escola e dos finais somadas.
  static int completed(SchoolProgress school, EndgameProgress endgames) =>
      school.completed.length +
      endgames.lessons.values.where((lesson) => lesson.lessonDone).length;

  /// Partidas de final ganhas.
  static int wins(Iterable<Attempt> attempts) =>
      attempts.where((attempt) => attempt.outcome == AttemptOutcome.win).length;
}
