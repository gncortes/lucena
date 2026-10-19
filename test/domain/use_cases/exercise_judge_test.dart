import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/exercise_judge.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

class _NoProof implements ExerciseProofProvider {
  int calls = 0;
  @override
  Future<ExerciseJudgement> lookup(String fen) async {
    calls++;
    return const ExerciseIndeterminate('noProof');
  }
}

void main() {
  late _NoProof proofs;
  late ExerciseJudge judge;
  setUp(() {
    proofs = _NoProof();
    judge = ExerciseJudge(proofs);
  });

  Future<ExerciseJudgement> evaluate(
    String fen, {
    String? initial,
    List<String> played = const [],
    Side student = Side.white,
    bool complete = true,
  }) => judge.evaluate(
    ExerciseJudgeRequest(
      initialFen: initial ?? fen,
      fen: fen,
      student: student,
      played: played,
      historyComplete: complete,
    ),
  );

  test(
    'mate winner is relative to the student and precedes draw clocks',
    () async {
      const fen = '7k/6Q1/6K1/8/8/8/8/8 b - - 100 70';
      final white = await evaluate(fen) as ExerciseKnown;
      final black = await evaluate(fen, student: Side.black) as ExerciseKnown;
      expect(white.wdl, Wdl.win);
      expect(black.wdl, Wdl.loss);
      expect(white.terminal?.reason, GameEndReason.checkmate);
      expect(white.sourceSha256, isNull);
      expect(proofs.calls, 0);
    },
  );

  for (final entry in {
    '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1': GameEndReason.stalemate,
    '8/8/4k3/8/8/4K3/8/8 w - - 0 1': GameEndReason.insufficientMaterial,
    '8/8/8/4k3/8/8/8/R3K3 w - - 100 70': GameEndReason.fiftyMoves,
  }.entries) {
    test('terminal ${entry.value.name} is a draw without provider', () async {
      final result = await evaluate(entry.key) as ExerciseKnown;
      expect(result.wdl, Wdl.draw);
      expect(result.terminal?.reason, entry.value);
      expect(proofs.calls, 0);
    });
  }

  test('repetition uses the legally replayed complete history', () async {
    const start = '8/8/8/4k3/8/8/8/R3K3 w - - 0 1';
    const shuffle = ['e1d1', 'e5d5', 'd1e1', 'd5e5'];
    final moves = [...shuffle, ...shuffle];
    var position = GameRules.fromFen(start)!;
    for (final move in moves) {
      position = GameRules.play(position, Move.parse(move)!)!.position;
    }
    final result = await evaluate(
      position.fen,
      initial: start,
      played: moves,
    ) as ExerciseKnown;
    expect(result.wdl, Wdl.draw);
    expect(result.terminal?.reason, GameEndReason.repetition);
    expect(proofs.calls, 0);
  });

  test(
    'history continuing after a terminal is rejected before provider',
    () async {
      const terminal = '7k/6Q1/6K1/8/8/8/8/8 b - - 100 70';
      final result = await evaluate(terminal, played: ['h8h7']);
      expect(
        result,
        isA<ExerciseIndeterminate>().having(
          (result) => result.reason,
          'reason',
          'historyContinuesAfterTerminal',
        ),
      );
      expect(proofs.calls, 0);
    },
  );

  test('unknown, incomplete, malformed and mismatched histories stay indeterminate', () async {
    const fen = '8/k1K5/3N4/8/8/8/8/5B2 w - - 0 1';
    expect(await evaluate(fen), isA<ExerciseIndeterminate>());
    expect(await evaluate(fen, complete: false), isA<ExerciseIndeterminate>());
    expect(
      await evaluate('8/k1K5/3N4/8/8/8/8/5B2 w - -'),
      isA<ExerciseIndeterminate>(),
    );
    expect(await evaluate(fen, played: ['d6d8']), isA<ExerciseIndeterminate>());
    expect(await evaluate(fen, played: ['d6c8']), isA<ExerciseIndeterminate>());
  });
}
