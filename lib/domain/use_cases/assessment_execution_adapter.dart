import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';

import '../models/assessment_attempt.dart';
import '../models/game_end.dart';
import 'exercise_judge.dart';
import 'game_rules.dart';

final class AssessmentExecutionAdapterException implements Exception {
  const AssessmentExecutionAdapterException(this.reason);

  final String reason;

  @override
  String toString() => 'AssessmentExecutionAdapterException: $reason';
}

/// Replays the actual complete history. Legal moves need no winning evaluation.
/// Opponent policy and conceptual facts are outside this adapter's evidence.
final class AssessmentExecutionAdapter {
  const AssessmentExecutionAdapter();

  AssessmentExecution replay({
    required String initialFen,
    required Side student,
    required List<String> played,
    String? expectedFen,
    bool pending = false,
  }) {
    final start = ExerciseJudge.exactPosition(initialFen);
    if (start == null ||
        (expectedFen != null &&
            ExerciseJudge.exactPosition(expectedFen) == null)) {
      throw const AssessmentExecutionAdapterException('invalidFen6');
    }
    final history = List<String>.unmodifiable(played);
    var position = start;
    final prefix = <String>[];
    final snapshots = <String, String>{'ply:0': initialFen};
    for (final uci in history) {
      if (GameRules.endOf(
            position,
            repetitions: GameRules.repetitionsOf(start, prefix),
          ) !=
          null) {
        throw const AssessmentExecutionAdapterException(
          'historyContinuesAfterTerminal',
        );
      }
      final move = Move.parse(uci);
      final next = move == null ? null : GameRules.play(position, move);
      if (next == null) {
        throw const AssessmentExecutionAdapterException('illegalHistory');
      }
      prefix.add(uci);
      position = next.position;
      snapshots['ply:${prefix.length}'] = position.fen;
    }
    if (expectedFen != null && position.fen != expectedFen) {
      throw const AssessmentExecutionAdapterException('historyFenMismatch');
    }
    final end = GameRules.endOf(
      position,
      repetitions: GameRules.repetitionsOf(start, history),
    );
    if (pending && end != null) {
      throw const AssessmentExecutionAdapterException('terminalPending');
    }
    final identity = sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'initialFen': initialFen,
              'student': student.name,
              'played': history,
            }),
          ),
        )
        .toString();
    return AssessmentExecution(
      gameFen: position.fen,
      played: history,
      visitedSnapshots: snapshots,
      historyIdentity: identity,
      historyVerified: true,
      studentMate:
          end?.reason == GameEndReason.checkmate && end?.winner == student,
      terminal: end != null,
      studentTurn: position.turn == student,
      pending: pending,
    );
  }
}
