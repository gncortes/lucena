import 'package:dartchess/dartchess.dart';

import '../models/kpk_outcome.dart';
import 'kpk_oracle.dart';

/// O lance da máquina no jogo livre e na prática (T70), sempre pela tabela:
/// o atacante escolhe o lance ganhador de menor DTM; o defensor, o lance que
/// segura mais perto da casa à frente do peão e, se nenhum segura, o de maior
/// DTM. Empates de critério saem pela ordem alfabética do UCI.
abstract final class MachineMove {
  /// O lance em UCI, ou nulo se a máquina não tem lance (fim de partida).
  static String? choose(KpkOracle oracle, Position position) {
    final candidates = <({String uci, Position next, KpkOutcome outcome})>[];
    for (final MapEntry(key: from, value: targets)
        in position.legalMoves.entries) {
      for (final to in targets.squares) {
        final promotes =
            position.board.roleAt(from) == Role.pawn &&
            (to.rank == Rank.first || to.rank == Rank.eighth);
        final move = NormalMove(
          from: from,
          to: to,
          promotion: promotes ? Role.queen : null,
        );
        final next = position.playUnchecked(move);
        candidates.add((
          uci: move.uci,
          next: next,
          outcome: oracle.evaluate(next),
        ));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.uci.compareTo(b.uci));

    final pawn = position.board.pawns.first;
    final pawnSide = pawn == null ? null : position.board.sideAt(pawn);
    if (pawn == null || pawnSide == position.turn) {
      return _attack(candidates).uci;
    }
    final front = Square(pawn.value + (pawnSide == Side.white ? 8 : -8));
    return _defend(candidates, position.turn, front).uci;
  }

  static ({String uci, Position next, KpkOutcome outcome}) _attack(
    List<({String uci, Position next, KpkOutcome outcome})> all,
  ) {
    final wins = all.where((c) => c.outcome.isWin).toList();
    if (wins.isEmpty) {
      return all.firstWhere((c) => c.outcome.isDraw, orElse: () => all.first);
    }
    var best = wins.first;
    for (final c in wins) {
      if (c.outcome.dtm < best.outcome.dtm) best = c;
    }
    return best;
  }

  static ({String uci, Position next, KpkOutcome outcome}) _defend(
    List<({String uci, Position next, KpkOutcome outcome})> all,
    Side side,
    Square front,
  ) {
    final holds = all.where((c) => c.outcome.isDraw).toList();
    if (holds.isNotEmpty) {
      var best = holds.first;
      var bestDistance = _distance(best.next, side, front);
      for (final c in holds) {
        final distance = _distance(c.next, side, front);
        if (distance < bestDistance) {
          best = c;
          bestDistance = distance;
        }
      }
      return best;
    }
    final wins = all.where((c) => c.outcome.isWin).toList();
    if (wins.isEmpty) return all.first;
    var best = wins.first;
    for (final c in wins) {
      if (c.outcome.dtm > best.outcome.dtm) best = c;
    }
    return best;
  }

  /// A distância (de rei) do rei de [side] à casa [front]. Capturar o peão
  /// vale 0: é o melhor lance que há.
  static int _distance(Position next, Side side, Square front) {
    if (next.board.pawns.isEmpty) return -1;
    final king = next.board.kingOf(side);
    if (king == null) return 99;
    final files = (king.file - front.file).abs();
    final ranks = (king.rank - front.rank).abs();
    return files > ranks ? files : ranks;
  }
}
