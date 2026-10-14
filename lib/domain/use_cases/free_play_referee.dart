import '../models/kpk_outcome.dart';
import 'game_rules.dart';

/// O árbitro do jogo livre e da prática (T70): diz se a partida acabou.
abstract final class FreePlayReferee {
  /// O fim de [fens] (as posições do jogo, da primeira à atual). [limit] é o
  /// limite em lances completos (cada um com um lance de cada lado). Nulo
  /// enquanto o jogo continua.
  ///
  /// Com [mate] (objetivo `mate`, sem peão em jogo), o fim é o xeque-mate, e
  /// não a falta de peão.
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
    } else if (current.board.pawns.isEmpty) {
      return current.board.occupied.size > 2
          ? FreeEnd.coroa
          : FreeEnd.capturado;
    }
    if (current.isStalemate) return FreeEnd.afogado;
    final key = _key(fens.last);
    if (fens.where((fen) => _key(fen) == key).length >= 3) {
      return FreeEnd.repeticao;
    }
    if (fens.length - 1 >= limit * 2) return FreeEnd.limite;
    return null;
  }

  /// Peças, vez, roque e en passant: o que faz duas posições serem a mesma.
  static String _key(String fen) => fen.split(' ').take(4).join(' ');
}
