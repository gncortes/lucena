import 'package:dartchess/dartchess.dart';

import '../models/game_end.dart';
import '../models/wdl.dart';
import 'game_rules.dart';

/// All moves since an explicit exercise reset, including both players' moves.
/// A FEN alone does not establish repetition history.
class ExerciseJudgeRequest {
  ExerciseJudgeRequest({
    required this.initialFen,
    required this.fen,
    required this.student,
    required List<String> played,
    required this.historyComplete,
  }) : played = List.unmodifiable(played);

  final String initialFen;
  final String fen;
  final Side student;
  final List<String> played;
  final bool historyComplete;
}

sealed class ExerciseJudgement {
  const ExerciseJudgement();
}

class ExerciseKnown extends ExerciseJudgement {
  const ExerciseKnown({
    required this.wdl,
    required this.perspective,
    required this.fen,
    required this.source,
    required this.conditions,
    this.sourceSha256,
    this.terminal,
  });

  final Wdl wdl;
  final Side perspective;
  final String fen;
  final String source;
  final String? sourceSha256;
  final String conditions;
  final GameEnd? terminal;
}

class ExerciseIndeterminate extends ExerciseJudgement {
  const ExerciseIndeterminate(this.reason);
  final String reason;
}

/// Only exact, rule-aware proofs. No centipawn fallback is permitted.
abstract interface class ExerciseProofProvider {
  Future<ExerciseJudgement> lookup(String fen);
}

class ExerciseJudge {
  const ExerciseJudge(this.proofs);
  final ExerciseProofProvider proofs;

  Future<ExerciseJudgement> evaluate(ExerciseJudgeRequest request) async {
    final start = exactPosition(request.initialFen);
    final target = exactPosition(request.fen);
    if (start == null || target == null) {
      return const ExerciseIndeterminate('invalidFen6');
    }
    if (!request.historyComplete) {
      return const ExerciseIndeterminate('incompleteHistory');
    }
    var position = start;
    final prefix = <String>[];
    for (final uci in request.played) {
      if (GameRules.endOf(
            position,
            repetitions: GameRules.repetitionsOf(start, prefix),
          ) !=
          null) {
        return const ExerciseIndeterminate('historyContinuesAfterTerminal');
      }
      final move = Move.parse(uci);
      final next = move == null ? null : GameRules.play(position, move);
      if (next == null) {
        return const ExerciseIndeterminate('illegalHistory');
      }
      prefix.add(uci);
      position = next.position;
    }
    if (position.fen != request.fen) {
      return const ExerciseIndeterminate('historyFenMismatch');
    }
    final end = GameRules.endOf(
      target,
      repetitions: GameRules.repetitionsOf(start, request.played),
    );
    if (end != null) {
      return ExerciseKnown(
        wdl: end.winner == null
            ? Wdl.draw
            : end.winner == request.student
            ? Wdl.win
            : Wdl.loss,
        perspective: request.student,
        fen: request.fen,
        source: 'GameRules/dartchess',
        conditions: 'complete exercise history; threefold and fifty-move draws',
        terminal: end,
      );
    }
    final ExerciseJudgement result;
    try {
      result = await proofs.lookup(request.fen);
    } on Object {
      return const ExerciseIndeterminate('proofUnavailable');
    }
    if (result is! ExerciseKnown) return result;
    if (result.fen != request.fen) {
      return const ExerciseIndeterminate('proofFenMismatch');
    }
    return ExerciseKnown(
      wdl: result.perspective == request.student
          ? result.wdl
          : result.wdl.flipped,
      perspective: request.student,
      fen: result.fen,
      source: result.source,
      sourceSha256: result.sourceSha256,
      conditions: '${result.conditions}; complete exercise history',
    );
  }

  /// Reject missing/normalized counters rather than silently resetting them.
  static Position? exactPosition(String fen) {
    if (fen.split(' ').length != 6) return null;
    final position = GameRules.fromFen(fen);
    return position?.fen == fen ? position : null;
  }
}
