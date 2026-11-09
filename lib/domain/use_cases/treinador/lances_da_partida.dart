import 'package:dartchess/dartchess.dart';

/// Um meio-lance da linha principal da partida.
typedef LanceDaPartida = ({String uci, String san, String fen});

/// A linha principal do PGN da partida, meio-lance a meio-lance (a análise
/// completa abre com ela).
abstract final class LancesDaPartida {
  /// Os meio-lances da linha principal; para no primeiro que não se joga.
  static List<LanceDaPartida> de(String? pgn) {
    if (pgn == null || pgn.trim().isEmpty) return const [];
    final PgnGame<PgnNodeData> jogo;
    Position posicao;
    try {
      jogo = PgnGame.parsePgn(pgn);
      posicao = PgnGame.startingPosition(jogo.headers);
    } on Object {
      return const [];
    }
    final lances = <LanceDaPartida>[];
    for (final no in jogo.moves.mainline()) {
      final lance = posicao.parseSan(no.san);
      if (lance == null) break;
      final (depois, san) = posicao.makeSan(lance);
      posicao = depois;
      lances.add((uci: lance.uci, san: san, fen: posicao.fen));
    }
    return lances;
  }

  /// O FEN de onde a partida começa.
  static String inicio(String? pgn) {
    if (pgn == null) return Chess.initial.fen;
    try {
      return PgnGame.startingPosition(PgnGame.parsePgn(pgn).headers).fen;
    } on Object {
      return Chess.initial.fen;
    }
  }
}
