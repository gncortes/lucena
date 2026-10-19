import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/assessment_execution_adapter.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

// Public positions/moves reused from game_rules_test and exercise_judge_test.
const _mate = '7k/6Q1/6K1/8/8/8/8/8 b - - 100 70';
const _rook = '8/8/8/4k3/8/8/8/R3K3 w - - 0 1';
const _shuffle = ['e1d1', 'e5d5', 'd1e1', 'd5e5'];
const _scholarMate = ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'];

Matcher failure(String reason) => isA<AssessmentExecutionAdapterException>()
    .having((e) => e.reason, 'reason', reason);

void main() {
  const adapter = AssessmentExecutionAdapter();

  test(
    'complete legal replay retains every visited prefix and actual turn',
    () {
      final moves = ['e2e4', 'e7e5', 'g1f3'];
      final result = adapter.replay(
        initialFen: GameRules.initial.fen,
        student: Side.white,
        played: moves,
      );
      expect(result.historyVerified, isTrue);
      expect(result.terminal, isFalse);
      expect(result.studentMate, isFalse);
      expect(result.studentTurn, isFalse);
      expect(result.pending, isFalse);
      expect(result.visitedSnapshots.keys, [
        'ply:0',
        'ply:1',
        'ply:2',
        'ply:3',
      ]);
      expect(result.visitedSnapshots['ply:0'], GameRules.initial.fen);
      expect(result.visitedSnapshots['ply:3'], result.gameFen);
      for (var ply = 0; ply <= moves.length; ply++) {
        final prefix = adapter.replay(
          initialFen: GameRules.initial.fen,
          student: Side.white,
          played: moves.take(ply).toList(),
        );
        expect(result.visitedSnapshots['ply:$ply'], prefix.gameFen);
      }
      moves.clear();
      expect(result.played, ['e2e4', 'e7e5', 'g1f3']);
      expect(() => result.played.clear(), throwsUnsupportedError);
      expect(() => result.visitedSnapshots.clear(), throwsUnsupportedError);
    },
  );

  test('actual replayed mate is relative to the student, for both sides', () {
    for (final student in [Side.white, Side.black]) {
      final result = adapter.replay(
        initialFen: GameRules.initial.fen,
        student: student,
        played: _scholarMate,
      );
      expect(result.terminal, isTrue);
      expect(result.studentMate, student == Side.white);
      expect(result.studentTurn, student == Side.black);
      expect(result.visitedSnapshots.length, _scholarMate.length + 1);
    }
  });

  test('checkmate in public root fixture precedes fifty-move draw clocks', () {
    final winner = adapter.replay(
      initialFen: _mate,
      student: Side.white,
      played: [],
    );
    final loser = adapter.replay(
      initialFen: _mate,
      student: Side.black,
      played: [],
    );
    expect(winner.studentMate, isTrue);
    expect(loser.studentMate, isFalse);
    expect(winner.terminal, isTrue);
    expect(winner.visitedSnapshots, {'ply:0': _mate});
  });

  for (final fen in [
    '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
    '8/8/4k3/8/8/4K3/8/8 w - - 0 1',
    '8/8/8/4k3/8/8/8/R3K3 w - - 100 70',
  ]) {
    test('public drawn terminal is terminal without student mate: $fen', () {
      final result = adapter.replay(
        initialFen: fen,
        student: Side.white,
        played: [],
      );
      expect(result.terminal, isTrue);
      expect(result.studentMate, isFalse);
    });
  }

  test('third repetition is terminal; legal play after it is rejected', () {
    final moves = [..._shuffle, ..._shuffle];
    final result = adapter.replay(
      initialFen: _rook,
      student: Side.white,
      played: moves,
    );
    expect(result.terminal, isTrue);
    expect(result.studentMate, isFalse);
    expect(
      () => adapter.replay(
        initialFen: _rook,
        student: Side.white,
        played: [...moves, 'e1d1'],
      ),
      throwsA(failure('historyContinuesAfterTerminal')),
    );
  });

  test('illegal, malformed and post-terminal history is rejected', () {
    for (final uci in ['e2e5', 'e7e5', 'not-a-move']) {
      expect(
        () => adapter.replay(
          initialFen: GameRules.initial.fen,
          student: Side.white,
          played: [uci],
        ),
        throwsA(failure('illegalHistory')),
      );
    }
    expect(
      () => adapter.replay(
        initialFen: _mate,
        student: Side.black,
        played: ['h8h7'],
      ),
      throwsA(failure('historyContinuesAfterTerminal')),
    );
    expect(
      () => adapter.replay(
        initialFen: GameRules.initial.fen,
        student: Side.white,
        played: [..._scholarMate, 'h8h7'],
      ),
      throwsA(failure('historyContinuesAfterTerminal')),
    );
  });

  test('initial and expected FEN require all six exact canonical fields', () {
    for (final invalid in [
      'not a FEN',
      '8/k1K5/3N4/8/8/8/8/5B2 w - -',
      '${GameRules.initial.fen} ',
      GameRules.initial.fen.replaceFirst(' 0 1', ' 00 1'),
    ]) {
      expect(
        () => adapter.replay(
          initialFen: invalid,
          student: Side.white,
          played: [],
        ),
        throwsA(failure('invalidFen6')),
      );
      expect(
        () => adapter.replay(
          initialFen: GameRules.initial.fen,
          student: Side.white,
          played: [],
          expectedFen: invalid,
        ),
        throwsA(failure('invalidFen6')),
      );
    }
  });

  test('a prefix checkpoint cannot stand in for the full replay endpoint', () {
    final prefix = adapter.replay(
      initialFen: GameRules.initial.fen,
      student: Side.white,
      played: ['e2e4'],
    );
    expect(
      () => adapter.replay(
        initialFen: GameRules.initial.fen,
        student: Side.white,
        played: ['e2e4', 'e7e5'],
        expectedFen: prefix.gameFen,
      ),
      throwsA(failure('historyFenMismatch')),
    );
    final full = adapter.replay(
      initialFen: GameRules.initial.fen,
      student: Side.white,
      played: ['e2e4', 'e7e5'],
    );
    expect(
      adapter
          .replay(
            initialFen: GameRules.initial.fen,
            student: Side.white,
            played: ['e2e4', 'e7e5'],
            expectedFen: full.gameFen,
          )
          .gameFen,
      full.gameFen,
    );
    expect(
      () => adapter.replay(
        initialFen: GameRules.initial.fen,
        student: Side.white,
        played: [],
        expectedFen: _rook,
      ),
      throwsA(failure('historyFenMismatch')),
    );
    expect(
      () => adapter.replay(
        initialFen: _rook,
        student: Side.white,
        played: [],
        expectedFen: '8/8/8/4k3/8/8/8/R3K3 w - - 99 70',
      ),
      throwsA(failure('historyFenMismatch')),
    );
  });

  test(
    'SHA256 identity is stable and covers root, student and complete moves',
    () {
      final initial = GameRules.initial.fen;
      final result = adapter.replay(
        initialFen: initial,
        student: Side.white,
        played: [],
      );
      final expected = sha256
          .convert(
            utf8.encode(
              jsonEncode({
                'initialFen': initial,
                'student': Side.white.name,
                'played': <String>[],
              }),
            ),
          )
          .toString();
      expect(result.historyIdentity, expected);
      expect(result.historyIdentity, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(
        adapter
            .replay(
              initialFen: initial,
              student: Side.white,
              played: [],
              expectedFen: initial,
              pending: true,
            )
            .historyIdentity,
        expected,
      );
      expect(
        adapter
            .replay(initialFen: initial, student: Side.black, played: [])
            .historyIdentity,
        isNot(expected),
      );
      expect(
        adapter
            .replay(initialFen: initial, student: Side.white, played: ['e2e4'])
            .historyIdentity,
        isNot(expected),
      );
      expect(
        adapter
            .replay(initialFen: _rook, student: Side.white, played: [])
            .historyIdentity,
        isNot(expected),
      );
    },
  );

  test('pending is allowed only while the actual board is nonterminal', () {
    final pending = adapter.replay(
      initialFen: GameRules.initial.fen,
      student: Side.black,
      played: [],
      pending: true,
    );
    expect(pending.pending, isTrue);
    expect(pending.terminal, isFalse);
    expect(pending.studentTurn, isFalse);
    expect(
      () => adapter.replay(
        initialFen: _mate,
        student: Side.white,
        played: [],
        pending: true,
      ),
      throwsA(failure('terminalPending')),
    );
  });
}
