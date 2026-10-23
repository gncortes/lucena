import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/use_cases/race_rules.dart';
import 'package:lucena/domain/use_cases/race_turn.dart';

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

  group('lance na sequência', () {
    final queen = RaceTurn.start(raceTestProblems[0]);
    final rook = RaceTurn.start(raceTestProblems[1]);

    test('todo lance ótimo vale (empate aceita todos)', () {
      expect(queen.judge('a1a8'), RaceMoveKind.optimal);
      expect(queen.judge('a1g7'), RaceMoveKind.optimal);
      expect(rook.judge('f6f7'), RaceMoveKind.optimal);
      expect(rook.judge('f6g6'), RaceMoveKind.optimal);
    });

    test('lance que ainda ganha, mas devagar, não é o certo', () {
      expect(queen.judge('a1a2'), RaceMoveKind.slower);
      final mistake = queen.mistake('a1a2');
      expect(mistake.correct, isFalse);
      expect(mistake.slower, isTrue);
      expect(mistake.best, ['a1a8', 'a1g7']);
      expect(mistake.distance, 1);
      expect(mistake.mateIn, 1);
      expect(mistake.fen, raceTestProblems[0].fen);
    });

    test('lance que empata ou perde é erro, sem ser "mais devagar"', () {
      expect(queen.judge('a2a3'), RaceMoveKind.wrong);
      expect(queen.mistake('a2a3').slower, isFalse);
    });

    test('o mate em 2 tem distância 3 e mate em 2 lances', () {
      expect(rook.node.distance, 3);
      expect(rook.node.mateIn, 2);
    });

    test('a defesa responde sozinha e a vez seguinte tem a posição nova', () {
      expect(rook.ends('f6f7'), isFalse);
      expect(rook.replyTo('f6f7'), 'h8h7');
      final next = rook.after('f6f7')!;
      expect(next.step, 1);
      expect(next.fen, '8/5K1k/8/8/8/8/8/R7 w - - 2 2');
      expect(next.judge('a1h1'), RaceMoveKind.optimal);
      expect(next.ends('a1h1'), isTrue);
      expect(next.after('a1h1'), isNull);
    });

    test('o erro no meio da sequência guarda a posição daquela vez', () {
      final next = rook.after('f6f7')!;
      final mistake = next.mistake('a1a2');
      expect(mistake.fen, next.fen);
      expect(mistake.best, ['a1h1']);
      expect(mistake.distance, 1);
    });
  });

  group('próximo problema', () {
    RaceProblem p(String id, int level, {RaceTheme? theme}) => RaceProblem(
      id: id,
      fen: raceTestProblems.first.fen,
      tree: raceTestProblems.first.tree,
      theme: theme ?? RaceTheme.queen,
      level: level,
    );
    final bank = [
      for (var bucket = 300; bucket <= 450; bucket += 50) ...[
        p('b$bucket.1', bucket),
        p('b$bucket.2', bucket + 49),
      ],
    ];

    RaceAnswer solved(RaceProblem problem) => RaceAnswer(
      problemId: problem.id,
      level: problem.level,
      move: 'x',
      correct: true,
    );

    test('começa sempre na faixa de 300', () {
      for (var i = 0; i < 20; i++) {
        final other = RaceRun(startedAt: start.add(Duration(seconds: i)));
        expect(RaceRules.next(bank, other)!.bucket, 300);
      }
    });

    test('sobe uma faixa a cada acerto, e o erro não faz subir', () {
      var current = run;
      final buckets = <int>[];
      for (var i = 0; i < 4; i++) {
        final next = RaceRules.next(bank, current)!;
        buckets.add(next.bucket);
        current = current.withAnswer(solved(next));
      }
      expect(buckets, [300, 350, 400, 450]);
      final missed = run.withAnswer(
        RaceAnswer(problemId: 'b300.1', level: 300, move: 'x', correct: false),
      );
      expect(RaceRules.next(bank, missed)!.bucket, 300);
      expect(RaceRules.next(bank, missed)!.id, 'b300.2');
    });

    test('sorteia dentro da faixa, sem repetir na Corrida', () {
      final ids = <String>{};
      for (var i = 0; i < 40; i++) {
        final other = RaceRun(startedAt: start.add(Duration(seconds: i)));
        ids.add(RaceRules.next(bank, other)!.id);
      }
      expect(ids, {'b300.1', 'b300.2'});
    });

    test('o mesmo ponto da Corrida dá o mesmo problema (retomar)', () {
      expect(
        RaceRules.next(bank, run)!.id,
        RaceRules.next(bank, RaceRun(startedAt: start))!.id,
      );
    });

    test('evita os das últimas Corridas, se há outro na faixa', () {
      for (var i = 0; i < 20; i++) {
        final other = RaceRun(startedAt: start.add(Duration(seconds: i)));
        expect(RaceRules.next(bank, other, recent: {'b300.1'})!.id, 'b300.2');
      }
    });

    test('se todos da faixa são recentes, usa um deles mesmo assim', () {
      final next = RaceRules.next(bank, run, recent: {'b300.1', 'b300.2'});
      expect(next!.bucket, 300);
    });

    test(
      'passou da última faixa e acabou o topo: desce à mais alta com sobra',
      () {
        // Topo (450) todo visto; 400 também; sobra a 350 e a 300.
        var current = run;
        for (final id in ['b450.1', 'b450.2', 'b400.1', 'b400.2']) {
          final problem = bank.firstWhere((p) => p.id == id);
          current = current.withAnswer(solved(problem));
        }
        for (var i = 0; i < 6; i++) {
          current = current.withAnswer(solved(bank.first));
        }
        expect(RaceRules.bucketFor(current), greaterThan(450));
        expect(RaceRules.next(bank, current)!.bucket, 350);
      },
    );

    test('depois de tudo visto, repete (dá a volta)', () {
      var current = run;
      for (final problem in bank) {
        current = current.withAnswer(solved(problem));
      }
      expect(RaceRules.next(bank, current), isNotNull);
    });

    test('os recentes saem das últimas 3 Corridas do histórico', () {
      RaceResult result(String id) => RaceResult(
        run: run.withAnswer(
          RaceAnswer(problemId: id, level: 300, move: 'x', correct: true),
        ),
        end: RaceEnd.time,
        finishedAt: start,
      );
      final recent = RaceRules.recentIds([
        result('a'),
        result('b'),
        result('c'),
        result('d'),
      ]);
      expect(recent, {'a', 'b', 'c'});
    });

    test('respeita o filtro de tema', () {
      final rook = RaceRun(startedAt: start, theme: RaceTheme.rook);
      expect(RaceRules.next(raceTestProblems, rook)!.theme, RaceTheme.rook);
    });

    test('faixa sem problema do tema pula para a próxima que tenha', () {
      // O banco de teste tem torre em 350 e 500; começando em 300, vem 350.
      final rook = RaceRun(startedAt: start, theme: RaceTheme.rook);
      expect(RaceRules.next(raceTestProblems, rook)!.bucket, 350);
      // Depois do primeiro acerto, a faixa pedida é 350; no segundo, 400
      // não tem torre e pula para 500.
      final two = rook
          .withAnswer(solved(raceTestProblems[1]))
          .withAnswer(solved(raceTestProblems[1]));
      expect(RaceRules.next(raceTestProblems, two)!.bucket, 500);
    });

    test('sem problema do tema, não há próximo', () {
      final none = RaceRun(startedAt: start, theme: RaceTheme.minor);
      expect(RaceRules.next(const [], none), isNull);
    });

    test('passando da última faixa, fica nela', () {
      var current = run;
      final buckets = <int>[];
      for (var i = 0; i < 5; i++) {
        final next = RaceRules.next(bank, current)!;
        buckets.add(next.bucket);
        current = current.withAnswer(solved(next));
      }
      expect(buckets, [300, 350, 400, 450, 450]);
    });
  });

  group('subida da régua', () {
    test('+50 por acerto até 1500 e +25 depois', () {
      expect(RaceRules.targetRating(0), 300);
      expect(RaceRules.targetRating(1), 350);
      expect(RaceRules.targetRating(24), 1500);
      expect(RaceRules.targetRating(25), 1525);
      expect(RaceRules.targetRating(26), 1550);
      expect(RaceRules.targetRating(68), 2600);
    });

    test('quantos acertos levam a cada faixa (inverso do alvo)', () {
      for (var corrects = 0; corrects <= 68; corrects++) {
        expect(
          RaceRules.correctsToReach(RaceRules.targetRating(corrects)),
          corrects,
        );
      }
      expect(RaceRules.correctsToReach(2600), 68);
    });

    test('o banco de faixas de 25 sobe uma faixa por acerto', () {
      RaceProblem q(int bucket) => RaceProblem(
        id: 'q$bucket',
        fen: raceTestProblems.first.fen,
        tree: raceTestProblems.first.tree,
        theme: RaceTheme.queen,
        level: bucket,
      );
      final bank = [
        for (final b in [1450, 1500, 1525, 1550]) q(b),
      ];
      var current = RaceRun(startedAt: start);
      // Acertos fictícios até o alvo ser 1450 (23 acertos).
      for (var i = 0; i < 23; i++) {
        current = current.withAnswer(
          RaceAnswer(problemId: 'x$i', level: 300, move: 'x', correct: true),
        );
      }
      final seen = <int>[];
      for (var i = 0; i < 4; i++) {
        final next = RaceRules.next(bank, current)!;
        seen.add(next.bucket);
        current = current.withAnswer(
          RaceAnswer(
            problemId: next.id,
            level: next.level,
            move: 'x',
            correct: true,
          ),
        );
      }
      expect(seen, [1450, 1500, 1525, 1550]);
    });
  });

  group('duração', () {
    test('5 minutos dão 5 minutos de relógio', () {
      final five = RaceRun(
        startedAt: start,
        duration: RaceDuration.fiveMinutes,
      );
      expect(
        RaceRules.remaining(five, start.add(const Duration(minutes: 3))),
        const Duration(minutes: 2),
      );
      expect(
        RaceRules.endOf(five, start.add(const Duration(minutes: 3))),
        isNull,
      );
      expect(
        RaceRules.endOf(five, start.add(const Duration(minutes: 5))),
        RaceEnd.time,
      );
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
      300,
      350,
      400,
      450,
      500,
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
      // Os 2 de torre (350, 500) primeiro; depois os fáceis dos outros temas.
      expect(warm.map((p) => p.level), [350, 500, 300, 400, 450]);
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

  group('lance aceito por tolerância (linha longa)', () {
    final turn = RaceTurn(
      problem: raceTestProblems[1],
      fen: raceTestProblems[1].fen,
      node: const RaceNode(
        distance: 31,
        moves: {'f6f7': RaceBranch()},
        alternatives: {'f6g6'},
        slower: {'a1a2'},
      ),
    );

    test('o lance da tolerância vale como certo e encerra o problema', () {
      expect(turn.judge('f6f7'), RaceMoveKind.optimal);
      expect(turn.judge('f6g6'), RaceMoveKind.optimal);
      expect(turn.ends('f6g6'), isTrue);
      expect(turn.after('f6g6'), isNull);
    });

    test('mais lento que isso continua erro "ganhava mais devagar"', () {
      expect(turn.judge('a1a2'), RaceMoveKind.slower);
      expect(turn.judge('a1b1'), RaceMoveKind.wrong);
    });
  });
}
