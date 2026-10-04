import 'package:dartchess/dartchess.dart';

import '../models/game_end.dart';

/// Regras do xadrez. Tudo vem do `dartchess`: aqui nada é reimplementado.
abstract final class GameRules {
  /// A posição inicial de uma partida.
  static const Position initial = Chess.initial;

  /// A posição descrita por um FEN. Nulo se o FEN for inválido ou a posição
  /// for impossível.
  static Position? fromFen(String fen) {
    try {
      return Chess.fromSetup(Setup.parseFen(fen));
    } on FenException {
      return null;
    } on PositionSetupException {
      return null;
    }
  }

  /// Joga [move] em [position]: devolve a posição nova e o lance em notação
  /// algébrica (`Nf3`, `O-O`, `exd6`, `a8=N+`). Nulo se o lance for ilegal.
  static ({Position position, String san})? play(Position position, Move move) {
    if (!position.isLegal(move)) return null;
    // O dartchess aceita o peão na última fila sem peça escolhida; aqui não.
    if (move case NormalMove(:final from, :final to, promotion: null)) {
      final isPawn = position.board.roleAt(from) == Role.pawn;
      if (isPawn && SquareSet.backranks.has(to)) return null;
    }
    final (next, san) = position.makeSanUnchecked(move);
    return (position: next, san: san);
  }

  /// Os destinos legais de cada peça do lado que joga.
  static Map<Square, Set<Square>> legalMoves(Position position) =>
      makeLegalMoves(position);

  /// A casa do rei em xeque, se houver.
  static Square? checkedKing(Position position) =>
      position.isCheck ? position.board.kingOf(position.turn) : null;

  /// O fim de partida quando o tempo de [flagged] acaba: vence o outro lado,
  /// a não ser que ele não tenha material para dar mate (aí é empate).
  static GameEnd timeoutEnd(Position position, Side flagged) {
    final opponent = flagged.opposite;
    if (position.hasInsufficientMaterial(opponent)) {
      return const GameEnd(GameEndReason.timeoutVsInsufficientMaterial);
    }
    return GameEnd(GameEndReason.timeout, winner: opponent);
  }

  /// Como a partida terminou. Nulo enquanto ela continua.
  static GameEnd? endOf(Position position) {
    if (position.isCheckmate) {
      return GameEnd(GameEndReason.checkmate, winner: position.turn.opposite);
    }
    if (position.isStalemate) return const GameEnd(GameEndReason.stalemate);
    if (position.isInsufficientMaterial) {
      return const GameEnd(GameEndReason.insufficientMaterial);
    }
    return null;
  }
}
