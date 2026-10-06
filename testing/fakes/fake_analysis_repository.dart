import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/analysis/analysis_repository.dart';
import 'package:lucena/domain/models/game_review.dart';

/// Uma engine de mentira, determinística: avalia pelo material (100 por
/// peão, do ponto de vista das brancas) e sugere os lances legais em ordem
/// alfabética (UCI). [answer] troca a resposta de uma posição (FEN).
class FakeAnalysisRepository implements AnalysisRepository {
  final requests = <String>[];
  final answer = <String, List<EngineLine>>{};

  @override
  Future<List<EngineLine>> analyse(
    Position position, {
    required int depth,
    int lines = 1,
    bool urgent = false,
  }) async {
    requests.add(position.fen);
    final fixed = answer[position.fen];
    if (fixed != null) return fixed.take(lines).toList();
    final moves = [
      for (final MapEntry(key: from, value: targets)
          in position.legalMoves.entries)
        for (final to in targets.squares) NormalMove(from: from, to: to).uci,
    ]..sort();
    final score = EngineScore(centipawns: _material(position.board));
    return [
      for (final move in moves.take(lines))
        EngineLine(score: score, moves: [move]),
    ];
  }

  static int _material(Board board) {
    const values = {
      Role.pawn: 100,
      Role.knight: 300,
      Role.bishop: 300,
      Role.rook: 500,
      Role.queen: 900,
      Role.king: 0,
    };
    var total = 0;
    for (final (_, piece) in board.pieces) {
      final value = values[piece.role]!;
      total += piece.color == Side.white ? value : -value;
    }
    return total;
  }
}
