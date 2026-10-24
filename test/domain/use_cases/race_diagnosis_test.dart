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

  test('conta por final: mate de dama e de torre separados', () {
    final diagnosis = of([
      run({'queen': (3, 1), 'rook': (1, 3)}),
      run({'pawnVsKing': (4, 0)}),
      run({'pawnVsKing': (3, 0)}),
    ]);
    expect(diagnosis.ready, isTrue);
    expect(diagnosis.weakest?.subcategory, 'rook');
    expect(diagnosis.weakest?.category, 'basic');
    expect(diagnosis.weakest?.corrects, 1);
    expect(diagnosis.weakest?.total, 4);
    // Do melhor para o pior.
    expect(
      [for (final s in diagnosis.mastered) s.subcategory],
      ['pawnVsKing', 'queen'],
    );
  });

  test('final com menos de 4 problemas fica de fora', () {
    final diagnosis = of([
      run({'knightBishopVsKing': (0, 3), 'pawnVsKing': (5, 0)}),
      run({}),
      run({}),
    ]);
    expect(diagnosis.toImprove, isEmpty);
    expect([for (final s in diagnosis.mastered) s.subcategory], ['pawnVsKing']);
  });

  test('domina com 70% de acerto; abaixo, a melhorar do pior ao melhor', () {
    final diagnosis = of([
      run({
        'pawnVsKing': (7, 3),
        'knightBishopVsKing': (2, 3),
        'queen': (6, 4),
      }),
      run({}),
      run({}),
    ]);
    expect([for (final s in diagnosis.mastered) s.subcategory], ['pawnVsKing']);
    expect(
      [for (final s in diagnosis.toImprove) s.subcategory],
      ['knightBishopVsKing', 'queen'],
    );
  });

  test('só as 10 Corridas mais recentes entram', () {
    final diagnosis = of([
      for (var i = 0; i < 10; i++) run({'pawnVsKing': (1, 0)}),
      run({'pawnVsKing': (0, 10)}),
    ]);
    expect(diagnosis.runs, 10);
    expect(diagnosis.toImprove, isEmpty);
    expect(diagnosis.mastered.single.total, 10);
  });

  test('aulas: só as liberadas, na ordem dos finais a melhorar', () {
    const scores = [
      RaceFinalScore(
        category: 'basic',
        subcategory: 'rook',
        corrects: 1,
        total: 5,
      ),
      RaceFinalScore(
        category: 'knightBishop',
        subcategory: 'knightBishopVsKing',
        corrects: 2,
        total: 5,
      ),
      RaceFinalScore(
        category: 'pawn',
        subcategory: 'pawnVsKing',
        corrects: 3,
        total: 5,
      ),
    ];
    // A Escola está escondida: o mate de torre fica sem aula.
    expect(
      [for (final l in RaceFinalLesson.forScores(scores)) l.lessonId],
      ['mates.bishopKnight.deletang', 'pawns.keySquares'],
    );
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
