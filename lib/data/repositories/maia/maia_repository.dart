import 'package:dartchess/dartchess.dart';

import '../../../domain/models/move_prediction.dart';

/// As previsões do Maia para uma posição.
abstract class MaiaRepository {
  /// O que uma pessoa de rating [level] faria em [position], contra um
  /// oponente do mesmo rating.
  Future<MovePrediction> predict(Position position, {required int level});
}
