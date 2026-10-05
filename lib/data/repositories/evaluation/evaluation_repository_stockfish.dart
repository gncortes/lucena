import 'package:dartchess/dartchess.dart';

import '../../../domain/use_cases/position_assessment.dart';
import '../../services/stockfish_service.dart';
import 'evaluation_repository.dart';

/// O Stockfish do app, numa profundidade baixa: um cálculo rápido por lance
/// (`docs/arquitetura-gamificacao.md`, seção 7).
class StockfishEvaluationRepository implements EvaluationRepository {
  StockfishEvaluationRepository(this._stockfish);

  static const depth = 10;

  final StockfishService _stockfish;

  @override
  Future<Evaluation?> evaluate(Position position, {required Side pov}) async {
    final score = await _stockfish.evaluate(position.fen, depth: depth);
    if (score == null) return null;
    // O motor responde do ponto de vista de quem joga.
    final sign = position.turn == pov ? 1 : -1;
    final mate = score.mate;
    final centipawns = score.centipawns;
    return Evaluation(
      mate: mate == null ? null : mate * sign,
      centipawns: centipawns == null ? null : centipawns * sign,
    );
  }
}
