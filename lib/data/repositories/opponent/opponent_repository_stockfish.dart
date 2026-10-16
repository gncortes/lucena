import 'package:dartchess/dartchess.dart';

import '../../../domain/models/clock.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/use_cases/pick_testing_move.dart';
import '../../services/stockfish_service.dart';
import '../analysis/analysis_repository.dart';
import '../analysis/analysis_repository_stockfish.dart';
import 'opponent_repository.dart';

/// O Stockfish na força máxima. Em final empatado escolhe, entre os lances
/// que seguram o empate, o que dá mais trabalho ao aluno ([PickTestingMove]);
/// no resto joga o melhor lance do motor.
class StockfishOpponentRepository implements OpponentRepository {
  StockfishOpponentRepository(this._stockfish, {AnalysisRepository? analysis})
    : _analysis = analysis ?? StockfishAnalysisRepository(_stockfish);

  final StockfishService _stockfish;
  final AnalysisRepository _analysis;

  @override
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.stockfish,
    int? level,
    List<Position> history = const [],
    TimeControl? time,
  }) async {
    final testing = await _testingMove(position, thinkTime);
    if (testing != null) return testing;
    final uci = await _stockfish.bestMove(position.fen, thinkTime);
    if (uci == null) return null;
    final move = Move.parse(uci);
    // O lance vem do motor; o app só joga lance legal.
    return move != null && position.isLegal(move) ? move : null;
  }

  /// O lance que mais complica o empate, ou nulo (jogo normal, motor sem
  /// resposta ou qualquer falha: segue o melhor lance).
  Future<Move?> _testingMove(Position position, Duration thinkTime) async {
    try {
      final uci = await PickTestingMove(
        (position, {required lines, required deep}) => _analysis.analyse(
          position,
          depth: deep ? 16 : 12,
          lines: lines,
          time: deep ? thinkTime : thinkTime ~/ 3,
        ),
      ).pick(position);
      final move = uci == null ? null : Move.parse(uci);
      return move != null && position.isLegal(move) ? move : null;
    } on Object {
      return null;
    }
  }
}
