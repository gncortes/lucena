import 'package:dartchess/dartchess.dart';

import 'game_rules.dart';
import 'lesson_rules.dart';

/// Os lances do roteiro (T70/T71). A posição válida segue as regras do
/// xadrez ([GameRules]); a sem rei (as lições de peça do curso de iniciante:
/// só a torre, o bispo...) segue os ataques da peça, como nas estrelas.
abstract final class ScriptMoves {
  /// Os destinos de cada peça do lado que joga em [fen]. Com [pieces], só as
  /// peças dessas casas mexem.
  static Map<Square, Set<Square>> dests(String fen, {List<String>? pieces}) {
    final position = GameRules.fromFen(fen);
    final Map<Square, Set<Square>> all;
    if (position != null) {
      all = GameRules.legalMoves(position);
    } else {
      final setup = _setup(fen);
      if (setup == null) return const {};
      all = LessonRules.starsMoves(setup.board, setup.turn);
    }
    if (pieces == null) return all;
    final allowed = {for (final name in pieces) ?Square.parse(name)};
    return {
      for (final MapEntry(:key, :value) in all.entries)
        if (allowed.contains(key) && value.isNotEmpty) key: value,
    };
  }

  /// O lance [uci] aceito em [fen] (com dama quando o peão coroa sem
  /// escolher), ou nulo.
  static String? legal(String fen, String uci, {List<String>? pieces}) {
    final move = Move.parse(uci);
    if (move is! NormalMove) return null;
    final targets = dests(fen, pieces: pieces)[move.from];
    if (targets == null || !targets.contains(move.to)) return null;
    final board = _setup(fen)?.board;
    final pawn = board?.roleAt(move.from) == Role.pawn;
    final last = move.to.rank == Rank.first || move.to.rank == Rank.eighth;
    if (pawn && last && move.promotion == null) {
      return NormalMove(
        from: move.from,
        to: move.to,
        promotion: Role.queen,
      ).uci;
    }
    return move.uci;
  }

  /// [uci] jogado em [fen]: a posição nova e o lance em notação algébrica.
  /// [keepTurn]: tarefa sem adversário, a vez não passa. Nulo se o lance não
  /// vale ali.
  ///
  /// Na tarefa, um passo pode mostrar um lance do outro lado (a captura de
  /// volta, F3): a peça joga como se fosse a vez dela.
  static ({String fen, String san})? play(
    String fen,
    String uci, {
    bool keepTurn = false,
  }) {
    final move = Move.parse(uci);
    if (move == null) return null;
    final mover = keepTurn ? moverOf(fen, uci) : null;
    if (mover != null && mover != _turnOf(fen)) {
      final played = play(_turnTo(fen, mover), uci, keepTurn: true);
      if (played == null) return null;
      return (fen: _withTurn(played.fen, fen), san: played.san);
    }
    final position = GameRules.fromFen(fen);
    if (position != null) {
      final played = GameRules.play(position, move);
      if (played == null) return null;
      final next = played.position.fen;
      return (fen: keepTurn ? _withTurn(next, fen) : next, san: played.san);
    }
    final setup = _setup(fen);
    if (setup == null || move is! NormalMove) return null;
    final board = setup.board;
    final piece = board.pieceAt(move.from);
    final after = LessonRules.moveStar(board, setup.turn, move.from, move.to);
    if (piece == null || after == null) return null;
    final capture = board.pieceAt(move.to) != null ? 'x' : '';
    final parts = fen.split(' ');
    return (
      fen: [after.fen, ...parts.skip(1)].join(' '),
      san: '${piece.role.uppercaseLetter}$capture${move.to.name}',
    );
  }

  /// A cor da peça que sai da casa de origem de [uci] em [fen], ou nulo.
  static Side? moverOf(String fen, String uci) {
    final move = Move.parse(uci);
    if (move is! NormalMove) return null;
    return _setup(fen)?.board.pieceAt(move.from)?.color;
  }

  static Side _turnOf(String fen) =>
      fen.split(' ').elementAtOrNull(1) == 'b' ? Side.black : Side.white;

  static String _turnTo(String fen, Side side) {
    final parts = fen.split(' ');
    if (parts.length < 2) return fen;
    parts[1] = side == Side.white ? 'w' : 'b';
    return parts.join(' ');
  }

  /// [fen] com a vez de [from].
  static String _withTurn(String fen, String from) {
    final parts = fen.split(' ');
    final turn = from.split(' ').elementAtOrNull(1);
    if (parts.length < 2 || turn == null) return fen;
    parts[1] = turn;
    return parts.join(' ');
  }

  static Setup? _setup(String fen) {
    try {
      return Setup.parseFen(fen);
    } on FenException {
      return null;
    }
  }
}
