import '../models/would_pay.dart';

/// Quando oferecer o "Você pagaria?" e o que cada passo exige (E1.26).
abstract final class WouldPayRules {
  /// Curso, treinador e o passo 3.
  static const totalSteps = 3;

  /// O cartão aparece a partir da 2ª aula concluída (finais ou Escola).
  static const lessonsToInvite = 2;

  /// Oferece uma vez só: some com "Agora não" e depois de respondido.
  static bool shouldInvite({
    required int lessonsCompleted,
    required bool dismissed,
    required bool answered,
  }) => lessonsCompleted >= lessonsToInvite && !dismissed && !answered;

  /// As perguntas de sim/talvez/não e de faixa do [step] (a partir de 0)
  /// estão respondidas. No passo 3, só a "estrutura ensina?" é obrigatória;
  /// o próximo final, o porquê e o nível são opcionais.
  static bool canAdvance(int step, WouldPayAnswers answers) => switch (step) {
    0 => answers.course != null && answers.coursePrice != null,
    1 => answers.coach != null && answers.coachPrice != null,
    _ => answers.learn != null,
  };

  /// Todos os passos podem seguir: dá para enviar.
  static bool complete(WouldPayAnswers answers) =>
      [for (var step = 0; step < totalSteps; step++) canAdvance(step, answers)]
          .every((ok) => ok);
}
