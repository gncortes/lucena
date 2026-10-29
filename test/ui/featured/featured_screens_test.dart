import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/featured/widgets/featured_card.dart';
import 'package:lucena/domain/models/crowd_stat.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/ui/core/share/share_button.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/featured/featured_progress_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/use_cases/featured_rules.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/featured/view_models/featured_catalog_cubit.dart';
import 'package:lucena/ui/featured/view_models/featured_endgame_cubit.dart';
import 'package:lucena/ui/featured/view_models/featured_tournament_cubit.dart';
import 'package:lucena/ui/featured/widgets/featured_endgame_screen.dart';
import 'package:lucena/ui/featured/widgets/featured_game_bar.dart';
import 'package:lucena/ui/featured/widgets/featured_list_screen.dart';
import 'package:lucena/ui/featured/widgets/featured_tournament_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_crowd_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeFeaturedRepository repository;
  late FakeFeaturedProgressRepository progress;
  late FakeFeaturedAlertsRepository alerts;
  final now = FakeNow(DateTime(2026, 1, 1, 12));

  setUp(() {
    repository = FakeFeaturedRepository(sampleFeaturedCatalog());
    progress = FakeFeaturedProgressRepository();
    alerts = FakeFeaturedAlertsRepository();
  });

  /// A tela [child] numa rota, com tudo o que ela lê, e uma rota "para onde
  /// foi" que mostra o endereço.
  /// A faixa de filtros rola: leva o chip para a tela antes de tocar.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  Future<GoRouter> pump(
    WidgetTester tester,
    Widget child, {
    required String location,
    required String path,
    FakeCrowdRepository? crowd,
  }) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => SettingsCubit(
                  FakeSettingsRepository(const AppSettings()),
                  languages: AppLanguage.selectable,
                )..load(),
              ),
              BlocProvider(
                lazy: false,
                create: (_) => FeaturedCatalogCubit(
                  featured: repository,
                  progress: progress,
                  now: now,
                )..load(),
              ),
              BlocProvider(
                lazy: false,
                create: (_) => FeaturedTournamentCubit(
                  id: state.pathParameters['id'] ?? 'live',
                  featured: repository,
                  progress: progress,
                  alerts: alerts,
                  now: now,
                )..load(),
              ),
              BlocProvider(
                lazy: false,
                create: (_) => FeaturedEndgameCubit(
                  id: state.pathParameters['id'] ?? 'a',
                  featured: repository,
                  progress: progress,
                  characters: FakeCharacterRepository(),
                )..load(),
              ),
              RepositoryProvider<FeaturedProgressRepository>.value(
                value: progress,
              ),
              RepositoryProvider<EndgameLessonRepository>.value(
                value: FakeEndgameLessonRepository(),
              ),
            ],
            child: child,
          ),
        ),
        GoRoute(
          path: '/featured/:id',
          builder: (context, state) =>
              Text('final ${state.pathParameters['id']}'),
        ),
        GoRoute(path: '/featured', builder: (_, _) => const Text('lista')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        router: router,
        locale: const Locale('pt'),
        crowdRepository: crowd,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('lista', () {
    testWidgets('mostra o torneio em andamento e os cartões', (tester) async {
      await pump(
        tester,
        const FeaturedListScreen(),
        location: '/list',
        path: '/list',
      );
      expect(find.byKey(FeaturedKeys.listScreen), findsOneWidget);
      expect(find.byKey(FeaturedKeys.ongoingTitle), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentCard('live')), findsOneWidget);
      expect(find.byKey(FeaturedKeys.card('a')), findsOneWidget);
      expect(find.byKey(FeaturedKeys.card('b')), findsOneWidget);
    });

    testWidgets('o cartão tem jogadores, evento e ano e a meta, sem selos', (
      tester,
    ) async {
      await pump(
        tester,
        const FeaturedListScreen(),
        location: '/list',
        path: '/list',
      );
      final card = find.byKey(FeaturedKeys.card('a'));
      expect(
        find.descendant(of: card, matching: find.text('A × A')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Torneio Antigo 1959')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Defender')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('NOVO')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Final A')),
        findsNothing,
      );
    });

    testWidgets('filtrar por origem esconde os outros e limpa', (tester) async {
      await pump(
        tester,
        const FeaturedListScreen(),
        location: '/list',
        path: '/list',
      );
      await tapVisible(tester, find.byKey(FeaturedKeys.originFilter('video')));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.card('c')), findsOneWidget);
      expect(find.byKey(FeaturedKeys.card('a')), findsNothing);
      await tapVisible(
        tester,
        find.byKey(FeaturedKeys.originFilter('historical')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.card('a')), findsOneWidget);
      expect(find.byKey(FeaturedKeys.card('c')), findsNothing);
    });

    testWidgets('filtros que escondem tudo oferecem limpar', (tester) async {
      await pump(
        tester,
        const FeaturedListScreen(),
        location: '/list',
        path: '/list',
      );
      await tester.tap(find.byKey(FeaturedKeys.countryFilter));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeaturedKeys.countryOption('US')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(FeaturedKeys.originFilter('video')));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.listFilteredOut), findsOneWidget);
      await tester.tap(find.byKey(FeaturedKeys.clearFilters));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.card('a')), findsOneWidget);
    });

    testWidgets('"Todos os países" tira o filtro de país', (tester) async {
      await pump(
        tester,
        const FeaturedListScreen(),
        location: '/list',
        path: '/list',
      );
      await tester.tap(find.byKey(FeaturedKeys.countryFilter));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeaturedKeys.countryOption('US')));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.card('b')), findsNothing);
      await tester.tap(find.byKey(FeaturedKeys.countryFilter));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeaturedKeys.countryAll));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.card('b')), findsOneWidget);
    });

    testWidgets('sem finais, mostra o vazio', (tester) async {
      repository.value = FeaturedCatalog.empty;
      await pump(
        tester,
        const FeaturedListScreen(),
        location: '/list',
        path: '/list',
      );
      expect(find.byKey(FeaturedKeys.listEmpty), findsOneWidget);
    });

    testWidgets('tocar no cartão abre o final', (tester) async {
      await pump(
        tester,
        const FeaturedListScreen(),
        location: '/list',
        path: '/list',
      );
      await tester.tap(find.byKey(FeaturedKeys.card('a')));
      await tester.pumpAndSettle();
      expect(find.text('final a'), findsOneWidget);
    });
  });

  group('torneio', () {
    testWidgets('resumo, links, final e o interruptor só com canal', (
      tester,
    ) async {
      await pump(
        tester,
        const FeaturedTournamentScreen(),
        location: '/t/live',
        path: '/t/:id',
      );
      expect(find.byKey(FeaturedKeys.tournamentSummary), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentOngoing), findsOneWidget);
      expect(
        find.byKey(FeaturedKeys.tournamentLink('results')),
        findsOneWidget,
      );
      expect(
        find.byKey(FeaturedKeys.tournamentLink('broadcast')),
        findsOneWidget,
      );
      expect(find.byKey(FeaturedKeys.card('b')), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentAlert), findsOneWidget);
      await tester.tap(find.byKey(FeaturedKeys.tournamentAlert));
      await tester.pumpAndSettle();
      expect(alerts.tournaments, {'live'});
    });

    testWidgets('sem canal de aviso, o interruptor some', (tester) async {
      alerts = FakeFeaturedAlertsRepository(available: false);
      await pump(
        tester,
        const FeaturedTournamentScreen(),
        location: '/t/live',
        path: '/t/:id',
      );
      expect(find.byKey(FeaturedKeys.tournamentAlert), findsNothing);
    });

    testWidgets('torneio que não existe mostra o aviso', (tester) async {
      await pump(
        tester,
        const FeaturedTournamentScreen(),
        location: '/t/nada',
        path: '/t/:id',
      );
      expect(find.byKey(FeaturedKeys.tournamentMissing), findsOneWidget);
    });
  });

  group('final', () {
    testWidgets('adversário fixo antes da primeira tentativa', (tester) async {
      await pump(
        tester,
        const FeaturedEndgameScreen(),
        location: '/e/a',
        path: '/e/:id',
      );
      expect(find.byKey(FeaturedKeys.endgameScreen), findsOneWidget);
      expect(find.byKey(FeaturedKeys.endgamePlayers), findsOneWidget);
      expect(find.byKey(FeaturedKeys.lockedIcon), findsWidgets);
      expect(find.byKey(FeaturedKeys.configNote), findsOneWidget);
      expect(find.byKey(FeaturedKeys.playButton), findsOneWidget);
    });

    testWidgets('final sugerido deixa trocar o adversário', (tester) async {
      await pump(
        tester,
        const FeaturedEndgameScreen(),
        location: '/e/c',
        path: '/e/:id',
      );
      expect(find.byKey(FeaturedKeys.lockedIcon), findsNothing);
      await tester.tap(find.byKey(FeaturedKeys.opponentRow));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.choiceSheet), findsOneWidget);
      await tester.tap(find.byKey(FeaturedKeys.choiceOpponent('stockfish')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeaturedKeys.choiceDone));
      await tester.pumpAndSettle();
      expect(progress.choices['c']!.opponent.code, 'stockfish');
    });

    testWidgets('o adversário aparece com o nome do personagem e o nível', (
      tester,
    ) async {
      await pump(
        tester,
        const FeaturedEndgameScreen(),
        location: '/e/a',
        path: '/e/:id',
      );
      expect(
        find.descendant(
          of: find.byKey(FeaturedKeys.opponentRow),
          matching: find.text('Valdini · 1600'),
        ),
        findsOneWidget,
      );
      expect(find.text('Maia · 1600'), findsNothing);
    });

    testWidgets('o livrinho abre com torneio e jogadores', (tester) async {
      await pump(
        tester,
        const FeaturedEndgameScreen(),
        location: '/e/a',
        path: '/e/:id',
      );
      await tester.tap(find.byKey(FeaturedKeys.bookButton));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.bookSheet), findsOneWidget);
      expect(find.byKey(FeaturedKeys.bookTournament), findsOneWidget);
      expect(find.byKey(FeaturedKeys.bookWhite), findsOneWidget);
      expect(find.byKey(FeaturedKeys.bookBlack), findsOneWidget);
      expect(find.byKey(FeaturedKeys.bookHappened), findsOneWidget);
    });

    testWidgets('final que não existe mostra o aviso', (tester) async {
      await pump(
        tester,
        const FeaturedEndgameScreen(),
        location: '/e/nada',
        path: '/e/:id',
      );
      expect(find.byKey(FeaturedKeys.endgameMissing), findsOneWidget);
    });
  });

  group('Ache o lance', () {
    Future<void> openFind(WidgetTester tester) => pump(
      tester,
      const FeaturedEndgameScreen(),
      location: '/e/b',
      path: '/e/:id',
    );

    testWidgets('mostra o tabuleiro e a pergunta', (tester) async {
      await openFind(tester);
      expect(find.byKey(FeaturedKeys.findScreen), findsOneWidget);
      expect(find.byKey(FeaturedKeys.findBoard), findsOneWidget);
      expect(find.byKey(FeaturedKeys.findPrompt), findsOneWidget);
      expect(find.byKey(FeaturedKeys.bookButton), findsOneWidget);
    });

    testWidgets('a dica não entrega a casa e ver a resposta mostra o lance', (
      tester,
    ) async {
      await openFind(tester);
      await tester.tap(find.byKey(FeaturedKeys.findHint));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.findHintText), findsOneWidget);
      await tester.tap(find.byKey(FeaturedKeys.findAnswer));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.findResult), findsOneWidget);
      expect(find.textContaining('Rb8'), findsOneWidget);
      expect(progress.playedIds, {'b'});
      await tester.tap(find.byKey(FeaturedKeys.findContinue));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.nextSheet), findsOneWidget);
    });
  });

  group('home', () {
    testWidgets('o cartão compacto: o tabuleiro de 46 e os jogadores', (
      tester,
    ) async {
      final item = FeaturedRules.items(
        sampleFeaturedCatalog(),
        {},
        now: now(),
      ).first;
      var opened = 0;
      await pump(
        tester,
        Scaffold(
          body: FeaturedCard(
            key: FeaturedKeys.homeCard,
            item: item,
            compact: true,
            onTap: () => opened++,
          ),
        ),
        location: '/home',
        path: '/home',
      );
      final board = tester.getSize(find.byType(PositionBoard));
      expect(board.width, FeaturedCard.compactThumbnail);
      await tester.tap(find.byKey(FeaturedKeys.homeCard));
      expect(opened, 1);
    });
  });

  group('fim da partida', () {
    testWidgets('Jogar de novo e Continuar abrem os caminhos', (tester) async {
      var again = 0;
      await pump(
        tester,
        Scaffold(body: FeaturedEndBar(onAgain: () => again++)),
        location: '/e/a',
        path: '/e/:id',
      );
      await tester.tap(find.byKey(FeaturedKeys.playAgain));
      expect(again, 1);
      await tester.tap(find.byKey(FeaturedKeys.continueButton));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.nextSheet), findsOneWidget);
      expect(find.byKey(FeaturedKeys.nextLesson), findsOneWidget);
    });

    testWidgets('o número ainda não saiu: sem o cartão', (tester) async {
      await pump(
        tester,
        Scaffold(body: FeaturedEndBar(onAgain: () {})),
        location: '/e/a',
        path: '/e/:id',
      );
      expect(find.byKey(FeaturedKeys.crowdCard), findsNothing);
    });

    testWidgets('o x% acertaram e quantos jogaram este final', (tester) async {
      await pump(
        tester,
        Scaffold(body: FeaturedEndBar(onAgain: () {})),
        location: '/e/a',
        path: '/e/:id',
        crowd: FakeCrowdRepository(
          featured: {'a': const CrowdStat(percent: 41, total: 1284)},
        ),
      );
      expect(find.byKey(FeaturedKeys.crowdCard), findsOneWidget);
      expect(find.text('41% acertaram'), findsOneWidget);
      expect(find.text('1.284 pessoas jogaram este final.'), findsOneWidget);
    });

    testWidgets('menos de 30 pessoas: sem número', (tester) async {
      await pump(
        tester,
        Scaffold(body: FeaturedEndBar(onAgain: () {})),
        location: '/e/a',
        path: '/e/:id',
        crowd: FakeCrowdRepository(
          featured: {'a': const CrowdStat(percent: 41, total: 12)},
        ),
      );
      expect(find.byKey(FeaturedKeys.crowdFew), findsOneWidget);
      expect(find.text('41% acertaram'), findsNothing);
    });

    testWidgets('a barra de cima tem o livro e, no fim, compartilhar', (
      tester,
    ) async {
      final boundary = GlobalKey();
      await pump(
        tester,
        Scaffold(
          appBar: AppBar(
            actions: [FeaturedGameActions(boundary: boundary, ended: true)],
          ),
        ),
        location: '/e/a',
        path: '/e/:id',
      );
      expect(find.byKey(FeaturedKeys.bookButton), findsOneWidget);
      expect(find.byKey(FeaturedKeys.shareButton), findsOneWidget);
      final share = tester.widget<ShareIconButton>(
        find.byKey(FeaturedKeys.shareButton),
      );
      expect(share.text, contains('https://${AppLinks.host}/p/'));
    });
  });
}
