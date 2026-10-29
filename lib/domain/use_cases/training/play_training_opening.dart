import 'package:dartchess/dartchess.dart';

import '../../models/lesson_script.dart';
import '../../models/training/training_content.dart';
import '../game_rules.dart';

/// Compiles authored setup, snapshots and moves without inferring missing moves.
final class PlayTrainingOpening {
  PlayTrainingOpening(this.trecho) {
    final example = trecho.script;
    _fens.add(
      _position(example?.fen ?? trecho.fen ?? GameRules.initial.fen).fen,
    );
    if (example == null) {
      for (final move in trecho.moves) {
        _appendMove(move, student: _position(_fens.last).turn == studentSide);
      }
    } else {
      for (final step in example.entry) {
        _appendStep(step, setup: true);
      }
      if (example.question case final question?) {
        _appendQuestion(question);
      }
      if (example.practice case final practice?) {
        _appendPractice(practice.line);
      } else {
        for (final step in example.line) {
          _appendStep(step);
        }
      }
    }
    if (_questions.isEmpty) {
      throw const FormatException('Opening has no student move');
    }
    _recordValidStudentMoveCounts();
  }

  PlayTrainingOpening._branch(this.trecho, String fen) {
    _fens.add(fen);
  }

  final OpeningTrecho trecho;
  final _fens = <String>[];
  final _san = <String>[];
  final _moves = <String?>[];
  final _questions = <int, List<String>>{};
  final _branches = <int, Map<String, PlayTrainingOpening>>{};
  final _validStudentMoveCounts = <int>{};
  Side get studentSide => trecho.black ? Side.black : Side.white;
  List<String> get fens => List.unmodifiable(_fens);
  List<String> get san => List.unmodifiable(_san);
  int get initialCursor => _questions.keys.firstOrNull ?? _moves.length;
  int get studentMoves => _questions.length;

  /// Exact result lengths for the main line and accepted authored branches.
  Set<int> get validStudentMoveCounts =>
      Set.unmodifiable(_validStudentMoveCounts);
  bool isComplete(int cursor) => cursor == _moves.length;
  int questionIndex(int cursor) => _questions.keys.toList().indexOf(cursor);
  List<String> acceptedAt(int cursor) => _questions[cursor] ?? const [];
  String? moveAt(int index) => _moves[index];
  int moveNumberAt(int index) => int.parse(_fens[index].split(' ')[5]);
  Side sideAt(int index) => _position(_fens[index]).turn;

  void _recordValidStudentMoveCounts() {
    _validStudentMoveCounts.add(_questions.length);
    for (final MapEntry(key: cursor, value: branches) in _branches.entries) {
      final before = _questions.keys.where((index) => index < cursor).length;
      for (final branch in branches.values) {
        branch._recordValidStudentMoveCounts();
        for (final count in branch._validStudentMoveCounts) {
          _validStudentMoveCounts.add(before + count);
        }
      }
    }
  }

  Position _position(String fen) =>
      GameRules.fromFen(fen) ??
      (throw FormatException('Invalid opening FEN: $fen'));

  // Return type inferred from the project rules wrapper.
  static ({Position position, String san}) _played(
    Position position,
    String uci,
  ) {
    final move = Move.parse(uci);
    final played = move == null ? null : GameRules.play(position, move);
    if (played == null) throw FormatException('Illegal opening move: $uci');
    return played;
  }

  void _appendMove(String uci, {bool student = false, List<String>? accepted}) {
    final played = _played(_position(_fens.last), uci);
    if (student) {
      _questions[_moves.length] = List.unmodifiable(accepted ?? [uci]);
    }
    _moves.add(uci);
    _san.add(played.san);
    _fens.add(played.position.fen);
  }

  PlayTrainingOpening _answerBranch(
    int cursor,
    String uci,
    List<String> accepted,
  ) =>
      PlayTrainingOpening._branch(trecho, _fens[cursor])
        .._appendMove(uci, student: true, accepted: accepted);

