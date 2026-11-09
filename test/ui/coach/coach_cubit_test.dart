import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/domain/use_cases/coach/coach_rules.dart';
import 'package:lucena/ui/coach/view_models/coach_cubit.dart';

import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/coach_fixtures.dart';
import 'coach_harness.dart';

/// Um repositório cujas leituras falham (sem rede na primeira vez).
class _RepoWithError extends FakeCoachRepository {
  _RepoWithError()
    : super(
        account: CoachFixtures.account,
        games: CoachFixtures.list(),
        stats: CoachFixtures.stats(),
      );

  bool fail = true;

  @override
  Stream<List<CoachGame>> games() =>
      fail ? Stream.error(StateError('sem rede')) : super.games();
}

/// As partidas falham na hora e a conta (do cache) chega depois.
class _RepoAccountLater extends FakeCoachRepository {
  _RepoAccountLater() : super(account: CoachFixtures.account);

  @override
  Stream<List<CoachGame>> games() => Stream.error(StateError('sem rede'));

  @override
  Stream<CoachAccount?> account() async* {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield CoachFixtures.account;
  }
}

void main() {
  late CoachBed bed;
  late CoachCubit cubit;

  CoachCubit create(CoachBed b) {
    final c = CoachCubit(
      repository: b.repo,
      grants: b.grants,
      preferences: b.preferences,
      now: b.now,
    );
    addTearDown(c.close);
    return c;
  }

  setUp(() {
    bed = CoachBed();
    cubit = create(bed);
  });

  test('começa carregando, sem conta e sem plano', () {
    expect(cubit.state.loading, isTrue);
    expect(cubit.state.noAccount, isFalse);
    expect(cubit.state.grant, isFalse);
  });

  group('load', () {
    test(
      'com conta e partidas: lista da mais nova para a mais antiga',
      () async {
        await cubit.load();
        await pumpEventQueue();
        final s = cubit.state;
        expect(s.loading, isFalse);
        expect(s.failed, isFalse);
        expect(s.account, CoachFixtures.account);
        expect(s.games, hasLength(5));
        expect(s.last?.id, CoachFixtures.idTiago);
        expect(s.noAccount, isFalse);
      },
    );

    test('sem conta ligada: semConta', () async {
      bed = CoachBed(repo: FakeCoachRepository());
      cubit = create(bed);
      await cubit.load();
      await pumpEventQueue();
      expect(cubit.state.noAccount, isTrue);
      expect(cubit.state.games, isEmpty);
      expect(cubit.state.last, isNull);
    });

    test('conta ligada e sem partidas: lista vazia, sem carregar', () async {
      bed = CoachBed(repo: FakeCoachRepository(account: CoachFixtures.account));
      cubit = create(bed);
      await cubit.load();
      await pumpEventQueue();
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.noAccount, isFalse);
      expect(cubit.state.games, isEmpty);
    });

    test('sem plano: acesso falso', () async {
      await cubit.load();
      expect(cubit.state.grant, isFalse);
    });

    test('com plano: acesso verdadeiro', () async {
      bed = CoachBed(grants: withPlan());
      cubit = create(bed);
      await cubit.load();
      expect(cubit.state.grant, isTrue);
    });

    test('o plano comprado depois chega sem recarregar', () async {
      await cubit.load();
      expect(cubit.state.grant, isFalse);
      bed.grants.current = withPlan();
      await pumpEventQueue();
      expect(cubit.state.grant, isTrue);
    });

    test('o plano que acaba tira o acesso', () async {
      bed = CoachBed(grants: withPlan());
      cubit = create(bed);
      await cubit.load();
      bed.grants.current = CourseGrants.empty;
      await pumpEventQueue();
      expect(cubit.state.grant, isFalse);
    });

    test('partida nova do servidor entra na lista', () async {
      await cubit.load();
      await pumpEventQueue();
      final newGame = withStatus(CoachFixtures.list()[1], GameStatus.ready);
      bed.repo.perGame(newGame);
      await pumpEventQueue();
      expect(
        cubit.state.games.firstWhere((p) => p.id == newGame.id).ready,
        isTrue,
      );
    });

    test('conta ligada depois: sai de semConta', () async {
      bed = CoachBed(repo: FakeCoachRepository());
      cubit = create(bed);
      await cubit.load();
      await pumpEventQueue();
      expect(cubit.state.noAccount, isTrue);
      bed.repo.currentAccount = CoachFixtures.account;
      await pumpEventQueue();
      expect(cubit.state.noAccount, isFalse);
      expect(cubit.state.account?.username, CoachFixtures.username);
    });
  });

  group('falha de leitura', () {
    test('falhou, sem carregar; tentar de novo recupera', () async {
      final repo = _RepoWithError();
      bed = CoachBed(repo: repo);
      cubit = create(bed);
      await cubit.load();
      await pumpEventQueue();
      expect(cubit.state.failed, isTrue);
      expect(cubit.state.loading, isFalse);

      repo.fail = false;
      cubit.retry();
      expect(cubit.state.loading, isTrue);
      expect(cubit.state.failed, isFalse);
      await pumpEventQueue();
      expect(cubit.state.failed, isFalse);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.games, hasLength(5));
    });
  });

  group('falha só nas partidas', () {
    test('a conta que chega depois não apaga o erro nem volta ao '
        'esqueleto', () async {
      bed = CoachBed(repo: _RepoAccountLater());
      cubit = create(bed);
      await cubit.load();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.account, isNotNull);
      expect(cubit.state.failed, isTrue);
      expect(cubit.state.loading, isFalse);
    });
  });

  group('filtros', () {
    setUp(() async {
      await cubit.load();
      await pumpEventQueue();
    });

    test(
      'filtrar por ritmo reduz a lista filtrada, não a lista toda',
      () async {
        await cubit.applyFilter(
          const GameFilter(timeControl: TimeControl.rapid),
        );
        expect(cubit.state.filtered.map((p) => p.id), [
          'lichess_DeF67890',
          'lichess_MnO11223',
        ]);
        expect(cubit.state.games, hasLength(5));
      },
    );

    test('filtrar por resultado', () async {
      await cubit.applyFilter(const GameFilter(result: GameResult.draw));
      expect(cubit.state.filtered.map((p) => p.id), ['lichess_GhI13579']);
    });

    test('ritmo e resultado juntos sem partida: lista vazia', () async {
      await cubit.applyFilter(
        const GameFilter(
          timeControl: TimeControl.bullet,
          result: GameResult.win,
        ),
      );
      expect(cubit.state.filtered, isEmpty);
    });

    test('limparFiltros volta a todas', () async {
      await cubit.applyFilter(
        const GameFilter(timeControl: TimeControl.bullet),
      );
      await cubit.clearFilters();
      expect(cubit.state.filter.empty, isTrue);
      expect(cubit.state.filtered, hasLength(5));
    });

    test('o filtro fica salvo no aparelho', () async {
      const filter = GameFilter(timeControl: TimeControl.blitz);
      await cubit.applyFilter(filter);
      expect(await bed.preferences.filter(), filter);
    });

    test('limpar o filtro apaga o que estava salvo', () async {
      await cubit.applyFilter(const GameFilter(timeControl: TimeControl.blitz));
      await cubit.clearFilters();
      expect(await bed.preferences.filter(), GameFilter.everyone);
      expect(bed.memory.values, isEmpty);
    });

    test('reabrir o cubit traz o filtro salvo', () async {
      const filter = GameFilter(
        timeControl: TimeControl.blitz,
        result: GameResult.loss,
      );
      await cubit.applyFilter(filter);

      final other = create(bed);
      await other.load();
      await pumpEventQueue();
      expect(other.state.filter, filter);
      expect(other.state.filtered.map((p) => p.id), [CoachFixtures.idTiago]);
    });
  });

  test('fechar o cubit durante a carga não emite depois', () async {
    final c = create(bed);
    final payload = c.load();
    await c.close();
    await payload;
    await pumpEventQueue();
    expect(c.isClosed, isTrue);
  });
}
