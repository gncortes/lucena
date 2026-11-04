import '../models/survey.dart';

/// Regras do questionário "Sua opinião".
abstract final class SurveyRules {
  /// Quantos passos tem o questionário de [kind].
  static int totalSteps(SurveyKind kind) => switch (kind) {
    SurveyKind.pilares => 2,
    SurveyKind.school => 3,
  };

  /// Se dá para sair do passo [step] (a partir de 0): a nota (passo 1) é
  /// obrigatória nos dois; o interesse (passo 2) só na Escola. O resto é
  /// opcional.
  static bool canAdvance(SurveyKind kind, int step, SurveyAnswers answers) =>
      switch ((kind, step)) {
        (_, 0) => answers.rating != null,
        (SurveyKind.school, 1) => answers.interest != null,
        _ => true,
      };

  /// "Quer rever?" vem com "Sim" marcado: sem resposta, vale "Sim".
  static bool reReviewOf(SurveyAnswers answers) => answers.reReview ?? true;

  /// O convite aparece enquanto não há resposta enviada daquele questionário.
  static bool shouldInvite({required bool hasResponse}) => !hasResponse;
}
