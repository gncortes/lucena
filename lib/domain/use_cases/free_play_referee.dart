import 'package:dartchess/dartchess.dart';

import '../models/kpk_outcome.dart';
import 'game_rules.dart';

/// O árbitro do jogo livre e da prática (T70): diz se a partida acabou.
abstract final class FreePlayReferee {
  /// O fim de [fens] (as posições do jogo, da primeira à atual). [limit] é o
  /// limite em lances completos (cada um com um lance de cada lado). Nulo
  /// enquanto o jogo continua.
  ///
  /// Com [mate] (objetivo `mate`, sem peão em jogo), o fim é o xeque-mate, e
  /// não a falta de peão. Com mais de 3 peças, a coroação que ganha é julgada
  /// fora daqui (pelo juiz da tela, T76); sem peões e com mais de 3 peças, só
  /// mate, afogamento, repetição e limite fecham. Sem peões, a captura que
  /// deixa uma peça só fecha como [FreeEnd.material] (T78).
  static FreeEnd? check(
    List<String> fens, {
    required int limit,
    bool mate = false,
  }) {
    final current = GameRules.fromFen(fens.last);
    if (current == null) return null;
    if (mate) {
      if (current.isCheckmate) return FreeEnd.mate;
      if (current.isInsufficientMaterial) return FreeEnd.insuficiente;
    } else if (current.isCheckmate) {
      // Com vários peões, o mate pode vir antes da coroação (T76).
      return FreeEnd.mate;
    } else if (current.board.pawns.isEmpty &&
        current.board.occupied.size <= 3) {
      if (current.board.occupied.size <= 2) {
        // Só os reis: o peão caiu, ou a peça coroada foi capturada.
        final before = fens.length < 2
            ? null
            : GameRules.fromFen(fens[fens.length - 2]);
        return before == null || before.board.pawns.isNotEmpty
            ? FreeEnd.capturado
            : FreeEnd.insuficiente;
      }
      // A coroação (ou a peça que sobrou da captura) só fecha a partida se
      // ela não cai de graça no lance seguinte; senão, a partida segue.
      if (!hangingPromotion(current)) {
        final before = fens.length < 2
            ? null
            : GameRules.fromFen(fens[fens.length - 2]);
        if (before == null ||
            before.board.pawns.isNotEmpty ||
            before.board.occupied.size <= 3) {
          return FreeEnd.coroa;
        }
        // A captura que afoga, ou que deixa peça que não dá mate, empata.
        if (current.isStalemate) return FreeEnd.afogado;
        if (current.isInsufficientMaterial) return FreeEnd.insuficiente;
        return FreeEnd.material;
      }
    }
    if (current.isStalemate) return FreeEnd.afogado;
    if (!mate && current.isInsufficientMaterial) return FreeEnd.insuficiente;
    final key = _key(fens.last);
    if (fens.where((fen) => _key(fen) == key).length >= 3) {
      return FreeEnd.repeticao;
    }
    if (fens.length - 1 >= limit * 2) return FreeEnd.limite;
    return null;
  }

  /// A peça coroada (a única além dos reis) pode ser capturada pelo lado
  /// que joga agora.
  static bool hangingPromotion(Position position) {
    final board = position.board;
    if (board.pawns.isNotEmpty || board.occupied.size != 3) return false;
    final piece = board.occupied.squares.firstWhere(
      (sq) => board.roleAt(sq) != Role.king,
    );
    if (board.sideAt(piece) == position.turn) return false;
    for (final MapEntry(:value) in position.legalMoves.entries) {
      if (value.has(piece)) return true;
    }
    return false;
  }

  /// Peças, vez, roque e en passant: o que faz duas posições serem a mesma.
  static String _key(String fen) => fen.split(' ').take(4).join(' ');
}
