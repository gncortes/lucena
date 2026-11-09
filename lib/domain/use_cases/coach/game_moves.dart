import 'package:dartchess/dartchess.dart';

/// Um meio-lance da linha principal da partida.
typedef GameMove = ({String uci, String san, String fen});

/// A linha principal do PGN da partida, meio-lance a meio-lance (a análise
/// completa abre com ela).
abstract final class GameMoves {
  /// Os meio-lances da linha principal; para no primeiro que não se joga.
  static List<GameMove> of(String? pgn) {
    if (pgn == null || pgn.trim().isEmpty) return const [];
    final PgnGame<PgnNodeData> match;
    Position position;
    try {
      match = PgnGame.parsePgn(pgn);
      position = PgnGame.startingPosition(match.headers);
    } on Object {
      return const [];
    }
    final moves = <GameMove>[];
    for (final no in match.moves.mainline()) {
      final chessMove = position.parseSan(no.san);
      if (chessMove == null) break;
      final (after, san) = position.makeSan(chessMove);
      position = after;
      moves.add((uci: chessMove.uci, san: san, fen: position.fen));
    }
    return moves;
  }

  /// O FEN de onde a partida começa.
  static String start(String? pgn) {
    if (pgn == null) return Chess.initial.fen;
    try {
      return PgnGame.startingPosition(PgnGame.parsePgn(pgn).headers).fen;
    } on Object {
      return Chess.initial.fen;
    }
  }
}
