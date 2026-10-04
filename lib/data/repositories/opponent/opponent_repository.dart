import 'package:dartchess/dartchess.dart';

import '../../../domain/models/game_setup.dart';

/// O adversário que escolhe os lances da máquina.
abstract class OpponentRepository {
  /// O lance da máquina em [position], dispondo de [thinkTime]. Nulo se não
  /// há lance (a partida já acabou).
  ///
  /// [kind] diz quem joga (Maia ou Stockfish) e [level], o nível do Maia.
  /// [history] são as posições da partida até [position], da mais antiga para
  /// a atual: o Maia joga olhando também as anteriores.
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.stockfish,
    int? level,
    List<Position> history = const [],
  });
}
