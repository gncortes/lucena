import 'package:dartchess/dartchess.dart';

import '../../../domain/models/move_prediction.dart';

/// As previsões do Maia para uma posição.
abstract class MaiaRepository {
  /// O que uma pessoa de rating [level] faria em [position], contra um
  /// oponente do mesmo rating.
  Future<MovePrediction> predict(Position position, {required int level});

  /// O que acontece em [position] entre quem joga, de rating [selfElo], e o
  /// oponente, de rating [oppoElo]. A chance de ganhar é de quem joga.
  Future<MovePrediction> predictMatch(
    Position position, {
    required int selfElo,
    required int oppoElo,
  });
}
