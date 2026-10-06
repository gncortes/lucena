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
  /// Os lances [ucis] a partir de [position], em notação algébrica, até o
  /// primeiro ilegal (no máximo [max]).
  static List<String> sanLine(
    Position position,
    List<String> ucis, {
    int max = 1 << 30,
  }) {
    final out = <String>[];
    var current = position;
    for (final uci in ucis.take(max)) {
      final move = Move.parse(uci);
      final played = move == null ? null : play(current, move);
      if (played == null) break;
      out.add(played.san);
      current = played.position;
    }
    return out;
  }

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
  ///
  /// [repetitions] é quantas vezes a posição atual já apareceu na partida
  /// (ver [repetitionsOf]). Com ele, valem também os empates automáticos: a
  /// terceira repetição e a regra dos 50 lances. Sem ele (o tabuleiro livre,
  /// em que o jogador move os dois lados), a partida só acaba no tabuleiro.
  static GameEnd? endOf(Position position, {int? repetitions}) {
    if (position.isCheckmate) {
      return GameEnd(GameEndReason.checkmate, winner: position.turn.opposite);
    }
    if (position.isStalemate) return const GameEnd(GameEndReason.stalemate);
    if (position.isInsufficientMaterial) {
      return const GameEnd(GameEndReason.insufficientMaterial);
    }
    if (repetitions != null) {
      if (repetitions >= 3) return const GameEnd(GameEndReason.repetition);
      if (position.halfmoves >= fiftyMovesInPlies) {
        return const GameEnd(GameEndReason.fiftyMoves);
      }
    }
    return null;
  }

  /// A regra dos 50 lances, em meios-lances (cada lado joga 50).
  static const fiftyMovesInPlies = 100;

  /// Quantas vezes a posição a que [moves] (UCI) chega, a partir de [start],
  /// já apareceu na partida, contando esta. Posição igual é a mesma
  /// disposição de peças, com o mesmo lado na vez e os mesmos direitos de
  /// roque e de captura en passant.
  static int repetitionsOf(Position start, List<String> moves) {
    var position = start;
    final seen = [_repetitionKey(position)];
    for (final uci in moves) {
      final move = Move.parse(uci);
      final played = move == null ? null : play(position, move);
      if (played == null) break;
      position = played.position;
      seen.add(_repetitionKey(position));
    }
    return seen.where((key) => key == seen.last).length;
  }

  // O FEN sem os contadores de lances.
  static String _repetitionKey(Position position) =>
      position.fen.split(' ').take(4).join(' ');
}
