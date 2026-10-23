import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/use_cases/race_diagnosis.dart';
import 'package:lucena/domain/use_cases/race_rules.dart';

import '../../../testing/fakes/fake_race_repository.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1, 12);

  RaceAnswer answer(String subcategory, {required bool correct}) => RaceAnswer(
    problemId: 'p',
    level: 400,
    move: 'a1a2',
    correct: correct,
    subcategory: subcategory,
  );

  /// Uma Corrida com [right] acertos e [wrong] erros em cada tipo.
  RaceResult run(Map<String, (int, int)> answers) {
    var current = RaceRun(startedAt: start);
    for (final MapEntry(key: subcategory, value: (right, wrong))
        in answers.entries) {
      for (var i = 0; i < right; i++) {
        current = current.withAnswer(answer(subcategory, correct: true));
      }
      for (var i = 0; i < wrong; i++) {
        current = current.withAnswer(answer(subcategory, correct: false));
      }
    }
    return RaceResult(run: current, end: RaceEnd.time, finishedAt: start);
  }

  RaceDiagnosis of(List<RaceResult> history) =>
      RaceDiagnosis.of(history, raceTestProblems);

  test('com menos de 3 Corridas ainda não está pronto', () {
    final diagnosis = of([
      run({'rook': (2, 3)}),
      run({'rook': (2, 3)}),
    ]);
    expect(diagnosis.runs, 2);
    expect(diagnosis.ready, isFalse);
  });

  test('conta por categoria: mate de dama e de torre juntos em "basic"', () {
    final diagnosis = of([
      run({'queen': (2, 1), 'rook': (0, 2)}),
      run({'pawnVsKing': (4, 0)}),
      run({'pawnVsKing': (3, 0)}),
    ]);
    expect(diagnosis.ready, isTrue);
    expect(diagnosis.weakest?.category, 'basic');
    expect(diagnosis.weakest?.errors, 3);
    expect(diagnosis.weakest?.total, 5);
    expect([for (final s in diagnosis.good) s.category], ['pawn']);
  });

  test('categoria com menos de 5 problemas fica de fora', () {
    final diagnosis = of([
      run({'knightBishopVsKing': (0, 3), 'pawnVsKing': (5, 0)}),
      run({}),
      run({}),
    ]);
    expect(diagnosis.weak, isEmpty);
    expect([for (final s in diagnosis.good) s.category], ['pawn']);
  });

  test('30% de erro já precisa de treino; o pior vem primeiro', () {
    final diagnosis = of([
      run({'pawnVsKing': (7, 3), 'knightBishopVsKing': (2, 3)}),
      run({}),
      run({}),
    ]);
    expect(
      [for (final s in diagnosis.weak) s.category],
      ['knightBishop', 'pawn'],
    );
    expect(diagnosis.good, isEmpty);
  });

  test('só as 5 Corridas mais recentes entram', () {
    final diagnosis = of([
      for (var i = 0; i < 5; i++) run({'pawnVsKing': (1, 0)}),
      run({'pawnVsKing': (0, 10)}),
    ]);
    expect(diagnosis.runs, 5);
    expect(diagnosis.weak, isEmpty);
    expect(diagnosis.good.single.total, 5);
  });

  test('a Corrida só de um tipo ou de uma família tira o resto', () {
    final onlyRook = RaceRules.only(raceTestProblems, subcategory: 'rook');
    expect(
      raceTestProblems.where(onlyRook.matches).map((p) => p.subcategory),
      everyElement('rook'),
    );
    final basic = RaceRules.only(raceTestProblems, category: 'basic');
    expect(RaceRules.count(raceTestProblems, basic), 3);
  });

  test('o tipo de final de uma posição vem das peças de cada lado', () {
    expect(
      RaceRules.subcategoryOf(raceTestProblems, '8/8/8/8/8/2k5/4P3/4K3 w - -'),
      'pawnVsKing',
    );
    expect(
      RaceRules.subcategoryOf(raceTestProblems, '8/8/8/8/8/2K5/4p3/4k3 b - -'),
      'pawnVsKing',
    );
    expect(
      RaceRules.subcategoryOf(raceTestProblems, '8/8/8/8/8/2k5/4r3/4K2Q w - -'),
      isNull,
    );
  });
}
