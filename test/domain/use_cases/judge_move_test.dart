import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/use_cases/judge_move.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/script_fixture.dart';

void main() {
  test('querer ganhar: vitória mantém, empate perde', () {
    expect(
      JudgeMove.ofOutcome(const KpkOutcome.win(5), wantsWin: true),
      MoveVerdict.keeps,
    );
    expect(
      JudgeMove.ofOutcome(KpkOutcome.draw, wantsWin: true),
      MoveVerdict.loses,
    );
  });

  test('querer empatar: empate mantém, vitória perde', () {
    expect(
      JudgeMove.ofOutcome(KpkOutcome.draw, wantsWin: false),
      MoveVerdict.keeps,
    );
    expect(
      JudgeMove.ofOutcome(const KpkOutcome.win(5), wantsWin: false),
      MoveVerdict.loses,
    );
  });

  test('fora da tabela não condena o lance', () {
    expect(
      JudgeMove.ofOutcome(KpkOutcome.outside, wantsWin: true),
      MoveVerdict.keeps,
    );
  });

  test('judge avalia a posição depois do lance', () {
    final oracle = FakeKpkOracle(
      byFen: {afterKe4: KpkOutcome.draw},
      fallback: const KpkOutcome.win(3),
    );
    final before = Chess.fromSetup(Setup.parseFen(exampleOneFen));
    expect(
      JudgeMove.judge(oracle, before, Move.parse('d3e4')!, wantsWin: true),
      MoveVerdict.loses,
    );
    expect(
      JudgeMove.judge(oracle, before, Move.parse('d3c3')!, wantsWin: true),
      MoveVerdict.keeps,
    );
  });
}
