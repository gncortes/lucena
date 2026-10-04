import 'package:dartchess/dartchess.dart';

/// O adversário que escolhe os lances da máquina.
abstract class OpponentRepository {
  /// O lance da máquina em [position], pensando [thinkTime]. Nulo se não há
  /// lance (a partida já acabou).
  Future<Move?> pickMove(Position position, {required Duration thinkTime});
}
