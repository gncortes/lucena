import '../models/survey.dart';

/// Regras do questionário "Sua opinião".
abstract final class SurveyRules {
  /// Quantos passos tem o questionário de [kind].
  static int totalSteps(SurveyKind kind) => switch (kind) {
    SurveyKind.endgames => 2,
    SurveyKind.school => 3,
  };

  /// Se dá para sair do passo [step] (a partir de 0): só a nota (passo 1) e o
  /// interesse (passo 2) são obrigatórios; o resto é opcional.
  static bool canAdvance(SurveyKind kind, int step, SurveyAnswers answers) =>
      switch (step) {
        0 => answers.rating != null,
        1 => answers.interest != null,
        _ => true,
      };

  /// O convite aparece enquanto não há resposta enviada daquele questionário.
  static bool shouldInvite({required bool hasResponse}) => !hasResponse;
}
