import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/coach/coach_preferences.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/coach/view_models/coach_game_cubit.dart';

import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/coach_fixtures.dart';
import 'coach_harness.dart';

/// Um repositório em que o pedido de análise espera o teste soltar.
class _RepoWithGate extends FakeCoachRepository {
  _RepoWithGate()
    : super(account: CoachFixtures.account, games: CoachFixtures.list());

  final gate = Completer<void>();

  @override
  Future<void> analyze(String id, {bool notify = true}) async {
    await gate.future;
    return super.analyze(id, notify: notify);
  }
}

/// Um repositório cujo pedido de análise falha com um erro qualquer.
class _RepoThatBreaks extends FakeCoachRepository {
  _RepoThatBreaks()
    : super(account: CoachFixtures.account, games: CoachFixtures.list());

  @override
  Future<void> analyze(String id, {bool notify = true}) =>
      Future.error(StateError('sem rede'));
}

/// Um repositório cuja leitura da partida falha.
class _RepoWithError extends FakeCoachRepository {
  _RepoWithError() : super(account: CoachFixtures.account);

  bool fail = true;

  @override
  Stream<CoachGame?> game(String id) =>
      fail ? Stream.error(StateError('sem rede')) : super.game(id);
}

/// Preferências em que gravar espera o teste soltar.
class _PrefsWithGate extends MemoryPreferences {
  final gate = Completer<void>();

  @override
  Future<void> setString(String key, String value) async {
    await gate.future;
    return super.setString(key, value);
  }
}

