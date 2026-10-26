import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/ui/race/view_models/race_cubit.dart';
import 'package:lucena/ui/race/view_models/race_warm_up_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';

void main() {
  late FakeNow now;
  late FakeRaceRepository repository;
  late RaceCubit cubit;

  const wrong = 'a2a3';

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    repository = FakeRaceRepository(now: now);
    cubit = RaceCubit(repository, now, replyDelay: Duration.zero);
  });

  tearDown(() => cubit.close());

  /// Joga a sequência ótima do problema da vez até fechá-lo.
  Future<void> solveCurrent() async {
    final id = cubit.state.problem!.id;
    final answers = cubit.state.run!.answers.length;
    while (cubit.state.phase == RacePhase.playing &&
        cubit.state.run!.answers.length == answers &&
        cubit.state.problem?.id == id) {
      await cubit.answer(cubit.state.turn!.node.moves.keys.first);
    }
  }

  test('a duração começa em 3 minutos e muda o recorde mostrado', () async {
    final both = FakeRaceRepository(
      now: now,
      record: const RaceRecord(corrects: 14, hardest: 1620),
      record5: const RaceRecord(corrects: 20, hardest: 1700),
    );
    final cubit = RaceCubit(both, now, replyDelay: Duration.zero);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.duration, RaceDuration.threeMinutes);
    expect(cubit.state.record.corrects, 14);
    await cubit.selectDuration(RaceDuration.fiveMinutes);
    expect(cubit.state.record.corrects, 20);
    expect(cubit.state.remaining, const Duration(minutes: 5));
    expect(await both.duration(), RaceDuration.fiveMinutes);
    await cubit.start();
    expect(cubit.state.run!.duration, RaceDuration.fiveMinutes);
    expect(cubit.state.remaining, const Duration(minutes: 5));
  });

  test(
    'a Corrida de 5 minutos só acaba aos 5 e grava o recorde dela',
    () async {
      await cubit.load();
      await cubit.selectDuration(RaceDuration.fiveMinutes);
      await cubit.start();
      await solveCurrent();
      now.advance(const Duration(minutes: 4));
      await cubit.tick();
      expect(cubit.state.phase, RacePhase.playing);
      now.advance(const Duration(minutes: 1));
      await cubit.tick();
      expect(cubit.state.phase, RacePhase.finished);
      expect(
        (await repository.record(duration: RaceDuration.fiveMinutes)).corrects,
        1,
      );
      expect((await repository.record()).isEmpty, isTrue);
    },
  );

  test('abre na introdução, com o banco e o recorde', () async {
    final stored = FakeRaceRepository(
      now: now,
      record: const RaceRecord(corrects: 14, hardest: 1620),
    );
    final cubit = RaceCubit(stored, now);
    await cubit.load();
    expect(cubit.state.phase, RacePhase.intro);
    expect(cubit.state.record.corrects, 14);
    expect(cubit.state.filter, const RaceFilter());
    await cubit.close();
  });

  test('começar abre o problema mais fácil e guarda a Corrida', () async {
    await cubit.load();
    await cubit.start();
    expect(cubit.state.phase, RacePhase.playing);
    expect(cubit.state.problem!.level, 300);
    expect(cubit.state.remaining, const Duration(minutes: 3));
    expect((await repository.ongoing())!.startedAt, now());
  });

  test('acerto soma, mostra o ícone de certo e sobe o nível', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    expect(cubit.state.run!.corrects, 1);
    expect(cubit.state.feedback, RaceFeedback.correct);
    expect(cubit.state.feedbackCount, 1);
    expect(cubit.state.problem!.level, 350);
  });

  test('erro gasta uma chance e a Corrida segue até o terceiro', () async {
    await cubit.load();
    await cubit.start();
    await cubit.answer(wrong);
    await cubit.answer(wrong);
    expect(cubit.state.phase, RacePhase.playing);
    expect(cubit.state.run!.errors, 2);
    expect(cubit.state.feedback, RaceFeedback.wrong);

    await cubit.answer(wrong);
    expect(cubit.state.phase, RacePhase.finished);
    expect(cubit.state.outcome!.result.end, RaceEnd.errors);
    expect(await repository.ongoing(), isNull);
  });

  test('o tempo acabando fecha a Corrida no tique', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    now.advance(const Duration(minutes: 2, seconds: 59));
    await cubit.tick();
    expect(cubit.state.phase, RacePhase.playing);
    expect(cubit.state.remaining, const Duration(seconds: 1));

    now.advance(const Duration(seconds: 1));
    await cubit.tick();
    expect(cubit.state.phase, RacePhase.finished);
    expect(cubit.state.outcome!.result.end, RaceEnd.time);
    expect(cubit.state.remaining, Duration.zero);
    expect(cubit.state.outcome!.isRecord, isTrue);
  });

  test('lance depois do tempo não vale', () async {
    await cubit.load();
    await cubit.start();
    now.advance(const Duration(minutes: 3, seconds: 1));
    await solveCurrent();
    expect(cubit.state.phase, RacePhase.finished);
    expect(cubit.state.outcome!.result.run.corrects, 0);
  });

  test('reabrir o app no meio continua do mesmo ponto', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    now.advance(const Duration(seconds: 30));

    final reopened = RaceCubit(repository, now, replyDelay: Duration.zero);
    await reopened.load();

    expect(reopened.state.phase, RacePhase.playing);
    expect(reopened.state.run!.corrects, 1);
    expect(reopened.state.remaining, const Duration(seconds: 150));
    expect(reopened.state.problem!.level, 350);
    await reopened.close();
  });

  test('reabrir o app depois dos 3 minutos mostra o resultado', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    now.advance(const Duration(minutes: 10));

    final reopened = RaceCubit(repository, now, replyDelay: Duration.zero);
    await reopened.load();

    expect(reopened.state.phase, RacePhase.finished);
    expect(reopened.state.outcome!.result.end, RaceEnd.time);
    expect(reopened.state.outcome!.result.run.corrects, 1);
    await reopened.close();
  });

  test('sair no meio descarta a Corrida: sem resultado e sem contar', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    await cubit.quit();
    expect(cubit.state.phase, RacePhase.intro);
    expect(cubit.state.outcome, isNull);
    expect(await repository.ongoing(), isNull);
    expect(await repository.history(), isEmpty);
    expect((await repository.record()).isEmpty, isTrue);
  });

  // Só o mate de dama (300) no banco de teste.
  const onlyQueen = RaceFilter(
    excluded: {'rook', 'pawnVsKing', 'knightBishopVsKing'},
  );

  test('o filtro limita os problemas aos tipos marcados', () async {
    await cubit.load();
    await cubit.applyFilter(onlyQueen);
    await cubit.start();
    expect(cubit.state.problem!.subcategory, 'queen');
    expect(cubit.state.run!.filter, onlyQueen);
  });

  test('o filtro escolhido persiste e volta na próxima abertura', () async {
    await cubit.load();
    await cubit.applyFilter(onlyQueen);
    expect(await repository.filter(), onlyQueen);
    final reopened = RaceCubit(repository, now);
    addTearDown(reopened.close);
    await reopened.load();
    expect(reopened.state.filter, onlyQueen);
    await reopened.applyFilter(const RaceFilter());
    expect(await repository.filter(), const RaceFilter());
  });

  test('um filtro sem problema no banco volta ao padrão', () async {
    final small = FakeRaceRepository(
      now: now,
      problems: raceTestProblems.take(2).toList(),
      filter: const RaceFilter(goal: RaceGoal.defend),
    );
    final cubit = RaceCubit(small, now);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.filter, const RaceFilter());
  });

  test('revisão passa pelos erros e volta ao resultado', () async {
    await cubit.load();
    await cubit.start();
    await cubit.answer(wrong);
    await solveCurrent();
    await cubit.answer(wrong);
    await cubit.answer(wrong);
    expect(cubit.state.phase, RacePhase.finished);
    expect(cubit.state.mistakes, hasLength(3));

    cubit.review();
    expect(cubit.state.phase, RacePhase.reviewing);
    cubit.nextMistake();
    cubit.nextMistake();
    expect(cubit.state.reviewIndex, 2);
    cubit.nextMistake();
    expect(cubit.state.phase, RacePhase.finished);
  });

  test('sem erros não há revisão', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    now.advance(const Duration(minutes: 3));
    await cubit.tick();
    cubit.review();
    expect(cubit.state.phase, RacePhase.finished);
  });

  group('sequência', () {
    test('lance ótimo no meio: a defesa responde sozinha e segue', () async {
      await cubit.load();
      await cubit.start();
      await solveCurrent(); // 300: mate em 1
      expect(cubit.state.problem!.id, 'race.350.01');
      final first = cubit.state.turn!;
      await cubit.answer('f6f7');
      // Ainda é o mesmo problema, na vez seguinte, com a resposta jogada.
      expect(cubit.state.problem!.id, 'race.350.01');
      expect(cubit.state.run!.answers, hasLength(1));
      expect(cubit.state.turn!.step, 1);
      expect(cubit.state.boardFen, first.after('f6f7')!.fen);
      expect(cubit.state.replying, isFalse);
      expect(cubit.state.feedbackCount, 1);
      await cubit.answer('a1h1');
      expect(cubit.state.run!.corrects, 2);
      expect(cubit.state.problem!.level, 400);
    });

    test('a outra linha ótima também vale', () async {
      await cubit.load();
      await cubit.start();
      await solveCurrent();
      await cubit.answer('f6g6');
      await cubit.answer('a1a8');
      expect(cubit.state.run!.corrects, 2);
    });

    test('no mate em 1, qualquer mate vale', () async {
      await cubit.load();
      await cubit.start();
      await cubit.answer('a1g7');
      expect(cubit.state.run!.corrects, 1);
    });

    test('enquanto a defesa responde, o tabuleiro não aceita lance', () async {
      final slow = RaceCubit(
        repository,
        now,
        replyDelay: const Duration(seconds: 1),
      );
      addTearDown(slow.close);
      await slow.load();
      await slow.start();
      await slow.answer('a1a8');
      final pending = slow.answer('f6f7');
      expect(slow.state.replying, isTrue);
      await slow.answer('f6g6'); // ignorado
      await pending;
      expect(slow.state.replying, isFalse);
      expect(slow.state.turn!.step, 1);
      expect(slow.state.run!.answers, hasLength(1));
    });

    test('lance que ganha mais devagar é erro, com o ótimo e o mate', () async {
      await cubit.load();
      await cubit.start();
      await cubit.answer('a1a2');
      expect(cubit.state.run!.corrects, 0);
      expect(cubit.state.feedback, RaceFeedback.wrong);
      final mistake = cubit.state.run!.answers.single;
      expect(mistake.slower, isTrue);
      expect(mistake.best, ['a1a8', 'a1g7']);
      expect(mistake.mateIn, 1);
      expect(mistake.fen, raceTestProblems.first.fen);
      // O erro (e o motivo) sobrevive ao histórico gravado.
      final round = RaceAnswer.fromJson(mistake.toJson());
      expect(round.slower, isTrue);
      expect(round.best, mistake.best);
      expect(round.distance, 1);
    });

    test('lance que não ganha é erro simples', () async {
      await cubit.load();
      await cubit.start();
      await cubit.answer(wrong);
      expect(cubit.state.run!.answers.single.slower, isFalse);
    });

    test('erro na segunda vez guarda a posição daquela vez', () async {
      await cubit.load();
      await cubit.start();
      await solveCurrent();
      await cubit.answer('f6f7');
      final fen = cubit.state.turn!.fen;
      await cubit.answer('a1a2');
      final mistake = cubit.state.run!.answers.last;
      expect(mistake.fen, fen);
      expect(mistake.best, ['a1h1']);
      expect(mistake.slower, isTrue);
      expect(mistake.problemId, 'race.350.01');
      // Errou, vai ao próximo problema da mesma faixa.
      expect(cubit.state.problem!.id, isNot('race.350.01'));
    });

    test('só sobe de faixa com acerto', () async {
      await cubit.load();
      await cubit.start();
      await cubit.answer(wrong);
      expect(cubit.state.problem!.bucket, 350); // só há um em 300: pula
      expect(cubit.state.run!.errors, 1);
    });

    test('evita os problemas das Corridas recentes', () async {
      final many = FakeRaceRepository(
        now: now,
        problems: [
          for (var i = 1; i <= 2; i++)
            RaceProblem(
              id: 'x.$i',
              fen: raceTestProblems.first.fen,
              tree: raceTestProblems.first.tree,
              category: 'basic',
              subcategory: 'queen',
              level: 300,
            ),
        ],
      );
      final first = RaceCubit(many, now, replyDelay: Duration.zero);
      addTearDown(first.close);
      await first.load();
      await first.start();
      final id = first.state.problem!.id;
      await first.answer('a1a8');
      await first.quit(); // descartada: não conta como recente
      now.advance(const Duration(minutes: 1));
      final second = RaceCubit(many, now, replyDelay: Duration.zero);
      addTearDown(second.close);
      await second.load();
      await second.start();
      await second.answer('a1a8');
      now.advance(const Duration(minutes: 3));
      await second.tick();
      expect(second.state.phase, RacePhase.finished);
      final played = second.state.run!.answers.single.problemId;
      now.advance(const Duration(minutes: 1));
      final third = RaceCubit(many, now, replyDelay: Duration.zero);
      addTearDown(third.close);
      await third.load();
      await third.start();
      expect(third.state.problem!.id, isNot(played));
      expect(id, isNotEmpty);
    });

    test(
      'jogar de novo na mesma tela também evita a Corrida que acabou',
      () async {
        final many = FakeRaceRepository(
          now: now,
          problems: [
            for (var i = 1; i <= 2; i++)
              RaceProblem(
                id: 'x.$i',
                fen: raceTestProblems.first.fen,
                tree: raceTestProblems.first.tree,
                category: 'basic',
                subcategory: 'queen',
                level: 300,
              ),
          ],
        );
        final cubit = RaceCubit(many, now, replyDelay: Duration.zero);
        addTearDown(cubit.close);
        await cubit.load();
        await cubit.start();
        final played = cubit.state.problem!.id;
        await cubit.answer('a1a8');
        now.advance(const Duration(minutes: 3));
        await cubit.tick();
        expect(cubit.state.phase, RacePhase.finished);
        expect(cubit.state.recent, contains(played));
        await cubit.start(); // o "Jogar de novo" do resultado
        expect(cubit.state.problem!.id, isNot(played));
      },
    );
  });

  group('aquecimento', () {
    test('passa pelos problemas fáceis, sem guardar nada', () async {
      final warmUp = RaceWarmUpCubit(repository, replyDelay: Duration.zero);
      await warmUp.load();
      expect(warmUp.state.problems, hasLength(5));
      Future<void> solve() async {
        final done = warmUp.state.results.length;
        while (warmUp.state.results.length == done) {
          await warmUp.answer(
            warmUp.state.turn?.node.moves.keys.first ??
                warmUp.state.problem!.tree.moves.keys.first,
          );
        }
      }

      await solve();
      await warmUp.answer(wrong);
      expect(warmUp.state.results, [true, false]);
      await solve();
      await solve();
      await solve();
      expect(warmUp.state.done, isTrue);
      expect(warmUp.state.corrects, 4);
      expect(warmUp.state.problem, isNull);
      expect(await repository.history(), isEmpty);
      await warmUp.close();
    });
  });

  group('ligações (E1.34)', () {
    test('a Corrida só de um tipo usa o filtro dele sem gravá-lo', () async {
      final only = RaceCubit(
        repository,
        now,
        replyDelay: Duration.zero,
        onlySubcategory: 'rook',
      );
      addTearDown(only.close);
      await only.load();
      expect(only.state.filter.matches(raceTestProblems[1]), isTrue);
      expect(only.state.filter.matches(raceTestProblems[0]), isFalse);
      expect(await repository.filter(), const RaceFilter());
    });

    test('tipo sem problemas no banco cai no filtro de sempre', () async {
      final only = RaceCubit(
        repository,
        now,
        replyDelay: Duration.zero,
        onlySubcategory: 'queenVsRook',
      );
      addTearDown(only.close);
      await only.load();
      expect(only.state.filter, const RaceFilter());
    });

    test('a Corrida conta para o diagnóstico ao acabar', () async {
      await cubit.load();
      expect(cubit.state.diagnosis.runs, 0);
      await cubit.start();
      for (var i = 0; i < 3; i++) {
        await cubit.answer(wrong);
      }
      expect(cubit.state.phase, RacePhase.finished);
      expect(cubit.state.diagnosis.runs, 1);
      expect(cubit.state.diagnosis.ready, isFalse);
    });
  });
}
