import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/use_cases/race_rules.dart';

import '../../../testing/fakes/fake_race_repository.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1, 12);
  final run = RaceRun(startedAt: start);

  RaceAnswer answer({required bool correct, int level = 1000}) =>
      RaceAnswer(problemId: 'p', level: level, move: 'a1a2', correct: correct);

  group('fim da Corrida', () {
    test('no começo ainda corre, com os 3 minutos inteiros', () {
      expect(RaceRules.endOf(run, start), isNull);
      expect(RaceRules.remaining(run, start), const Duration(minutes: 3));
    });

    test('acaba por tempo aos 3 minutos', () {
      final almost = start.add(const Duration(minutes: 2, seconds: 59));
      expect(RaceRules.endOf(run, almost), isNull);
      expect(RaceRules.remaining(run, almost), const Duration(seconds: 1));
      final over = start.add(const Duration(minutes: 3));
      expect(RaceRules.endOf(run, over), RaceEnd.time);
      expect(RaceRules.remaining(run, over), Duration.zero);
    });

    test('acaba no terceiro erro, não no segundo', () {
      var current = run;
      for (var i = 0; i < 2; i++) {
        current = current.withAnswer(answer(correct: false));
      }
      expect(RaceRules.endOf(current, start), isNull);
      current = current.withAnswer(answer(correct: false));
      expect(RaceRules.endOf(current, start), RaceEnd.errors);
    });

    test('acertos não gastam chance', () {
      var current = run;
      for (var i = 0; i < 10; i++) {
        current = current.withAnswer(answer(correct: true));
      }
      expect(RaceRules.endOf(current, start), isNull);
    });

    test('o terceiro erro vale mesmo com o tempo estourado', () {
      var current = run;
      for (var i = 0; i < 3; i++) {
        current = current.withAnswer(answer(correct: false));
      }
      final late = start.add(const Duration(minutes: 5));
      expect(RaceRules.endOf(current, late), RaceEnd.errors);
    });

    test('relógio do aparelho atrasado não devolve tempo', () {
      final before = start.subtract(const Duration(minutes: 1));
      expect(RaceRules.remaining(run, before), RaceRules.limit);
    });
  });

  group('contagem', () {
    test('conta acertos, erros e o nível mais difícil resolvido', () {
      final current = run
          .withAnswer(answer(correct: true, level: 900))
          .withAnswer(answer(correct: false, level: 2000))
          .withAnswer(answer(correct: true, level: 1200));
      expect(current.corrects, 2);
      expect(current.errors, 1);
      expect(current.hardestSolved, 1200);
    });

    test('sem acertos o mais difícil é zero', () {
      expect(run.hardestSolved, 0);
    });
  });

  group('resposta', () {
    final problem = raceTestProblems.first;

    test('só o lance do problema é certo', () {
      expect(RaceRules.answer(problem, problem.solution).correct, isTrue);
      expect(RaceRules.answer(problem, 'a1a2').correct, isFalse);
    });
  });

  group('próximo problema', () {
    test('começa pelo mais fácil e sobe a cada problema', () {
      var current = run;
      final levels = <int>[];
      for (var i = 0; i < raceTestProblems.length; i++) {
        final next = RaceRules.next(raceTestProblems, current)!;
        levels.add(next.level);
        current = current.withAnswer(RaceRules.answer(next, next.solution));
      }
      expect(levels, [900, 1060, 1140, 1220]);
    });

    test('respeita o filtro de tema', () {
      final rook = RaceRun(startedAt: start, theme: RaceTheme.rook);
      expect(RaceRules.next(raceTestProblems, rook)!.theme, RaceTheme.rook);
    });

    test('sem problema do tema, não há próximo', () {
      final minor = RaceRun(startedAt: start, theme: RaceTheme.minor);
      expect(RaceRules.next(raceTestProblems, minor), isNull);
    });

    test('acabando o banco, dá a volta', () {
      var current = run;
      for (var i = 0; i < raceTestProblems.length; i++) {
        final next = RaceRules.next(raceTestProblems, current)!;
        current = current.withAnswer(RaceRules.answer(next, next.solution));
      }
      expect(RaceRules.next(raceTestProblems, current)!.level, 900);
    });
  });

  group('recorde', () {
    test('mais acertos que o recorde é recorde', () {
      final outcome = RaceRules.finish(
        run.withAnswer(answer(correct: true)),
        RaceEnd.time,
        const RaceRecord(),
        start,
      );
      expect(outcome.isRecord, isTrue);
    });

    test('empatar não é recorde', () {
      final outcome = RaceRules.finish(
        run.withAnswer(answer(correct: true)),
        RaceEnd.time,
        const RaceRecord(corrects: 1, hardest: 1000),
        start,
      );
      expect(outcome.isRecord, isFalse);
    });

    test('o mais difícil guarda o maior nível de todas as Corridas', () {
      const record = RaceRecord(corrects: 10, hardest: 1500);
      final merged = RaceRules.merge(
        record,
        run.withAnswer(answer(correct: true, level: 1800)),
      );
      expect(merged.corrects, 10);
      expect(merged.hardest, 1800);
    });
  });

  test('o aquecimento são os 5 mais fáceis (ou todos, se forem menos)', () {
    expect(RaceRules.warmUp(raceTestProblems).map((p) => p.level), [
      900,
      1060,
      1140,
      1220,
    ]);
  });

  test(
    'o aquecimento do tema traz o final do desafio e completa com os fáceis',
    () {
      final rook = raceTestProblems.where((p) => p.theme == RaceTheme.rook);
      final warm = RaceRules.warmUp(raceTestProblems, theme: RaceTheme.rook);
      expect(warm, containsAll(rook));
      expect(
        warm.length,
        raceTestProblems.length < 5 ? raceTestProblems.length : 5,
      );
    },
  );

  test(
    'os de outro tema completam o aquecimento no fim, cada grupo por nível',
    () {
      final warm = RaceRules.warmUp(raceTestProblems, theme: RaceTheme.rook);
      // Os 2 de torre (1140, 1220) primeiro; depois os fáceis dos outros temas.
      expect(warm.map((p) => p.level), [1140, 1220, 900, 1060]);
      expect(warm.map((p) => p.theme).take(2), everyElement(RaceTheme.rook));
    },
  );

  test('a subcategoria do desafio escolhe o tema do aquecimento', () {
    expect(RaceTheme.ofSubcategory('rook'), RaceTheme.rook);
    expect(RaceTheme.ofSubcategory('queenVsPawn'), RaceTheme.queen);
    expect(RaceTheme.ofSubcategory('pawnVsKing'), RaceTheme.pawns);
    expect(RaceTheme.ofSubcategory('twoBishopsVsKing'), RaceTheme.minor);
    expect(RaceTheme.ofSubcategory('outra'), isNull);
  });
}