  void _appendPractice(List<PracticeTurn> turns, [int index = 0]) {
    if (index == turns.length) return;
    final turn = turns[index];
    if (turn.right.isEmpty) {
      throw const FormatException('Empty practice turn');
    }
    final position = _position(_fens.last);
    for (final uci in turn.right) {
      _played(position, uci);
    }
    final cursor = _moves.length;
    _appendMove(turn.right.first, student: true, accepted: turn.right);
    if (turn.reply case final reply?) _appendMove(reply);
    _appendPractice(turns, index + 1);
    for (final uci in turn.right.skip(1)) {
      final branch = _answerBranch(cursor, uci, turn.right);
      if (turn.reply case final reply?) branch._appendMove(reply);
      // Every accepted answer shares the remaining authored practice turns.
      // Invalid continuations reject the definition instead of skipping moves.
      branch._appendPractice(turns, index + 1);
      (_branches[cursor] ??= {})[uci] = branch;
    }
  }

  void _appendQuestion(ScriptQuestion question) {
    if (question.right.isEmpty) {
      throw const FormatException('Empty opening question');
    }
    final accepted = <String>{
      ...question.right,
      ...question.alternatives.keys,
    }.toList();
    final position = _position(_fens.last);
    for (final uci in accepted) {
      _played(position, uci);
    }
    final primary =
        question.rightStep.moves.firstOrNull ?? question.right.first;
    if (!question.right.contains(primary)) {
      throw const FormatException('Question answer is not an accepted move');
    }
    final cursor = _moves.length;
    _appendMove(primary, student: true, accepted: accepted);
    _appendAnswerStep(question.rightStep, primary);
    for (final uci in accepted) {
      if (uci == primary && !question.alternatives.containsKey(uci)) continue;
      final branch = _answerBranch(cursor, uci, accepted);
      final steps = question.alternatives[uci] ?? const <ScriptStep>[];
      for (var i = 0; i < steps.length; i++) {
        if (i == 0) {
          branch._appendAnswerStep(steps[i], uci);
        } else {
          branch._appendStep(steps[i]);
        }
      }
      (_branches[cursor] ??= {})[uci] = branch;
    }
  }

  // The first answer step may repeat the move the student just supplied.
  void _appendAnswerStep(ScriptStep step, String uci) {
    if (step.moves.firstOrNull != uci) {
      _appendStep(step);
      return;
    }
    for (final next in step.moves.skip(1)) {
      _appendMove(next);
    }
    _applySnapshot(step);
  }

  void _appendStep(ScriptStep step, {bool setup = false}) {
    for (final uci in step.moves) {
      _appendMove(
        uci,
        student: !setup && _position(_fens.last).turn == studentSide,
      );
    }
    _applySnapshot(step);
  }

  void _applySnapshot(ScriptStep step) {
    final authored = _position(step.fen).fen;
    if (step.hasMove) {
      // FEN counters/en-passant may differ between authoring tools. The
      // authored snapshot remains authoritative after validating the move.
      if (_fens.last.split(' ').take(3).join(' ') !=
          authored.split(' ').take(3).join(' ')) {
        throw const FormatException('Opening move and snapshot disagree');
      }
      _fens[_fens.length - 1] = authored;
    } else if (_fens.last != authored) {
      _moves.add(null);
      _san.add('');
      _fens.add(authored);
    }
  }

  ({int cursor, bool correct}) play(int cursor, String uci) {
    final accepted = _questions[cursor];
    if (accepted == null) throw StateError('Not a student turn');
    if (!accepted.contains(uci)) return (cursor: cursor, correct: false);
    final played = _played(_position(_fens[cursor]), uci);
    if (_branches[cursor]?[uci] case final branch?) {
      _moves.replaceRange(cursor, _moves.length, branch._moves);
      _san.replaceRange(cursor, _san.length, branch._san);
      _fens.replaceRange(cursor + 1, _fens.length, branch._fens.skip(1));
      _questions.removeWhere((index, _) => index >= cursor);
      for (final MapEntry(:key, :value) in branch._questions.entries) {
        _questions[cursor + key] = value;
      }
      _branches.removeWhere((index, _) => index >= cursor);
      for (final MapEntry(:key, :value) in branch._branches.entries) {
        _branches[cursor + key] = value;
      }
    } else if (uci != _moves[cursor]) {
      // No authored continuation exists for this accepted answer.
      _moves.replaceRange(cursor, _moves.length, [uci]);
      _san.replaceRange(cursor, _san.length, [played.san]);
      _fens.replaceRange(cursor + 1, _fens.length, [played.position.fen]);
      _questions.removeWhere((index, _) => index > cursor);
      _branches.removeWhere((index, _) => index >= cursor);
    }
    final next = _questions.keys.where((index) => index > cursor).firstOrNull;
    return (cursor: next ?? _moves.length, correct: true);
  }
}
