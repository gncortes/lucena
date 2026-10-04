import 'package:dartchess/dartchess.dart';

import '../../../domain/models/game_setup.dart';
import '../../services/stockfish_service.dart';
import 'opponent_repository.dart';

/// O Stockfish na força máxima.
class StockfishOpponentRepository implements OpponentRepository {
  StockfishOpponentRepository(this._stockfish);

  final StockfishService _stockfish;

  @override
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.stockfish,
    int? level,
    List<Position> history = const [],
  }) async {
    final uci = await _stockfish.bestMove(position.fen, thinkTime);
    if (uci == null) return null;
    final move = Move.parse(uci);
    // O lance vem do motor; o app só joga lance legal.
    return move != null && position.isLegal(move) ? move : null;
  }
}
