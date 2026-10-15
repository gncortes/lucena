import 'package:dartchess/dartchess.dart';

import '../models/kpk_outcome.dart';
import '../models/script_table.dart';
import '../models/wdl.dart';
import 'kpk_oracle.dart';

/// Quem diz se uma posição ganha, empata ou perde para quem joga (T76).
/// Nulo: não sabe (o lance é tratado como "mantém").
abstract interface class PositionJudge {
  Future<Wdl?> evaluate(Position position);
}

/// O juiz da tela de roteiro, em camadas: a tabela KPK (até 3 peças), a
/// tabela do roteiro (tablebase do Lichess, gerada offline) e, fora delas, o
/// motor ([engine], opcional). Mate, afogamento e material insuficiente
/// valem antes do motor.
class LayeredJudge implements PositionJudge {
  LayeredJudge(this._oracle, this._table, [this._engine]);

  final KpkOracle _oracle;
  final ScriptTable _table;
  final PositionJudge? _engine;

  @override
  Future<Wdl?> evaluate(Position position) async {
    final kpk = kpkWdl(_oracle.evaluate(position), position);
    if (kpk != null) return kpk;
    final known = _table.wdl(position.fen);
    if (known != null) return known;
    if (position.isCheckmate) return Wdl.loss;
    if (position.isStalemate || position.isInsufficientMaterial) {
      return Wdl.draw;
    }
    return _engine?.evaluate(position);
  }

  /// O resultado da tabela KPK do ponto de vista de quem joga: a vitória é
  /// do lado da peça que não é rei (o peão ou a peça coroada).
  static Wdl? kpkWdl(KpkOutcome outcome, Position position) {
    if (outcome.isOutside) return null;
    if (outcome.isDraw) return Wdl.draw;
    final board = position.board;
    final strong = board.occupied.squares
        .where((sq) => board.roleAt(sq) != Role.king)
        .map(board.sideAt)
        .firstOrNull;
    if (strong == null) return null;
    return strong == position.turn ? Wdl.win : Wdl.loss;
  }
}
