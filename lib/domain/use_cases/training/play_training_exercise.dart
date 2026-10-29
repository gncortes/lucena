import 'package:dartchess/dartchess.dart';

import '../../models/training/training_content.dart';
import '../game_rules.dart';

/// Executes only the exported line. Alternatives certify the first move only;
/// they finish the exercise because no continuation is supplied by the bank.
final class PlayTrainingExercise {
  PlayTrainingExercise(this.exercise) {
    final initial = GameRules.fromFen(exercise.fen);
    if (initial == null || exercise.solution.isEmpty) {
      throw const FormatException('Missing playable exercise');
    }
    var position = initial;
    for (final uci in exercise.solution) {
      position = _play(position, uci);
    }
    for (final uci in exercise.alternatives) {
      _play(initial, uci);
    }
  }
  final TrainingExercise exercise;

  ({String fen, int cursor, bool done, bool correct, String lastMove}) play(
    String fen,
    int cursor,
    String uci,
  ) {
    if (cursor < 0 || cursor >= exercise.solution.length || cursor.isOdd) {
      throw StateError('Not a student turn');
    }
    final position = GameRules.fromFen(fen);
    if (position == null) throw const FormatException('Invalid exercise FEN');
    if (cursor == 0 && exercise.alternatives.contains(uci)) {
      return (
        fen: _play(position, uci).fen,
        cursor: exercise.solution.length,
        done: true,
        correct: true,
        lastMove: uci,
      );
    }
    final expected = exercise.solution[cursor];
    if (uci != expected) {
      return (
        fen: _play(position, expected).fen,
        cursor: cursor,
        done: true,
        correct: false,
        lastMove: expected,
      );
    }
    var next = _play(position, expected);
    var index = cursor + 1;
    var last = expected;
    if (index < exercise.solution.length) {
      last = exercise.solution[index++];
      next = _play(next, last);
    }
    return (
      fen: next.fen,
      cursor: index,
      done: index == exercise.solution.length,
      correct: true,
      lastMove: last,
    );
  }

  static Position _play(Position position, String uci) {
    final move = Move.parse(uci);
    final next = move == null ? null : GameRules.play(position, move);
    if (next == null) throw FormatException('Illegal exported move: $uci');
    return next.position;
  }
}
