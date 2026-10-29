import 'package:dartchess/dartchess.dart';

import '../../models/training/training_content.dart';
import '../game_rules.dart';

/// Replays only the exported main line, validating every UCI before use.
final class PlayTrainingOpening {
  PlayTrainingOpening(this.trecho) {
    if (trecho.moves.isEmpty) throw const FormatException('Empty opening');
    var position = GameRules.initial;
    final positions = <String>[position.fen];
    final notation = <String>[];
    for (final uci in trecho.moves) {
      final move = Move.parse(uci);
      final played = move == null ? null : GameRules.play(position, move);
      if (played == null) throw FormatException('Illegal opening move: $uci');
      notation.add(played.san);
      position = played.position;
      positions.add(position.fen);
    }
    if (trecho.black && trecho.moves.length < 2) {
      throw const FormatException('Opening has no student move');
    }
    fens = List.unmodifiable(positions);
    san = List.unmodifiable(notation);
  }
  final OpeningTrecho trecho;
  late final List<String> fens, san;
  int get initialCursor => trecho.black ? 1 : 0;
  int get studentMoves => (trecho.moves.length + (trecho.black ? 0 : 1)) ~/ 2;

  ({int cursor, bool correct}) play(int cursor, String uci) {
    if (cursor < initialCursor ||
        cursor >= trecho.moves.length ||
        cursor.isOdd != trecho.black) {
      throw StateError('Not a student turn');
    }
    final move = Move.parse(uci);
    final position = GameRules.fromFen(fens[cursor])!;
    if (move == null || GameRules.play(position, move) == null) {
      return (cursor: cursor, correct: false);
    }
    if (uci != trecho.moves[cursor]) return (cursor: cursor, correct: false);
    final next = cursor + 2;
    return (
      cursor: next > trecho.moves.length ? trecho.moves.length : next,
      correct: true,
    );
  }
}
