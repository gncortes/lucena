import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:lucena/ui/core/keys/coach_your_game_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';
import 'package:lucena/ui/coach/widgets/game_row.dart';

import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/coach_fixtures.dart';
import 'coach_harness.dart';

/// A primeira leitura das partidas só chega quando o teste deixa.
class _RepoSlow extends FakeCoachRepository {
  _RepoSlow()
    : super(
        account: CoachFixtures.account,
        games: CoachFixtures.list(),
        stats: CoachFixtures.stats(),
      );

  final release = Completer<void>();

  @override
  Stream<List<CoachGame>> games() async* {
    await release.future;
    yield* super.games();
  }
}

/// A leitura das partidas falha (sem rede na primeira vez).
class _RepoOffline extends FakeCoachRepository {
  _RepoOffline()
    : super(
        account: CoachFixtures.account,
        games: CoachFixtures.list(),
        stats: CoachFixtures.stats(),
      );

  bool fail = true;

  @override
  Stream<List<CoachGame>> games() =>
      fail ? Stream.error(StateError('sem rede')) : super.games();

  @override
  Stream<CoachAccount?> account() =>
      fail ? Stream.error(StateError('sem rede')) : super.account();
}

/// A conta vem do cache e só a leitura das partidas falha.
class _RepoOnlyGamesFail extends FakeCoachRepository {
  _RepoOnlyGamesFail() : super(account: CoachFixtures.account);

  @override
  Stream<List<CoachGame>> games() => Stream.error(StateError('sem rede'));
}

FakeCoachRepository _withData() => FakeCoachRepository(
  account: CoachFixtures.account,
  games: CoachFixtures.list(),
  stats: CoachFixtures.stats(),
);

/// Rola até o item aparecer e toca nele.
Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await assentar(tester);
}

Finder _textAt(Key key, String text) =>
    find.descendant(of: find.byKey(key), matching: find.text(text));

GameProgress _progress(int doneCount, {int corrects = 0}) => GameProgress(
  results: [
    for (var n = 1; n <= doneCount; n++)
      ExerciseResult(
        n: n,
        solved: n <= corrects,
        points: n <= corrects ? 10 : 0,
      ),
  ],
);

