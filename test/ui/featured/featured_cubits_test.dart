import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/featured_rules.dart';
import 'package:lucena/ui/featured/view_models/featured_catalog_cubit.dart';
import 'package:lucena/ui/featured/view_models/featured_endgame_cubit.dart';
import 'package:lucena/ui/featured/view_models/featured_tournament_cubit.dart';
import 'package:lucena/ui/featured/view_models/find_move_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_push_repository.dart';

void main() {
  late FakeFeaturedRepository repository;
  late FakeFeaturedProgressRepository progress;
  late FakeFeaturedAlertsRepository alerts;
  late FakePushRepository push;
  final now = FakeNow(DateTime(2026, 1, 1, 12));

  setUp(() {
    repository = FakeFeaturedRepository(sampleFeaturedCatalog());
    progress = FakeFeaturedProgressRepository();
    alerts = FakeFeaturedAlertsRepository();
    push = FakePushRepository();
  });

  group('FeaturedCatalogCubit', () {
    FeaturedCatalogCubit newCatalog({String? country}) {
      final cubit = FeaturedCatalogCubit(
        featured: repository,
        progress: progress,
        alerts: alerts,
        push: push,
        now: now,
        country: country,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('separa recentes (30 dias) e históricos, e acha o torneio', () async {
      final cubit = newCatalog();
      expect(cubit.state.ready, isFalse);
      await cubit.load();
      expect(cubit.state.ready, isTrue);
      expect([for (final i in cubit.state.recent) i.id], ['b']);
      expect([for (final i in cubit.state.historic) i.id], ['a', 'c']);
      expect([for (final t in cubit.state.ongoing) t.id], ['live']);
      expect(cubit.state.finalsOf('live'), 1);
    });

    test('sem finais, a lista está vazia', () async {
      repository.value = FeaturedCatalog.empty;
      final cubit = newCatalog();
      await cubit.load();
      expect(cubit.state.isEmpty, isTrue);
    });

    test('o país do perfil só muda a ordem, nenhum final some', () async {
      final cubit = newCatalog(country: 'US');
      await cubit.load();
      expect(cubit.state.recent.length + cubit.state.historic.length, 3);
    });

    test('os jogados vão para o fim do grupo', () async {
      progress.playedIds.add('a');
      final cubit = newCatalog();
      await cubit.load();
      expect(cubit.state.historic.last.id, 'a');
      expect(cubit.state.historic.last.played, isTrue);
    });

    test('catálogo ilegível termina em erro e "tentar de novo" relê', () async {
      repository.failure = StateError('lixo');
      final cubit = newCatalog();
      await cubit.load();
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.ready, isFalse);
      repository.failure = null;
      await cubit.retryLoad();
      expect(cubit.state.failure, isNull);
      expect(cubit.state.ready, isTrue);
    });

    group('sino', () {
      test('abre desligado e liga com a permissão, guardando', () async {
        push.granted = true;
        final cubit = newCatalog();
        await cubit.load();
        expect(cubit.state.bellOn, isFalse);
        await cubit.toggleBell();
        expect(push.permissionRequests, 1);
        expect(cubit.state.bellOn, isTrue);
        expect(cubit.state.notice, FeaturedBellNotice.turnedOn);
        expect(alerts.all, isTrue);
        final again = newCatalog();
        await again.load();
        expect(again.state.bellOn, isTrue);
      });

      test('desligar guarda e avisa que desligou', () async {
        alerts.all = true;
        push.allowed = true;
        final cubit = newCatalog();
        await cubit.load();
        expect(cubit.state.bellOn, isTrue);
        await cubit.toggleBell();
        expect(cubit.state.bellOn, isFalse);
        expect(cubit.state.notice, FeaturedBellNotice.turnedOff);
        expect(alerts.all, isFalse);
        expect(push.permissionRequests, 0);
      });

      test(
        'permissão negada: continua desligado e oferece os ajustes',
        () async {
          push.granted = false;
          final cubit = newCatalog();
          await cubit.load();
          await cubit.toggleBell();
          expect(cubit.state.bellOn, isFalse);
          expect(cubit.state.notice, FeaturedBellNotice.permissionDenied);
          expect(alerts.all, isFalse);
          await cubit.openSystemSettings();
          expect(push.settingsOpened, 1);
        },
      );

      test('cada aviso conta de novo, mesmo repetido', () async {
        push.allowed = true;
        final cubit = newCatalog();
        await cubit.load();
        await cubit.toggleBell();
        await cubit.toggleBell();
        await cubit.toggleBell();
        expect(cubit.state.noticeCount, 3);
      });
    });
  });

  group('FeaturedTournamentCubit', () {
    FeaturedTournamentCubit newTournament(String id) {
      final cubit = FeaturedTournamentCubit(
        id: id,
        featured: repository,
        progress: progress,
        now: now,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('mostra o torneio, os finais dele e se está em andamento', () async {
      final cubit = newTournament('live');
      await cubit.load();
      expect(cubit.state.tournament!.id, 'live');
      expect([for (final i in cubit.state.items) i.id], ['b']);
      expect(cubit.state.ongoing, isTrue);
    });

    test('torneio que não existe termina pronto e sem torneio', () async {
      final cubit = newTournament('nada');
      await cubit.load();
      expect(cubit.state.ready, isTrue);
      expect(cubit.state.tournament, isNull);
    });

    test('torneio passado não está em andamento', () async {
      final cubit = newTournament('old');
      await cubit.load();
      expect(cubit.state.ongoing, isFalse);
    });

    test('falha de leitura vira erro e "tentar de novo" relê', () async {
      repository.failure = StateError('lixo');
      final cubit = newTournament('live');
      await cubit.load();
      expect(cubit.state.failure, isNotNull);
      repository.failure = null;
      await cubit.retryLoad();
      expect(cubit.state.ready, isTrue);
    });
  });

  group('FeaturedEndgameCubit', () {
    FeaturedEndgameCubit newEndgame(String id) {
      final cubit = FeaturedEndgameCubit(
        id: id,
        featured: repository,
        progress: progress,
        characters: FakeCharacterRepository(),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('carrega o final, o torneio, os irmãos e a sugestão', () async {
      final cubit = newEndgame('a');
      await cubit.load();
      expect(cubit.state.endgame!.id, 'a');
      expect(cubit.state.tournament!.id, 'old');
      expect(cubit.state.siblings, isEmpty);
      expect(cubit.state.choice!.level, 1600);
      expect(cubit.state.played, isFalse);
    });

    test('final que não existe termina pronto e vazio', () async {
      final cubit = newEndgame('nada');
      await cubit.load();
      expect(cubit.state.ready, isTrue);
      expect(cubit.state.endgame, isNull);
    });

    test('antes da primeira tentativa a escolha é fixa', () async {
      final cubit = newEndgame('a');
      await cubit.load();
      expect(cubit.state.canChange, isFalse);
      await cubit.choose(
        const FeaturedChoice(opponent: OpponentKind.stockfish),
      );
      expect(cubit.state.choice!.opponent, OpponentKind.maia);
      expect(progress.choices, isEmpty);
    });

    test(
      'depois da primeira tentativa o jogador troca e a troca fica',
      () async {
        final cubit = newEndgame('a');
        await cubit.load();
        await cubit.markPlayed();
        expect(progress.playedIds, {'a'});
        expect(cubit.state.canChange, isTrue);
        const other = FeaturedChoice(opponent: OpponentKind.stockfish);
        await cubit.choose(other);
        expect(cubit.state.choice, other);
        final again = newEndgame('a');
        await again.load();
        expect(again.state.choice, other);
      },
    );

    test('final sugerido (aberto) já deixa trocar', () async {
      final cubit = newEndgame('c');
      await cubit.load();
      expect(cubit.state.canChange, isTrue);
      const other = FeaturedChoice(opponent: OpponentKind.maia, level: 2000);
      await cubit.choose(other);
      expect(progress.choices['c'], other);
    });

    test(
      'a escolha guardada de um final fixo e não jogado é ignorada',
      () async {
        progress.choices['a'] = const FeaturedChoice(
          opponent: OpponentKind.stockfish,
        );
        final cubit = newEndgame('a');
        await cubit.load();
        expect(cubit.state.choice!.opponent, OpponentKind.maia);
      },
    );

    test('os irmãos são os outros finais do torneio', () async {
      repository.value = FeaturedCatalog(
        tournaments: repository.value.tournaments,
        finals: [
          ...repository.value.finals,
          FeaturedEndgame(
            id: 'd',
            kind: FeaturedKind.play,
            origin: FeaturedOrigin.tournament,
            fen: '8/8/5k1p/8/6PP/5K2/8/8 w - - 2 55',
            goal: PositionGoal.win,
            white: const FeaturedPlayer(name: 'X'),
            black: const FeaturedPlayer(name: 'Y'),
            tournamentId: 'live',
            suggested: const FeaturedChoice(opponent: OpponentKind.stockfish),
          ),
        ],
      );
      final cubit = newEndgame('b');
      await cubit.load();
      expect([for (final e in cubit.state.siblings) e.id], ['d']);
    });
  });

  group('FindMoveCubit', () {
    FindMoveCubit newFind() {
      final cubit = FindMoveCubit(
        endgame: sampleFeaturedCatalog().endgame('b')!,
        progress: progress,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('a resposta e a dica vêm da posição', () {
      final cubit = newFind();
      expect(cubit.answer, 'c8b8');
      expect(cubit.answerSan, 'Kb8');
      expect(cubit.hintRole, Role.king);
    });

    test('só o rei e sem dica própria: não oferece a dica genérica', () {
      final base = sampleFeaturedCatalog().endgame('b')!;
      final bare = FeaturedEndgame(
        id: base.id,
        kind: base.kind,
        origin: base.origin,
        fen: base.fen,
        goal: base.goal,
        white: base.white,
        black: base.black,
        suggested: base.suggested,
        solutions: base.solutions,
      );
      final cubit = FindMoveCubit(endgame: bare, progress: progress);
      addTearDown(cubit.close);
      expect(cubit.hasHint, isFalse);
      expect(newFind().hasHint, isTrue);
      expect(newFind().answerMove?.to, Square.b8);
    });

    test(
      'lance errado deixa tentar de novo, certo resolve e marca jogado',
      () async {
        final cubit = newFind();
        await cubit.play(Move.parse('c8c7')!);
        expect(cubit.state.phase, FindMovePhase.wrong);
        expect(cubit.state.attempts, 1);
        expect(progress.playedIds, isEmpty);
        await cubit.retry();
        expect(cubit.state.phase, FindMovePhase.asking);
        await cubit.play(Move.parse('c8b8')!);
        expect(cubit.state.phase, FindMovePhase.solved);
        expect(cubit.state.finished, isTrue);
        expect(progress.playedIds, {'b'});
        await cubit.play(Move.parse('c8c7')!);
        expect(cubit.state.phase, FindMovePhase.solved);
      },
    );

    test('dica e ver a resposta', () async {
      final cubit = newFind();
      await cubit.showHint();
      expect(cubit.state.hint, isTrue);
      await cubit.reveal();
      expect(cubit.state.phase, FindMovePhase.revealed);
      expect(progress.playedIds, {'b'});
      // Depois de ver a resposta, dá para tentar de novo (tabuleiro novo).
      final attempts = cubit.state.attempts;
      await cubit.retry();
      expect(cubit.state.phase, FindMovePhase.asking);
      expect(cubit.state.attempts, attempts + 1);
      expect(cubit.state.hint, isFalse);
    });
  });

  test('FeaturedItem expõe o id do final', () {
    final item = FeaturedRules.items(
      sampleFeaturedCatalog(),
      {},
      now: now(),
    ).first;
    expect(item.id, item.endgame.id);
  });
}
