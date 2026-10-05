import 'package:dartchess/dartchess.dart';

import '../../../domain/models/clock.dart';
import '../../../domain/models/game_setup.dart';
import 'opponent_repository.dart';

/// Os adversários do aparelho: entrega cada pedido ao Maia ou ao Stockfish.
class DeviceOpponentRepository implements OpponentRepository {
  DeviceOpponentRepository({required this._maia, required this._stockfish});

  final OpponentRepository _maia;
  final OpponentRepository _stockfish;

  @override
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.stockfish,
    int? level,
    List<Position> history = const [],
    TimeControl? time,
  }) {
    final engine = kind == OpponentKind.maia ? _maia : _stockfish;
    return engine.pickMove(
      position,
      thinkTime: thinkTime,
      kind: kind,
      level: level,
      history: history,
      time: time,
    );
  }
}