void main() {
  group('carregando e falha de leitura', () {
    testWidgets('enquanto as partidas não chegam, mostra o esqueleto', (
      tester,
    ) async {
      device411x914(tester);
      final repo = _RepoSlow();
      final bed = CoachBed(repo: repo, grants: withPlan());
      await bed.open(tester, Routes.coach());

      expect(find.byType(LoadSkeletonScreen), findsOneWidget);
      expect(find.byKey(CoachKeys.screen), findsNothing);
      expect(find.text('Análise'), findsOneWidget);

      repo.release.complete();
      await assentar(tester);
      expect(find.byType(LoadSkeletonScreen), findsNothing);
      expect(find.byKey(CoachKeys.screen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem rede e sem dados, mostra o erro e tentar de novo '
        'recupera', (tester) async {
      device411x914(tester);
      final repo = _RepoOffline();
      final bed = CoachBed(repo: repo, grants: withPlan());
      await bed.open(tester, Routes.coach());

      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byKey(CoachKeys.screen), findsNothing);

      repo.fail = false;
      await tester.tap(find.text('Tentar novamente'));
      await assentar(tester);
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(find.byKey(CoachKeys.today), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('conta em cache, partidas sem rede', () {
    testWidgets('mostra o erro de rede, não o vazio "Jogue uma partida"', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _RepoOnlyGamesFail(), grants: withPlan());
      await bed.open(tester, Routes.coach());

      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.byKey(CoachKeys.todayEmpty), findsNothing);
      expect(find.textContaining('Jogue uma partida'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('sem conta ligada', () {
    late CoachBed bed;

    setUp(() {
      bed = CoachBed(repo: FakeCoachRepository(), grants: withPlan());
    });

    testWidgets(
      'mostra "Conecte sua conta", os dois sites e a barra das abas',
      (tester) async {
        device411x914(tester);
        await bed.open(tester, Routes.coach());

        expect(find.byKey(CoachKeys.linkAccount), findsOneWidget);
        expect(find.text('Conecte sua conta'), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
        expect(
          _textAt(CoachKeys.linkLichess, 'Conectar o Lichess'),
          findsOneWidget,
        );
        expect(
          _textAt(CoachKeys.linkChesscom, 'Conectar o chess.com'),
          findsOneWidget,
        );
        // Canvas DLigarConta: o Lichess é o primário (cheio); o chess.com, contornado.
        expect(
          tester.widget(find.byKey(CoachKeys.linkLichess)),
          isA<FilledButton>(),
        );
        expect(
          tester.widget(find.byKey(CoachKeys.linkChesscom)),
          isA<OutlinedButton>(),
        );
        expect(
          find.text(
            'Só lemos partidas públicas. Você pode desconectar quando quiser.',
          ),
          findsOneWidget,
        );
        // O bloco fica no meio da altura e a barra das abas aparece.
        final block = tester.getCenter(find.byIcon(Icons.link)).dy;
        expect(block, inInclusiveRange(250, 450));
        expect(find.byKey(CoachKeys.tabToday), findsOneWidget);
        expect(find.byKey(CoachKeys.today), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('escolher o Lichess abre o login de lá, sem campo de '
        'usuário, e liga o dono do token', (tester) async {
      device411x914(tester);
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.linkLichess));
      await assentar(tester);

      expect(bed.lichess.connects, 1);
      expect(bed.repo.lichessTokens, ['token-falso-do-lichess']);
      expect(bed.repo.links, isEmpty);
      expect(find.byKey(CoachKeys.username), findsNothing);
      expect(find.byKey(CoachKeys.linkAccount), findsNothing);
      expect(find.byKey(CoachKeys.tabToday), findsOneWidget);
      expect(
        find.text('Jogue uma partida no Lichess e ela aparece aqui.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('já entrou no Lichess pelo Perfil: liga sem abrir o login', (
      tester,
    ) async {
      device411x914(tester);
      bed.lichess.connected = true;
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.linkLichess));
      await assentar(tester);

      expect(bed.lichess.connects, 0);
      expect(bed.repo.lichessTokens, ['token-falso-do-lichess']);
      expect(find.byKey(CoachKeys.tabToday), findsOneWidget);
    });

    testWidgets('voltou do Lichess sem autorizar: fica na tela com o texto e '
        'o botão para tentar de novo', (tester) async {
      device411x914(tester);
      bed.lichess.hold = true;
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.linkLichess));
      await assentar(tester);
      bed.lichess.cancel();
      await assentar(tester);

      expect(find.byKey(CoachKeys.linkAccount), findsOneWidget);
      expect(
        find.text(
          'Para confirmar que a conta é sua, você entra no Lichess e '
          'autoriza o Lucena.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(CoachKeys.accountError), findsNothing);
      expect(bed.repo.lichessTokens, isEmpty);

      bed.lichess.hold = false;
      await tester.tap(find.byKey(CoachKeys.confirmAccount));
      await assentar(tester);
      expect(bed.repo.lichessTokens, ['token-falso-do-lichess']);
      expect(find.byKey(CoachKeys.tabToday), findsOneWidget);
    });

    testWidgets('escolher o chess.com mostra o nome do site no campo', (
      tester,
    ) async {
      device411x914(tester);
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.linkChesscom));
      await assentar(tester);
      expect(find.text('Seu usuário no chess.com'), findsOneWidget);

      await tester.enterText(find.byKey(CoachKeys.username), 'magnus');
      await assentar(tester);
      await tester.tap(find.byKey(CoachKeys.confirmAccount));
      await assentar(tester);
      expect(bed.repo.links, [(Platform.chesscom, 'magnus')]);
    });

    testWidgets('"Trocar de site" volta à escolha', (tester) async {
      device411x914(tester);
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.linkChesscom));
      await assentar(tester);
      await tester.tap(find.byKey(CoachKeys.switchSite));
      await assentar(tester);

      expect(find.byKey(CoachKeys.username), findsNothing);
      expect(find.byKey(CoachKeys.linkLichess), findsOneWidget);
      expect(find.byKey(CoachKeys.linkChesscom), findsOneWidget);
    });

    for (final (failure, text) in [
      (
        LinkAccountFailure.doesNotExist,
        'Não achamos esse usuário no chess.com.',
      ),
      (
        LinkAccountFailure.tooMany,
        'Você tentou conectar muitas vezes hoje. Tente de novo amanhã.',
      ),
      (
        LinkAccountFailure.noResponse,
        'Sem resposta do servidor. Verifique sua conexão com a internet e '
            'tente novamente.',
      ),
      (
        LinkAccountFailure.noLogin,
        'Entre na sua conta do Lucena para conectar a conta de xadrez.',
      ),
    ]) {
      testWidgets('falha $failure mostra o texto do erro e não liga', (
        tester,
      ) async {
        device411x914(tester);
        bed.repo.linkFailure = failure;
        await bed.open(tester, Routes.coach());

        await tester.tap(find.byKey(CoachKeys.linkChesscom));
        await assentar(tester);
        await tester.enterText(find.byKey(CoachKeys.username), 'ninguem');
        await assentar(tester);
        await tester.tap(find.byKey(CoachKeys.confirmAccount));
        await assentar(tester);

        expect(find.byKey(CoachKeys.accountError), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(CoachKeys.accountError)).data,
          text,
        );
        expect(find.byKey(CoachKeys.linkAccount), findsOneWidget);
        expect(find.byKey(CoachKeys.discoverPlan), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sem o plano de análise, o erro oferece conhecer o plano', (
      tester,
    ) async {
      device411x914(tester);
      bed.repo.linkFailure = LinkAccountFailure.noPlan;
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.linkChesscom));
      await assentar(tester);
      await tester.enterText(find.byKey(CoachKeys.username), 'gabriel');
      await assentar(tester);
      await tester.tap(find.byKey(CoachKeys.confirmAccount));
      await assentar(tester);

      expect(
        tester.widget<Text>(find.byKey(CoachKeys.accountError)).data,
        'Para conectar a conta, você precisa do plano de análise.',
      );
      expect(
        _textAt(CoachKeys.discoverPlan, 'Conhecer o plano de análise'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(CoachKeys.discoverPlan));
      await assentar(tester);
      expect(bed.path, '/pilares');
      expect(find.text('stub.pilares'), findsOneWidget);
    });

    testWidgets('o voltar fecha a tela e volta à home', (tester) async {
      device411x914(tester);
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.back));
      await assentar(tester);
      expect(find.text('stub.home'), findsOneWidget);
      expect(find.byKey(CoachKeys.screen), findsNothing);
    });
  });

  group('aba Hoje', () {
    testWidgets('com plano: a última partida, o botão e os exercícios que '
        'faltam', (tester) async {
      device411x914(tester);
      final bed = CoachBed(repo: _withData(), grants: withPlan());
      await bed.open(tester, Routes.coach());

      expect(find.byKey(CoachKeys.today), findsOneWidget);
      expect(find.text('Análise'), findsOneWidget);
      for (final tab in ['Hoje', 'Partidas', 'Seu jogo']) {
        expect(
          find.descendant(
            of: find.byKey(switch (tab) {
              'Hoje' => CoachKeys.tabToday,
              'Partidas' => CoachKeys.tabGames,
              _ => CoachKeys.tabYourGame,
            }),
            matching: find.text(tab),
          ),
          findsOneWidget,
        );
      }
      expect(find.byKey(CoachKeys.noPlan), findsNothing);
      expect(find.text('Última partida'), findsOneWidget);
      expect(find.byKey(CoachKeys.lastGame), findsOneWidget);
      expect(_textAt(CoachKeys.seeLastGame, 'Ver a partida'), findsOneWidget);
      expect(find.text('Para fazer agora'), findsOneWidget);
      // O cartão traz o resumo da partida (Tiago_Rook, pronta).
      expect(
        _textAt(
          CoachKeys.lastGame,
          'Você perdeu no lance 51, num final de torres que empatava.',
        ),
        findsOneWidget,
      );
      // O próximo exercício pendente: o tema e a posição, no CourseItemTile.
      final item = CoachKeys.toDoExercise(CoachFixtures.idTiago, 1);
      expect(find.byKey(item), findsOneWidget);
      expect(_textAt(item, 'Sacrificio h7'), findsOneWidget);
      expect(
        _textAt(item, 'Posição da sua partida contra Tiago_Rook, lance 8.'),
        findsOneWidget,
      );
      expect(_textAt(item, 'Xeque duplo'), findsNothing);
      // Um item por partida: o próximo; os outros ficam para depois.
      expect(
        find.byKey(CoachKeys.toDoExercise(CoachFixtures.idTiago, 3)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Ver a partida" abre a partida da lista', (tester) async {
      device411x914(tester);
      final bed = CoachBed(repo: _withData(), grants: withPlan());
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.seeLastGame));
      await assentar(tester);

      expect(bed.path, '/treinador/partida/${CoachFixtures.idTiago}');
      expect(find.byKey(CoachKeys.start), findsOneWidget);
    });

    testWidgets(
      'tocar no exercício para fazer abre a partida no exercício mostrado',
      (tester) async {
        device411x914(tester);
        final bed = CoachBed(repo: _withData(), grants: withPlan());
        await bed.open(tester, Routes.coach());

        await _tap(
          tester,
          find.byKey(CoachKeys.toDoExercise(CoachFixtures.idTiago, 1)),
        );
        expect(
          bed.path,
          startsWith('/treinador/partida/${CoachFixtures.idTiago}/exercicios'),
        );
      },
    );

    testWidgets('só o próximo exercício pendente de cada partida aparece', (
      tester,
    ) async {
      device411x914(tester);
      final partial = CoachFixtures.tiago().copyWith(
        progress: _progress(2, corrects: 1),
      );
      final bed = CoachBed(
        repo: FakeCoachRepository(
          account: CoachFixtures.account,
          games: [partial],
        ),
        grants: withPlan(),
      );
      await bed.open(tester, Routes.coach());

      for (final n in [1, 2, 4]) {
        expect(
          find.byKey(CoachKeys.toDoExercise(CoachFixtures.idTiago, n)),
          findsNothing,
        );
      }
      expect(
        find.byKey(CoachKeys.toDoExercise(CoachFixtures.idTiago, 3)),
        findsOneWidget,
      );
    });

    testWidgets('sem plano: mostra a caixa e conhecer o plano abre a venda', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _withData());
      await bed.open(tester, Routes.coach());

      expect(find.byKey(CoachKeys.noPlan), findsWidgets);
      expect(find.text('Análise de partidas'), findsOneWidget);
      expect(
        find.text(
          'Com o plano de análise, toda partida nova vira exercícios. '
          'Sem ele, são 3 análises grátis por semana.',
        ),
        findsOneWidget,
      );
      expect(
        _textAt(CoachKeys.discoverPlan, 'Conhecer o plano de análise'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(CoachKeys.discoverPlan));
      await assentar(tester);
      expect(bed.path, '/pilares');
    });

    testWidgets('sem partidas: mostra o aviso do site da conta', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(
        repo: FakeCoachRepository(account: CoachFixtures.account),
        grants: withPlan(),
      );
      await bed.open(tester, Routes.coach());

      expect(find.byKey(CoachKeys.todayEmpty), findsOneWidget);
      expect(
        find.text('Jogue uma partida no Lichess e ela aparece aqui.'),
        findsOneWidget,
      );
      expect(find.byKey(CoachKeys.lastGame), findsNothing);
      expect(find.text('Exercícios para fazer'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('com todos os exercícios feitos, diz que está em dia', (
      tester,
    ) async {
      device411x914(tester);
      final done = CoachFixtures.tiago().copyWith(
        progress: _progress(4, corrects: 3),
      );
      final bed = CoachBed(
        repo: FakeCoachRepository(
          account: CoachFixtures.account,
          games: [done],
        ),
        grants: withPlan(),
      );
      await bed.open(tester, Routes.coach());

      expect(
        find.text('Você fez os exercícios de todas as partidas analisadas.'),
        findsOneWidget,
      );
      // O cartão da última partida mostra o resumo, não o estado.
      expect(find.text('3 de 4 certos'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(CoachKeys.tabGames));
      await assentar(tester);
      expect(
        find.text('Precisão 78% · 3 de 4 exercícios certos'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  group('aba Partidas', () {
    late CoachBed bed;

    setUp(() {
      bed = CoachBed(repo: _withData(), grants: withPlan());
    });

    Future<void> openGames(WidgetTester tester) async {
      device411x914(tester);
      await bed.open(tester, Routes.coach());
      await tester.tap(find.byKey(CoachKeys.tabGames));
      await assentar(tester);
    }

    testWidgets('lista as cinco partidas com os filtros e o estado de '
        'cada uma', (tester) async {
      await openGames(tester);

      expect(find.byKey(CoachKeys.games), findsOneWidget);
      expect(find.byKey(CoachKeys.gamesBase), findsWidgets);
      expect(find.byType(GameRow), findsNWidgets(5));
      // Canvas DPartidasFiltro: sem rótulos, "Todas" no resultado e a contagem.
      expect(find.text('Ritmo'), findsNothing);
      expect(find.text('Resultado'), findsNothing);
      expect(
        find.text('5 partidas do Lichess, da mais recente'),
        findsOneWidget,
      );
      for (final (key, text) in [
        (CoachKeys.filterAll, 'Todas'),
        (CoachKeys.timeControlFilter('bullet'), 'Bullet'),
        (CoachKeys.timeControlFilter('blitz'), 'Blitz'),
        (CoachKeys.timeControlFilter('rapida'), 'Rápido'),
        (CoachKeys.resultFilter('vitoria'), 'Vitórias'),
        (CoachKeys.resultFilter('derrota'), 'Derrotas'),
        (CoachKeys.resultFilter('empate'), 'Empates'),
      ]) {
        expect(_textAt(key, text), findsOneWidget, reason: '$key');
      }
      expect(find.text('Pronta para analisar'), findsNWidgets(3));
      expect(find.text('Analisando…'), findsOneWidget);
      expect(find.text('0 de 4 exercícios feitos'), findsOneWidget);
      // Uma fileira só: "Todas" aparece uma vez.
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Todos'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('o filtro de ritmo reduz a lista', (tester) async {
      await openGames(tester);

      await _tap(tester, find.byKey(CoachKeys.timeControlFilter('rapida')));
      expect(find.byType(GameRow), findsNWidgets(2));
      expect(find.byKey(CoachKeys.game('lichess_DeF67890')), findsOneWidget);
      expect(find.byKey(CoachKeys.game('lichess_MnO11223')), findsOneWidget);
      expect(find.byKey(CoachKeys.game('lichess_JkL24680')), findsNothing);
    });

    testWidgets('filtros sem partida mostram o vazio e limpar volta a lista', (
      tester,
    ) async {
      await openGames(tester);

      await _tap(tester, find.byKey(CoachKeys.timeControlFilter('rapida')));
      await _tap(tester, find.byKey(CoachKeys.resultFilter('derrota')));

      expect(find.byKey(CoachKeys.gamesEmpty), findsOneWidget);
      expect(find.text('Nenhuma partida com esses filtros.'), findsOneWidget);
      expect(find.byKey(CoachKeys.gamesBase), findsNothing);
      expect(_textAt(CoachKeys.clearFilters, 'Limpar filtros'), findsOneWidget);

      await tester.tap(find.byKey(CoachKeys.clearFilters));
      await assentar(tester);
      expect(find.byType(GameRow), findsNWidgets(5));
      expect(find.byKey(CoachKeys.gamesEmpty), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar numa partida nova já começa a analisar (A10 G2)', (
      tester,
    ) async {
      await openGames(tester);

      await tester.tap(find.byKey(CoachKeys.game('lichess_DeF67890')));
      await assentar(tester);

      expect(bed.path, '/treinador/partida/lichess_DeF67890');
      expect(find.byKey(CoachKeys.loading), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sem partidas, mostra o aviso e não os filtros vazios', (
      tester,
    ) async {
      device411x914(tester);
      bed = CoachBed(
        repo: FakeCoachRepository(account: CoachFixtures.account),
        grants: withPlan(),
      );
      await bed.open(tester, Routes.coach());
      await tester.tap(find.byKey(CoachKeys.tabGames));
      await assentar(tester);

      expect(find.byKey(CoachKeys.gamesEmpty), findsOneWidget);
      expect(
        find.text('Jogue uma partida no Lichess e ela aparece aqui.'),
        findsOneWidget,
      );
      expect(find.byKey(CoachKeys.clearFilters), findsNothing);
    });

    testWidgets('o filtro escolhido fica salvo para a próxima vez', (
      tester,
    ) async {
      await openGames(tester);
      await _tap(tester, find.byKey(CoachKeys.resultFilter('empate')));
      expect(find.byType(GameRow), findsNWidgets(1));

      // Reabre a tela: o filtro volta como estava.
      bed.router.go('/');
      await assentar(tester);
      unawaited(bed.router.push(Routes.coach(tab: 'partidas')));
      await assentar(tester);
      expect(find.byType(GameRow), findsNWidgets(1));
    });
  });

  group('aba Seu jogo', () {
    testWidgets('a aba mostra o Seu jogo de verdade, sem o "em breve"', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _withData(), grants: withPlan());
      await bed.open(tester, Routes.coach());

      await tester.tap(find.byKey(CoachKeys.tabYourGame));
      await assentar(tester);
      expect(find.byKey(CoachKeys.yourGame), findsOneWidget);
      expect(find.byKey(YourGameKeys.tab), findsOneWidget);
      expect(find.text('Em breve: onde você mais erra.'), findsNothing);
      expect(find.byKey(CoachKeys.today), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('o parâmetro da rota abre direto na aba pedida', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _withData(), grants: withPlan());
      await bed.open(tester, Routes.coach(tab: 'seuJogo'));
      expect(find.byKey(CoachKeys.yourGame), findsOneWidget);

      await tester.tap(find.byKey(CoachKeys.tabToday));
      await assentar(tester);
      expect(find.byKey(CoachKeys.today), findsOneWidget);
    });
  });

  group('A10 G1: atalho Análise da Home', () {
    testWidgets('abre a última partida, com a lista embaixo', (tester) async {
      device411x914(tester);
      final bed = CoachBed(repo: _withData(), grants: withPlan());
      await bed.open(tester, Routes.coach(openLast: true));

      final last = CoachFixtures.list().first;
      expect(bed.path, Routes.coachGame(last.id));
      await tester.tap(find.byKey(CoachKeys.back));
      await assentar(tester);
      expect(find.byKey(CoachKeys.today), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a última já feita: fica na aba Hoje', (tester) async {
      device411x914(tester);
      final last = CoachFixtures.list().first;
      final repo = _withData();
      await repo.saveProgress(last.id, _progress(last.exercises.length));
      final bed = CoachBed(repo: repo, grants: withPlan());
      await bed.open(tester, Routes.coach(openLast: true));

      expect(find.byKey(CoachKeys.today), findsOneWidget);
      expect(bed.path, isNot(Routes.coachGame(last.id)));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