void main() {
  const idNew = 'lichess_DeF67890';
  const idAnalyzing = 'lichess_GhI13579';

  late CoachBed bed;

  CoachGameCubit create(String id, {CoachBed? b, FakeCoachRepository? repo}) {
    final base = b ?? bed;
    final c = CoachGameCubit(
      id: id,
      repository: repo ?? base.repo,
      grants: base.grants,
      preferences: base.preferences,
      now: base.now,
    );
    addTearDown(c.close);
    return c;
  }

  setUp(() => bed = CoachBed());

  group('load', () {
    test('partida pronta: carrega e mostra os exercícios', () async {
      final c = create(CoachFixtures.idTiago);
      expect(c.state.loading, isTrue);
      await c.load();
      await pumpEventQueue();
      expect(c.state.loading, isFalse);
      expect(c.state.game?.ready, isTrue);
      expect(c.state.game?.exercises, hasLength(4));
      expect(c.state.notFound, isFalse);
      expect(c.state.analysisStart, isNull);
    });

    test('partida que não existe: naoEncontrada', () async {
      final c = create('lichess_naoExiste');
      await c.load();
      await pumpEventQueue();
      expect(c.state.notFound, isTrue);
      expect(c.state.game, isNull);
    });

    test('sem plano: acesso falso; com plano: verdadeiro', () async {
      final without = create(idNew);
      await without.load();
      expect(without.state.grant, isFalse);

      final b = CoachBed(grants: withPlan());
      final withValue = create(idNew, b: b);
      await withValue.load();
      expect(withValue.state.grant, isTrue);
    });

    test(
      'o plano comprado enquanto a tela está aberta chega ao estado',
      () async {
        final c = create(idNew);
        await c.load();
        bed.grants.current = withPlan();
        await pumpEventQueue();
        expect(c.state.grant, isTrue);
      },
    );

    test('falha de leitura: falhou; tentar de novo recupera', () async {
      final repo = _RepoWithError();
      repo.currentGames = CoachFixtures.list();
      final c = create(idNew, repo: repo);
      await c.load();
      await pumpEventQueue();
      expect(c.state.failed, isTrue);
      expect(c.state.loading, isFalse);
      expect(c.state.notFound, isFalse);

      repo.fail = false;
      c.retry();
      expect(c.state.loading, isTrue);
      await pumpEventQueue();
      expect(c.state.failed, isFalse);
      expect(c.state.game?.id, idNew);
    });

    test('fechar durante a carga não emite depois', () async {
      final c = create(idNew);
      final payload = c.load();
      await c.close();
      await payload;
      expect(c.isClosed, isTrue);
    });
  });

  group('pedir a análise', () {
    test(
      'fila, analisando e pronta: o início é marcado e depois esquecido',
      () async {
        final c = create(idNew);
        await c.load();
        await pumpEventQueue();
        expect(c.state.game?.status, GameStatus.newGame);

        final request = c.analyze();
        expect(c.state.request, AnalysisRequest.sending);
        expect(await request, isTrue);
        await pumpEventQueue();

        expect(bed.repo.analysisRequests, [(idNew, false)]);
        expect(c.state.request, AnalysisRequest.none);
        expect(c.state.game?.status, GameStatus.analyzing);
        expect(c.state.analysisStart, bed.now());
        expect(await bed.preferences.startOfAnalysis(idNew), bed.now().toUtc());

        // O servidor termina a análise.
        bed.repo.perGame(
          withStatus(
            CoachFixtures.list().firstWhere((p) => p.id == idNew),
            GameStatus.ready,
          ),
        );
        await pumpEventQueue();
        expect(c.state.game?.status, GameStatus.ready);
        expect(c.state.analysisStart, isNull);
        expect(await bed.preferences.startOfAnalysis(idNew), isNull);
      },
    );

    test('na fila do servidor: não conta tempo (a barra não anda)', () async {
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      final newGame = CoachFixtures.list().firstWhere((p) => p.id == idNew);
      bed.repo.perGame(withStatus(newGame, GameStatus.queued));
      await pumpEventQueue();
      expect(c.state.game?.status, GameStatus.queued);
      expect(c.state.analysisStart, isNull);
      expect(await bed.preferences.startOfAnalysis(idNew), isNull);

      // O início só vale quando a análise começa de verdade.
      bed.repo.perGame(withStatus(newGame, GameStatus.analyzing));
      await pumpEventQueue();
      expect(c.state.analysisStart, bed.now());
    });

    test('lê quantos exercícios a análise gera', () async {
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      expect(c.state.expectedExercises, CoachConfig.standard.exercisesPerGame);
    });

    test('reabrir a tela em análise mantém o início de onde estava', () async {
      final start = bed.now().subtract(const Duration(seconds: 90));
      await bed.preferences.markStart(idAnalyzing, start);
      final c = create(idAnalyzing);
      await c.load();
      await pumpEventQueue();
      expect(c.state.analysisStart, start);
      expect(WaitPercentage.of(c.state.analysisStart, bed.now()), 60);
    });

    test(
      'partida já em análise sem início salvo: começa a contar agora',
      () async {
        final c = create(idAnalyzing);
        await c.load();
        await pumpEventQueue();
        expect(c.state.game?.status, GameStatus.analyzing);
        expect(c.state.analysisStart, bed.now());
        expect(
          await bed.preferences.startOfAnalysis(idAnalyzing),
          bed.now().toUtc(),
        );
      },
    );

    test('segundo pedido enquanto envia é ignorado', () async {
      final repo = _RepoWithGate();
      final b = CoachBed(repo: repo);
      final c = create(idNew, b: b);
      await c.load();
      await pumpEventQueue();

      final firstOne = c.analyze();
      expect(await c.analyze(), isFalse);
      repo.gate.complete();
      expect(await firstOne, isTrue);
      expect(repo.analysisRequests, hasLength(1));
    });

    test('cota do grátis esgotada: pedido vira cota', () async {
      bed.repo
        ..analyzeFailure = 'permission-denied'
        ..analyzeReason = 'cota';
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      expect(await c.analyze(), isFalse);
      expect(c.state.request, AnalysisRequest.quota);
      expect(c.state.analysisStart, isNull);
      expect(await bed.preferences.startOfAnalysis(idNew), isNull);
    });

    test('teto do mês do assinante: recusado', () async {
      bed.repo
        ..analyzeFailure = 'permission-denied'
        ..analyzeReason = 'teto';
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      expect(await c.analyze(), isFalse);
      expect(c.state.request, AnalysisRequest.refused);
    });

    test('permission-denied sem motivo: recusado', () async {
      bed.repo.analyzeFailure = 'permission-denied';
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      await c.analyze();
      expect(c.state.request, AnalysisRequest.refused);
    });

    test('outro código do servidor: falhou', () async {
      bed.repo.analyzeFailure = 'unavailable';
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      expect(await c.analyze(), isFalse);
      expect(c.state.request, AnalysisRequest.failed);
    });

    test('erro qualquer (sem rede): falhou', () async {
      final repo = _RepoThatBreaks();
      final c = create(idNew, repo: repo);
      await c.load();
      await pumpEventQueue();
      expect(await c.analyze(), isFalse);
      expect(c.state.request, AnalysisRequest.failed);
    });

    test('pedidoVisto limpa a recusa e deixa pedir de novo', () async {
      bed.repo.analyzeFailure = 'unavailable';
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      await c.analyze();
      expect(c.state.request, AnalysisRequest.failed);
      c.requestSeen();
      expect(c.state.request, AnalysisRequest.none);

      bed.repo.analyzeFailure = null;
      expect(await c.analyze(), isTrue);
      expect(bed.repo.analysisRequests, hasLength(2));
    });

    test('partida em erro: tentar de novo pede a análise outra vez', () async {
      final error = withStatus(
        CoachFixtures.list().firstWhere((p) => p.id == idNew),
        GameStatus.error,
        errorReason: 'timeout',
      );
      bed.repo.perGame(error);
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      expect(c.state.game?.status, GameStatus.error);
      expect(c.state.game?.canRedo, isTrue);

      expect(await c.analyze(), isTrue);
      await pumpEventQueue();
      expect(c.state.game?.status, GameStatus.analyzing);
    });

    test('analisar com o fake que conclui: termina pronta', () async {
      bed.repo.analyzeCompletes = true;
      final c = create(idNew);
      await c.load();
      await pumpEventQueue();
      expect(await c.analyze(), isTrue);
      await pumpEventQueue();
      expect(c.state.game?.status, GameStatus.ready);
      expect(c.state.game?.exercises, isNotEmpty);
    });

    // BUG (treinador_partida_cubit.dart, _pedir): se a partida já ficou pronta
    // antes de analisar() voltar, o início é gravado depois e a espera nunca
    // zera (a tela mostra "Carregando" só em andamento, mas a pref fica).
    test(
      'pedido que volta depois da partida pronta não deixa início preso',
      () async {
        bed.repo.analyzeCompletes = true;
        final c = create(idNew);
        await c.load();
        await pumpEventQueue();
        await c.analyze();
        await pumpEventQueue();
        expect(c.state.game?.status, GameStatus.ready);
        expect(c.state.analysisStart, isNull);
        expect(await bed.preferences.startOfAnalysis(idNew), isNull);
      },
    );

    // BUG (treinador_partida_cubit.dart, _chegou): o evento "analisando"
    // espera a gravação do início e pode emitir depois do evento "pronta".
    test('eventos seguidos analisando e pronta terminam em pronta', () async {
      final prefs = _PrefsWithGate();
      final b = CoachBed(prefs: prefs);
      final c = create(idNew, b: b);
      await c.load();
      await pumpEventQueue();

      b.repo.perGame(
        withStatus(
          CoachFixtures.list().firstWhere((p) => p.id == idNew),
          GameStatus.analyzing,
        ),
      );
      await pumpEventQueue();
      b.repo.perGame(
        withStatus(
          CoachFixtures.list().firstWhere((p) => p.id == idNew),
          GameStatus.ready,
        ),
      );
      await pumpEventQueue();
      prefs.gate.complete();
      await pumpEventQueue();
      expect(c.state.game?.status, GameStatus.ready);
    });
  });

  group('me avise quando terminar', () {
    test('pede de novo com aviso ligado, sem mexer no estado', () async {
      final c = create(idAnalyzing);
      await c.load();
      await pumpEventQueue();
      final before = c.state.request;
      await c.notifyMe();
      expect(bed.repo.analysisRequests, [(idAnalyzing, true)]);
      expect(c.state.request, before);
    });

    test('a falha do pedido não chega à tela', () async {
      bed.repo.analyzeFailure = 'permission-denied';
      final c = create(idAnalyzing);
      await c.load();
      await pumpEventQueue();
      await c.notifyMe();
      expect(c.state.request, AnalysisRequest.none);
    });

    test('erro qualquer também é engolido', () async {
      final c = create(idAnalyzing, repo: _RepoThatBreaks());
      await c.load();
      await pumpEventQueue();
      await expectLater(c.notifyMe(), completes);
    });
  });

  group('PorcentagemDaEspera', () {
    final start = DateTime.utc(2026, 11, 9, 12);

    test('sem início: 0', () {
      expect(WaitPercentage.of(null, start), 0);
    });

    test('no instante do início ou antes: 0', () {
      expect(WaitPercentage.of(start, start), 0);
      expect(
        WaitPercentage.of(start, start.subtract(const Duration(seconds: 5))),
        0,
      );
    });

    test('anda depressa no começo', () {
      final p = WaitPercentage.of(
        start,
        start.add(const Duration(seconds: 10)),
      );
      expect(p, inInclusiveRange(9, 12));
    });

    test('com 90 s está em 60%', () {
      expect(
        WaitPercentage.of(start, start.add(const Duration(seconds: 90))),
        60,
      );
    });

    test('nunca passa do teto de 95%', () {
      expect(
        WaitPercentage.of(start, start.add(const Duration(hours: 3))),
        WaitPercentage.ceiling,
      );
    });

    test('só cresce com o tempo', () {
      var previous = -1;
      for (var s = 0; s <= 600; s += 15) {
        final p = WaitPercentage.of(start, start.add(Duration(seconds: s)));
        expect(p, greaterThanOrEqualTo(previous));
        previous = p;
      }
    });
  });

  test('o início da análise usa a chave do aparelho esperada', () async {
    await bed.preferences.markStart(idNew, bed.now());
    expect(bed.memory.values[CoachPreferences.startKey(idNew)], isNotNull);
  });
}
