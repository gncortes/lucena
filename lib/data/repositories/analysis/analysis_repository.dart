import 'package:dartchess/dartchess.dart';

import '../../../domain/models/game_review.dart';

/// A engine analisando posições para a revisão da partida.
abstract class AnalysisRepository {
  /// As [lines] melhores linhas em [position], com profundidade [depth],
  /// do ponto de vista das brancas. Lista vazia se a engine não respondeu ou
  /// a posição não tem lance.
  Future<List<EngineLine>> analyse(
    Position position, {
    required int depth,
    int lines = 1,
  });
}
