import 'package:dartchess/dartchess.dart';

import '../../../domain/models/game_review.dart';
import '../../services/stockfish_service.dart';
import 'analysis_repository.dart';

/// O Stockfish do aparelho analisando para a revisão.
class StockfishAnalysisRepository implements AnalysisRepository {
  StockfishAnalysisRepository(this._stockfish);

  final StockfishService _stockfish;

  @override
  Future<List<EngineLine>> analyse(
    Position position, {
    required int depth,
    int lines = 1,
  }) async {
    try {
      final found = await _stockfish.analyse(
        position.fen,
        depth: depth,
        lines: lines,
      );
      // O motor responde do ponto de vista de quem joga.
      final sign = position.turn == Side.white ? 1 : -1;
      return [
        for (final line in found)
          EngineLine(
            score: EngineScore(
              centipawns: line.centipawns == null
                  ? null
                  : line.centipawns! * sign,
              mate: line.mate == null ? null : line.mate! * sign,
            ),
            moves: line.moves,
          ),
      ];
    } on Object {
      return const [];
    }
  }
}
