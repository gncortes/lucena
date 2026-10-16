import 'package:dartchess/dartchess.dart';

import '../models/wdl.dart';
import 'kpk_oracle.dart';

/// O lance da máquina no jogo livre e na prática (T70), pela tabela KPK, com
/// a regra de resistência (T76, Gabriel: "sempre procurar os melhores lances
/// para dar resistência"), a mesma para o atacante e para o defensor:
///
/// 1. só os lances que mantêm o melhor resultado para a máquina (vitória, se
///    houver; senão empate; senão a derrota);
/// 2. entre eles, o mais exigente: o que deixa ao aluno mais respostas que
///    pioram o resultado dele;
/// 3. desempate: não entregar material (depois do lance, o aluno não tem
///    captura de peça que não seja rei);
/// 4. depois, o critério de antes: o atacante que ganha, o menor DTM; o
///    defensor que segura, o rei mais perto da casa à frente do peão
///    (capturar o peão vale mais); o defensor que perde, o maior DTM;
/// 5. por fim, a ordem alfabética do UCI.
///
/// A tabela do roteiro (mais de 3 peças) guarda o lance escolhido pela mesma
/// regra em `tools/script_tables.py`; `tools/machine_reply.dart` mostra a
/// resposta da máquina a cada erro de um roteiro.
abstract final class MachineMove {
  /// O lance em UCI, ou nulo se a máquina não tem lance (fim de partida).
  static String? choose(KpkOracle oracle, Position position) {
    final me = position.turn;
    final candidates = [
      for (final move in _moves(position))
        _Candidate.of(oracle, position, move, me),
    ];
    if (candidates.isEmpty) return null;

    final top = candidates.map((c) => c.mine.index).reduce(_min);
    final kept = [
      for (final c in candidates)
        if (c.mine.index == top) c,
    ];
    final front = _front(position);
    for (final c in kept) {
      c.demand = _demand(oracle, c.next, c.mine.flipped);
      c.hangs = _hangs(c.next, me);
      c.criterion = switch (c.mine) {
        // Vitória: a mais rápida.
        Wdl.win => c.dtm,
        // Empate: o rei perto da casa à frente do peão (só o defensor).
        Wdl.draw => front == null ? 0 : _distance(c.next, me, front),
        // Derrota: a mais longa.
        Wdl.loss => -c.dtm,
      };
    }
    kept.sort((a, b) {
      final demand = b.demand.compareTo(a.demand);
      if (demand != 0) return demand;
      final hangs = (a.hangs ? 1 : 0).compareTo(b.hangs ? 1 : 0);
      if (hangs != 0) return hangs;
      final criterion = a.criterion.compareTo(b.criterion);
      if (criterion != 0) return criterion;
      return a.uci.compareTo(b.uci);
    });
    return kept.first.uci;
  }

  static int _min(int a, int b) => a < b ? a : b;

  /// Os lances legais; a coroação é sempre em dama.
  static Iterable<NormalMove> _moves(Position position) sync* {
    for (final MapEntry(key: from, value: targets)
        in position.legalMoves.entries) {
      for (final to in targets.squares) {
        final promotes =
            position.board.roleAt(from) == Role.pawn &&
            (to.rank == Rank.first || to.rank == Rank.eighth);
        yield NormalMove(
          from: from,
          to: to,
          promotion: promotes ? Role.queen : null,
        );
      }
    }
  }

  /// O resultado de [position] para quem joga nela; a tabela KPK não sabe
  /// (rei contra rei, por exemplo): pelas regras, ou empate.
  static ({Wdl wdl, int dtm}) _evaluate(KpkOracle oracle, Position position) {
    if (position.isCheckmate) return (wdl: Wdl.loss, dtm: 0);
    final outcome = oracle.evaluate(position);
    if (outcome.isWin) {
      final strong = _strongSide(position);
      if (strong != null) {
        return (
          wdl: strong == position.turn ? Wdl.win : Wdl.loss,
          dtm: outcome.dtm,
        );
      }
    }
    return (wdl: Wdl.draw, dtm: 0);
  }

  /// O lado da peça que não é rei (o peão ou a peça coroada).
  static Side? _strongSide(Position position) {
    final board = position.board;
    return board.occupied.squares
        .where((sq) => board.roleAt(sq) != Role.king)
        .map(board.sideAt)
        .firstOrNull;
  }

  /// Quantas respostas do aluno em [next] deixam o resultado dele pior que
  /// [current] (o que ele tem em [next] jogando certo).
  static int _demand(KpkOracle oracle, Position next, Wdl current) {
    if (current == Wdl.loss) return 0;
    var count = 0;
    for (final reply in _moves(next)) {
      final after = next.playUnchecked(reply);
      final his = _evaluate(oracle, after).wdl.flipped;
      if (his.index > current.index) count++;
    }
    return count;
  }

  /// Depois do lance, o aluno (quem joga em [next]) captura uma peça de [me]
  /// que não é rei.
  static bool _hangs(Position next, Side me) {
    final board = next.board;
    final mine = board.bySide(me).diff(board.kings);
    for (final targets in next.legalMoves.values) {
      if (targets.intersect(mine).isNotEmpty) return true;
    }
    return false;
  }

  /// A casa à frente do peão quando quem joga defende; nulo se ataca. Depois
  /// da coroação, o lado sem a peça nova vale a1 (só a captura conta).
  static Square? _front(Position position) {
    final pawn = position.board.pawns.first;
    if (pawn == null) {
      final strong = _strongSide(position);
      return strong != null && strong != position.turn ? Square.a1 : null;
    }
    final pawnSide = position.board.sideAt(pawn);
    if (pawnSide == position.turn) return null;
    return Square(pawn.value + (pawnSide == Side.white ? 8 : -8));
  }

  /// A distância (de rei) do rei de [side] à casa [front]. Capturar o peão
  /// (ou a peça coroada) vale -1: é o melhor lance que há.
  static int _distance(Position next, Side side, Square front) {
    if (_strongSide(next) == null) return -1;
    final king = next.board.kingOf(side);
    if (king == null) return 99;
    final files = (king.file - front.file).abs();
    final ranks = (king.rank - front.rank).abs();
    return files > ranks ? files : ranks;
  }
}

class _Candidate {
  _Candidate(this.uci, this.next, this.mine, this.dtm);

  factory _Candidate.of(
    KpkOracle oracle,
    Position position,
    NormalMove move,
    Side me,
  ) {
    final next = position.playUnchecked(move);
    final value = MachineMove._evaluate(oracle, next);
    return _Candidate(move.uci, next, value.wdl.flipped, value.dtm);
  }

  final String uci;
  final Position next;

  /// O resultado para a máquina depois do lance.
  final Wdl mine;
  final int dtm;

  int demand = 0;
  bool hangs = false;
  int criterion = 0;
}
