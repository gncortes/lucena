import 'package:dartchess/dartchess.dart';

import '../../../domain/models/wdl.dart';
import '../../../domain/use_cases/position_judge.dart';
import '../../services/stockfish_service.dart';

/// O juiz de reserva da tela de roteiro (T76): o Stockfish do app numa
/// profundidade fixa, para a posição que nem a tabela KPK nem a do roteiro
/// cobrem. Mate é vitória ou derrota; fora disso, vantagem acima de [limit]
/// centipeões. A profundidade e o limite saem da validação com a tablebase
/// (`tools/script_tables.py --validate`; em 15/10/2026, 600 finais de peões
/// de 4 a 7 peças: profundidade 20 e limite 150 erram 1, 16 erra 3, 12 erra
/// 28).
class StockfishJudgeRepository implements PositionJudge {
  StockfishJudgeRepository(this._stockfish);

  static const depth = 20;
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
