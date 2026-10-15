import 'package:dartchess/dartchess.dart';

import '../../../domain/models/wdl.dart';
import '../../../domain/use_cases/position_judge.dart';
import '../../services/stockfish_service.dart';

/// O juiz de reserva da tela de roteiro (T76): o Stockfish do app numa
/// profundidade fixa, para a posição que nem a tabela KPK nem a do roteiro
/// cobrem. Mate é vitória ou derrota; fora disso, vantagem acima de [limit]
/// centipeões. A profundidade e o limite saem da validação de
/// `tools/script_tables.py --validate` (Stockfish × tablebase nas posições
/// das tabelas dos roteiros).
class StockfishJudgeRepository implements PositionJudge {
  StockfishJudgeRepository(this._stockfish);

  static const depth = 16;
  static const limit = 150;

  final StockfishService _stockfish;

  @override
  Future<Wdl?> evaluate(Position position) async {
    final ({int? centipawns, int? mate})? score;
    try {
      score = await _stockfish.evaluate(position.fen, depth: depth);
    } on Object {
      return null;
    }
    if (score == null) return null;
    final mate = score.mate;
    if (mate != null) return mate > 0 ? Wdl.win : Wdl.loss;
    final centipawns = score.centipawns;
    if (centipawns == null) return null;
    if (centipawns > limit) return Wdl.win;
    if (centipawns < -limit) return Wdl.loss;
    return Wdl.draw;
  }
}
