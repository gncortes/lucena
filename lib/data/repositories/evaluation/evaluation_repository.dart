import 'package:dartchess/dartchess.dart';

import '../../../domain/use_cases/position_assessment.dart';

/// A avaliação da posição para os personagens. Nunca aparece na tela.
abstract class EvaluationRepository {
  /// A avaliação de [position] do ponto de vista de [pov]. Nula se o motor
  /// não respondeu.
  Future<Evaluation?> evaluate(Position position, {required Side pov});
}
