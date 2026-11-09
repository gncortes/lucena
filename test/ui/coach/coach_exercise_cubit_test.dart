import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/data/repositories/coach/coach_preferences.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/coach/view_models/coach_exercise_cubit.dart';

import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/coach_fixtures.dart';
import 'coach_harness.dart';

/// O salvar progresso falha (o espelho do servidor fora do ar).
class _RepoNoSave extends FakeCoachRepository {
  _RepoNoSave()
    : super(account: CoachFixtures.account, games: [CoachFixtures.tiago()]);

  @override
  Future<void> saveProgress(String id, GameProgress progress) =>
      Future.error(StateError('sem rede'));
}

void main() {
  const id = CoachFixtures.idTiago;
  // Soluções dos quatro exercícios da fixture.
  const rightCount = ['d3h7', 'f7f6', 'h5g3', 'b8c8'];

  late FakeCoachRepository repo;

  FakeCoachRepository newRepo({List<CoachGame>? games, GameProgress? saved}) {
    final r = FakeCoachRepository(
      account: CoachFixtures.account,
      games: games ?? [CoachFixtures.tiago()],
    );
    return r;
  }

  CoachExerciseCubit create({
    FakeCoachRepository? r,
    bool redo = false,
    String game = id,
  }) {
    final c = CoachExerciseCubit(
      id: game,
      repository: r ?? repo,
      preferences: CoachPreferences(MemoryPreferences()),
      redo: redo,
    );
    addTearDown(c.close);
    return c;
  }

  Future<CoachExerciseCubit> isOpen({bool redo = false}) async {
    final c = create(redo: redo);
    await c.load();
    return c;
  }

  setUp(() => repo = newRepo());

  group('load', () {
    test('partida pronta: abre o primeiro exercício, jogando', () async {
      final c = await isOpen();
      expect(c.state.phase, ExerciseStep.playing);
      expect(c.state.index, 0);
      expect(c.state.total, 4);
      expect(c.state.fen, CoachFixtures.fenGreekGift);
      expect(c.state.attempts, 1);
      expect(c.state.progress.doneCount, 0);
      expect(c.state.lastMoveOfGame, isNull);
    });

    test('partida que não existe: indisponível', () async {
      final c = create(game: 'lichess_nao');
      await c.load();
      expect(c.state.phase, ExerciseStep.unavailable);
    });

    test('partida pronta sem exercícios: indisponível', () async {
      repo = newRepo(games: [CoachFixtures.tiago(exercises: 0)]);
      final c = await isOpen();
      expect(c.state.phase, ExerciseStep.unavailable);
    });

    test('espera a partida ficar pronta e abre quando chega', () async {
      repo = newRepo(games: [CoachFixtures.tiago(status: 'analisando')]);
      final c = create();
      final payload = c.load();
      await pumpEventQueue();
      expect(c.state.phase, ExerciseStep.loading);

      repo.perGame(CoachFixtures.tiago());
      await payload;
      expect(c.state.phase, ExerciseStep.playing);
    });

    testWidgets('partida que nunca fica pronta: offline em 8 s', (
      tester,
    ) async {
      repo = newRepo(games: [CoachFixtures.tiago(status: 'analisando')]);
      final c = create();
      unawaited(c.load());
      await tester.pump(const Duration(seconds: 7));
      expect(c.state.phase, ExerciseStep.loading);
      await tester.pump(const Duration(seconds: 2));
      expect(c.state.phase, ExerciseStep.offline);
    });

    test('fechar à força depois de errar guarda a tentativa', () async {
      final prefs = CoachPreferences(MemoryPreferences());
      CoachExerciseCubit isNew() {
        final c = CoachExerciseCubit(
          id: id,
          repository: repo,
          preferences: prefs,
        );
        addTearDown(c.close);
        return c;
      }

      final c = isNew();
      await c.load();
      final pos = GameRules.fromFen(c.state.exercise!.fen)!;
      // O primeiro lance legal que não é a solução.
      final uci = [
        for (final e in GameRules.legalMoves(pos).entries)
          for (final to in e.value) NormalMove(from: e.key, to: to).uci,
      ].firstWhere((u) => !c.state.exercise!.accepts(u));
      await c.play(uci);
      expect(c.state.phase, ExerciseStep.missed);

      // Fechou à força: abre de novo, e o acerto já vale a tentativa 2.
      final reopened = isNew();
      await reopened.load();
      expect(reopened.state.attempts, 2);
      await reopened.play(rightCount[0]);
      expect(reopened.state.progress.results.single.points, 1);
      expect(await prefs.attempts(id, 1), 1);
    });

    test('retoma do exercício seguinte ao último feito', () async {
      await repo.saveProgress(
        id,
        const GameProgress().withValue(
          const ExerciseResult(n: 1, solved: true, points: 3),
        ),
      );
      final c = await isOpen();
      expect(c.state.phase, ExerciseStep.playing);
      expect(c.state.index, 1);
      expect(c.state.fen, c.state.exercises[1].fen);
      expect(c.state.progress.doneCount, 1);
    });

    test('tudo feito: abre direto na pontuação (fim)', () async {
      var p = const GameProgress();
      for (var n = 1; n <= 4; n++) {
        p = p.withValue(ExerciseResult(n: n, solved: true, points: 3));
      }
      await repo.saveProgress(id, p);
      final c = await isOpen();
      expect(c.state.phase, ExerciseStep.end);
      expect(c.state.progress.corrects, 4);
      expect(c.state.index, 3);
    });

    test('refazer: começa do 1 e só grava com o primeiro resultado', () async {
      var p = const GameProgress();
      for (var n = 1; n <= 4; n++) {
        p = p.withValue(ExerciseResult(n: n, solved: true, points: 3));
      }
      await repo.saveProgress(id, p);
      final c = await isOpen(redo: true);
      expect(c.state.phase, ExerciseStep.playing);
      expect(c.state.index, 0);
      expect(c.state.progress.doneCount, 0);
      // Sair agora deixa a partida no resumo.
      expect((await repo.progress(id)).doneCount, 4);
      await c.seeSolution();
      expect((await repo.progress(id)).doneCount, 1);
    });
  });

  group('jogar', () {
    test(
      'lance certo: acertou, tabuleiro na posição depois do lance',
      () async {
        final c = await isOpen();
        await c.play('d3h7');
        expect(c.state.phase, ExerciseStep.solved);
        expect(c.state.lastMoveOfGame, 'd3h7');
        expect(c.state.fen, isNot(CoachFixtures.fenGreekGift));
        expect(c.state.progress.doneCount, 1);
        expect(c.state.progress.corrects, 1);
        expect(c.state.progress.points, 3);
        expect(c.state.saving, isFalse);
      },
    );

    test('acerto salva o progresso no repositório', () async {
      final c = await isOpen();
      await c.play('d3h7');
      final saved = await repo.progress(id);
      expect(saved.doneCount, 1);
      expect(saved.results.single.n, 1);
      expect(saved.results.single.points, 3);
    });

    test('lance errado: errou, nada salvo ainda', () async {
      final c = await isOpen();
      await c.play('a2a3');
      expect(c.state.phase, ExerciseStep.missed);
      expect(c.state.lastMoveOfGame, 'a2a3');
      expect(c.state.progress.doneCount, 0);
      expect((await repo.progress(id)).doneCount, 0);
    });

    test('lance ilegal ou sem sentido é ignorado', () async {
      final c = await isOpen();
      await c.play('e2e7');
      expect(c.state.phase, ExerciseStep.playing);
      await c.play('lixo');
      expect(c.state.phase, ExerciseStep.playing);
    });

    test('depois de acertar, outro lance não conta', () async {
      final c = await isOpen();
      await c.play('d3h7');
      await c.play('a2a3');
      expect(c.state.phase, ExerciseStep.solved);
      expect(c.state.progress.doneCount, 1);
    });

    test('lance aceito alternativo também acerta', () async {
      final c = await isOpen();
      final accepted = c.state.exercise!.accepted;
      if (accepted.isEmpty) return;
      await c.play(accepted.first);
      expect(c.state.phase, ExerciseStep.solved);
    });
  });

  group('tentar de novo', () {
    test('errou: volta à posição e conta mais uma tentativa', () async {
      final c = await isOpen();
      await c.play('a2a3');
      c.retry();
      expect(c.state.phase, ExerciseStep.playing);
      expect(c.state.attempts, 2);
      expect(c.state.fen, CoachFixtures.fenGreekGift);
      expect(c.state.lastMoveOfGame, isNull);
    });

    test('acertar na segunda tentativa vale 1 ponto', () async {
      final c = await isOpen();
      await c.play('a2a3');
      c.retry();
      await c.play('d3h7');
      expect(c.state.progress.points, 1);
      expect(c.state.progress.corrects, 1);
      expect(c.state.progress.results.single.attempts, 2);
    });

    test('só vale depois de errar', () async {
      final c = await isOpen();
      c.retry();
      expect(c.state.attempts, 1);
      expect(c.state.phase, ExerciseStep.playing);
    });
  });

  group('ver a solução', () {
    test('depois de errar: mostra a solução e vale 0', () async {
      final c = await isOpen();
      await c.play('a2a3');
      await c.seeSolution();
      expect(c.state.phase, ExerciseStep.solution);
      expect(c.state.fen, CoachFixtures.fenGreekGift);
      expect(c.state.progress.doneCount, 1);
      expect(c.state.progress.corrects, 0);
      expect(c.state.progress.points, 0);
      final r = c.state.progress.results.single;
      expect(r.sawSolution, isTrue);
      expect(r.solved, isFalse);
    });

    test('direto, sem errar antes (jogando)', () async {
      final c = await isOpen();
      await c.seeSolution();
      expect(c.state.phase, ExerciseStep.solution);
      expect(c.state.progress.points, 0);
    });

    test('ver a solução salva o progresso', () async {
      final c = await isOpen();
      await c.seeSolution();
      expect((await repo.progress(id)).results.single.sawSolution, isTrue);
    });

    test('não vale depois de acertar', () async {
      final c = await isOpen();
      await c.play('d3h7');
      await c.seeSolution();
      expect(c.state.phase, ExerciseStep.solved);
      expect(c.state.progress.corrects, 1);
    });
  });

  group('próximo', () {
    test(
      'depois de acertar abre o exercício seguinte, zerando tentativas',
      () async {
        final c = await isOpen();
        await c.play('a2a3');
        c.retry();
        await c.play('d3h7');
        c.next();
        expect(c.state.phase, ExerciseStep.playing);
        expect(c.state.index, 1);
        expect(c.state.attempts, 1);
        expect(c.state.fen, c.state.exercises[1].fen);
        expect(c.state.lastMoveOfGame, isNull);
      },
    );

    test('depois da solução também avança', () async {
      final c = await isOpen();
      await c.seeSolution();
      c.next();
      expect(c.state.index, 1);
      expect(c.state.phase, ExerciseStep.playing);
    });

    test('não avança jogando nem errado', () async {
      final c = await isOpen();
      c.next();
      expect(c.state.index, 0);
      await c.play('a2a3');
      c.next();
      expect(c.state.index, 0);
      expect(c.state.phase, ExerciseStep.missed);
    });

    test('no último, vai para a pontuação (fim)', () async {
      final c = await isOpen();
      for (var i = 0; i < 4; i++) {
        await c.play(rightCount[i]);
        expect(
          c.state.phase,
          ExerciseStep.solved,
          reason: 'exercício ${i + 1}',
        );
        c.next();
      }
      expect(c.state.phase, ExerciseStep.end);
      expect(c.state.progress.doneCount, 4);
      expect(c.state.progress.corrects, 4);
      expect(c.state.progress.points, 12);
      expect(c.state.progress.isComplete(4), isTrue);
    });

    test('mistura de acertos, erro e solução soma os pontos certos', () async {
      final c = await isOpen();
      await c.play('d3h7'); // 3
      c.next();
      await c.play('a7a6'); // errado
      c.retry();
      await c.play('f7f6'); // 1
      c.next();
      await c.seeSolution(); // 0
      c.next();
      await c.play('b8c8'); // 3
      c.next();
      expect(c.state.phase, ExerciseStep.end);
      expect(c.state.progress.points, 7);
      expect(c.state.progress.corrects, 3);
      expect(c.state.progress.doneCount, 4);
    });
  });

  group('progresso salvo', () {
    test('reabrir o cubit depois de salvar mostra o progresso novo', () async {
      final c = await isOpen();
      await c.play('d3h7');
      c.next();
      await c.play('f7f6');
      await c.close();

      final other = await isOpen();
      expect(other.state.phase, ExerciseStep.playing);
      expect(other.state.index, 2);
      expect(other.state.progress.doneCount, 2);
      expect(other.state.progress.points, 6);
    });

    test('o espelho da lista ouve o progresso salvo', () async {
      final c = await isOpen();
      await c.play('d3h7');
      final p = await repo.games().first;
      expect(p.single.progress?.doneCount, 1);
    });

    test('falha ao salvar não derruba o exercício', () async {
      final c = create(r: _RepoNoSave());
      await c.load();
      await c.play('d3h7');
      expect(c.state.phase, ExerciseStep.solved);
      expect(c.state.progress.doneCount, 1);
      expect(c.state.saving, isFalse);
    });

    test('acertos refeitos no mesmo número substituem o resultado', () async {
      final c = await isOpen();
      await c.seeSolution();
      expect(c.state.progress.results, hasLength(1));
      await c.close();
      // refazer zera tudo e o 1 volta a valer 3.
      final of = await isOpen(redo: true);
      await of.play('d3h7');
      expect(of.state.progress.results, hasLength(1));
      expect(of.state.progress.points, 3);
    });
  });

  group('dica', () {
    String wrong(CoachExerciseCubit c) {
      final pos = GameRules.fromFen(c.state.exercise!.fen)!;
      return [
        for (final e in GameRules.legalMoves(pos).entries)
          for (final to in e.value) NormalMove(from: e.key, to: to).uci,
      ].firstWhere((u) => !c.state.exercise!.accepts(u));
    }

    test('cada dica desce um degrau e para no lance mostrado', () async {
      final c = await isOpen();
      expect(c.state.counts, 3);
      expect(c.state.canHint, isTrue);

      c.hint();
      expect(c.state.hints, 1);
      expect(c.state.counts, 2);

      c.hint();
      expect(c.state.hints, 2);
      expect(c.state.counts, 1);
      expect(c.state.canHint, isFalse);

      c.hint();
      expect(c.state.hints, 2);
    });

    test('acertar com uma dica vale 2 e não conta como de primeira', () async {
      final c = await isOpen();
      c.hint();
      await c.play(rightCount[0]);

      final r = c.state.progress.results.single;
      expect(r.points, 2);
      expect(r.hints, 1);
      expect(c.state.progress.firstOnes[1], isFalse);
    });

    test('dica depois de errar zera o exercício', () async {
      final c = await isOpen();
      await c.play(wrong(c));
      c.retry();
      c.hint();
      expect(c.state.counts, 0);
      await c.play(rightCount[0]);
      expect(c.state.progress.results.single.points, 0);
    });

    test('só jogando: errado ou resolvido não pede dica', () async {
      final c = await isOpen();
      await c.play(wrong(c));
      c.hint();
      expect(c.state.hints, 0);

      c.retry();
      await c.play(rightCount[0]);
      c.hint();
      expect(c.state.hints, 0);
    });

    test('o próximo exercício começa sem dica', () async {
      final c = await isOpen();
      c.hint();
      await c.play(rightCount[0]);
      c.next();
      expect(c.state.index, 1);
      expect(c.state.hints, 0);
      expect(c.state.counts, 3);
    });

    test('fechar à força guarda as dicas, também depois do erro', () async {
      final prefs = CoachPreferences(MemoryPreferences());
      CoachExerciseCubit isNew() {
        final c = CoachExerciseCubit(
          id: id,
          repository: repo,
          preferences: prefs,
        );
        addTearDown(c.close);
        return c;
      }

      final c = isNew();
      await c.load();
      c.hint();
      await pumpEventQueue();

      final reopened = isNew();
      await reopened.load();
      expect(reopened.state.hints, 1);
      expect(reopened.state.attempts, 1);

      await reopened.play(wrong(reopened));
      await pumpEventQueue();
      final third = isNew();
      await third.load();
      expect(third.state.attempts, 2);
      expect(third.state.hints, 1);

      await third.play(rightCount[0]);
      expect(third.state.progress.results.single.points, 0);
      expect(await prefs.hints(id, 1), 0);
    });
  });

  test('fechar durante a carga não emite depois', () async {
    final c = create();
    final payload = c.load();
    await c.close();
    await payload;
    expect(c.isClosed, isTrue);
  });
}
