import 'package:dartchess/dartchess.dart';

import '../../../testing/board_gestures.dart';

import 'dart:async';

import 'package:lucena/domain/models/find_move_checkpoint.dart';
import 'package:flutter/material.dart';
import 'package:lucena/ui/featured/view_models/featured_alert_cubit.dart';

import '../../../testing/fakes/fake_alerts_repository.dart';

import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/routing/routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/featured/widgets/featured_card.dart';
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
import 'package:lucena/ui/core/motion/tabuleiro_hero.dart';
import 'package:lucena/ui/featured/view_models/featured_catalog_cubit.dart';
import 'package:lucena/ui/featured/view_models/featured_endgame_cubit.dart';
import 'package:lucena/ui/featured/view_models/featured_tournament_cubit.dart';
import 'package:lucena/ui/featured/widgets/featured_endgame_screen.dart';
import 'package:lucena/ui/featured/widgets/featured_game_bar.dart';
import 'package:lucena/ui/featured/widgets/featured_list_screen.dart';
import 'package:lucena/ui/featured/widgets/featured_tournament_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

class _ControlledProgress extends FakeFeaturedProgressRepository {
  Completer<void>? gate;
  bool failWrite = false;
  bool failRead = false;

  @override
  Future<FindMoveCheckpoint?> findMove(FeaturedEndgame endgame) async {
    if (failRead) throw StateError('checkpoint read');
    return super.findMove(endgame);
  }

  @override
  Future<void> saveFindMove(
    String id,
    FindMoveCheckpoint checkpoint, {
    Future<void> Function()? onPlayed,
  }) async {
    await gate?.future;
    if (failWrite) throw StateError('checkpoint write');
    await super.saveFindMove(id, checkpoint, onPlayed: onPlayed);
  }
}

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

  /// A tela [child] numa rota, com tudo o que ela lê, e uma rota "para onde
  /// foi" que mostra o endereço.
  Future<GoRouter> pump(
    WidgetTester tester,
    Widget child, {
    required String location,
    required String path,
    bool load = true,
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
                create: (_) {
                  final cubit = FeaturedCatalogCubit(
                    featured: repository,
                    progress: progress,
                    alerts: alerts,
                    push: push,
                    now: now,
                  );
                  if (load) cubit.load();
                  return cubit;
                },
              ),
              BlocProvider(
                lazy: false,
                create: (_) {
                  final cubit = FeaturedTournamentCubit(
                    id: state.pathParameters['id'] ?? 'live',
                    featured: repository,
                    progress: progress,
                    now: now,
                  );
                  if (load) cubit.load();
                  return cubit;
                },
              ),
              BlocProvider(
                lazy: false,
                create: (_) {
                  final cubit = FeaturedEndgameCubit(
                    id: state.pathParameters['id'] ?? 'a',
                    featured: repository,
                    progress: progress,
                    characters: FakeCharacterRepository(),
                  );
                  if (load) cubit.load();
                  return cubit;
                },
              ),
              BlocProvider(
                create: (_) => FeaturedAlertCubit(
                  id: state.pathParameters['id'] ?? 'a',
                  prompts: FakeFeaturedAlertsRepository(),
                  alerts: FakeAlertsRepository(),
                  push: FakePushRepository(),
                ),
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
          path: '/featured/tournament/:id',
          builder: (context, state) =>
              Text('torneio ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/featured/:id',
          builder: (context, state) =>
              Text('final ${state.pathParameters['id']}'),
        ),
        GoRoute(path: '/featured', builder: (_, _) => const Text('lista')),
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(key: HomeKeys.screen),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        router: router,
        locale: const Locale('pt'),
        child: const SizedBox(),
      ),
    );
    if (!load) {
      await tester.pump();
      return router;
    }
    await tester.pumpAndSettle();
    return router;
  }

  group('lista', () {
    Future<void> openList(WidgetTester tester, {bool load = true}) => pump(
      tester,
      const FeaturedListScreen(),
      location: '/list',
      path: '/list',
      load: load,
    );

    testWidgets('mostra o carrossel de torneios e as seções', (tester) async {
      await openList(tester);
      expect(find.byKey(FeaturedKeys.listScreen), findsOneWidget);
      expect(find.byKey(FeaturedKeys.ongoingTitle), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentCarousel), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentCard('live')), findsOneWidget);
      expect(find.byKey(FeaturedKeys.recentTitle), findsOneWidget);
      expect(find.byKey(FeaturedKeys.historicTitle), findsOneWidget);
      expect(find.text('Finais históricos'), findsOneWidget);
      expect(find.byKey(FeaturedKeys.card('b')), findsOneWidget);
      expect(find.byKey(FeaturedKeys.card('a')), findsOneWidget);
    });

    // H-ANI-02: o tabuleiro do cartão voa até a tela do final, com o id = FEN
    // que ela abre. Uma marca por posição na lista.
    testWidgets('o tabuleiro de cada cartão é o TabuleiroHero da posição', (
      tester,
    ) async {
      await openList(tester);
      for (final final_ in sampleFeaturedCatalog().finals.where(
        (f) => f.id == 'a' || f.id == 'b',
      )) {
        final hero = find.descendant(
          of: find.byKey(FeaturedKeys.card(final_.id)),
          matching: find.byType(TabuleiroHero),
        );
        expect(hero, findsOneWidget);
        expect(tester.widget<TabuleiroHero>(hero).id, final_.fen);
      }
      final ids = tester
          .widgetList<TabuleiroHero>(find.byType(TabuleiroHero))
          .map((h) => h.id)
          .toList();
      expect(ids.toSet().length, ids.length);
    });

    testWidgets('não há filtros de país nem de origem', (tester) async {
      await openList(tester);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('o cartão do torneio conta os finais para praticar', (
      tester,
    ) async {
      await openList(tester);
      expect(
        find.descendant(
          of: find.byKey(FeaturedKeys.tournamentCard('live')),
          matching: find.text('Um final para praticar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem torneio ao vivo, a seção "Acontecendo agora" some', (
      tester,
    ) async {
      repository.value = FeaturedCatalog(
        tournaments: [
          for (final t in sampleFeaturedCatalog().tournaments)
            if (t.id == 'old') t,
        ],
        finals: [
          for (final f in sampleFeaturedCatalog().finals)
            if (f.tournamentId != 'live') f,
        ],
      );
      await openList(tester);
      expect(find.byKey(FeaturedKeys.ongoingTitle), findsNothing);
      expect(find.byKey(FeaturedKeys.tournamentCarousel), findsNothing);
    });

    testWidgets('selos: NOVO e Torneio no recente, Histórica no histórico', (
      tester,
    ) async {
      progress.playedIds.add('a');
      await openList(tester);
      final recent = find.byKey(FeaturedKeys.card('b'));
      expect(
        find.descendant(of: recent, matching: find.byKey(FeaturedKeys.cardNew)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: recent,
          matching: find.byKey(FeaturedKeys.cardTournament),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: recent,
          matching: find.byKey(FeaturedKeys.cardHistoric),
        ),
        findsNothing,
      );
      final old = find.byKey(FeaturedKeys.card('a'));
      expect(
        find.descendant(
          of: old,
          matching: find.byKey(FeaturedKeys.cardHistoric),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: old, matching: find.byKey(FeaturedKeys.cardPlayed)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: old, matching: find.byKey(FeaturedKeys.cardNew)),
        findsNothing,
      );
    });

    testWidgets('o cartão mostra título, jogadores com o evento e o tema', (
      tester,
    ) async {
      await openList(tester);
      final card = find.byKey(FeaturedKeys.card('a'));
      expect(
        find.descendant(of: card, matching: find.text('Final A')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('A × A · Torneio Antigo 1959'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem finais, mostra o vazio', (tester) async {
      repository.value = FeaturedCatalog.empty;
      await openList(tester);
      expect(find.byKey(FeaturedKeys.listEmpty), findsOneWidget);
    });

    testWidgets('carregando mostra o esqueleto, sem tela em branco', (
      tester,
    ) async {
      await openList(tester, load: false);
      expect(find.byKey(FeaturedKeys.listLoading), findsOneWidget);
      expect(find.byKey(CoreKeys.skeleton), findsOneWidget);
    });

    testWidgets('catálogo ilegível mostra o erro padrão, e tentar de novo '
        'recarrega', (tester) async {
      repository.failure = StateError('lixo');
      await openList(tester);
      expect(find.byKey(FeaturedKeys.listError), findsOneWidget);
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      repository.failure = null;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.listScreen), findsOneWidget);
    });

    testWidgets('tocar no cartão abre o final', (tester) async {
      await openList(tester);
      await tester.tap(find.byKey(FeaturedKeys.card('b')));
      await tester.pumpAndSettle();
      expect(find.text('final b'), findsOneWidget);
    });

    testWidgets('tocar no cartão do torneio abre o torneio', (tester) async {
      await openList(tester);
      await tester.tap(find.byKey(FeaturedKeys.tournamentCard('live')));
      await tester.pumpAndSettle();
      expect(find.text('torneio live'), findsOneWidget);
    });

    group('sino', () {
      testWidgets('liga com a permissão e avisa', (tester) async {
        push.granted = true;
        await openList(tester);
        await tester.tap(find.byKey(FeaturedKeys.bell));
        await tester.pumpAndSettle();
        expect(find.byKey(FeaturedKeys.bellNotice), findsOneWidget);
        expect(
          find.text('Notificações de finais novos ligadas'),
          findsOneWidget,
        );
        expect(alerts.all, isTrue);
      });

      testWidgets('desliga e avisa', (tester) async {
        alerts.all = true;
        push.allowed = true;
        await openList(tester);
        await tester.tap(find.byKey(FeaturedKeys.bell));
        await tester.pumpAndSettle();
        expect(
          find.text('Notificações de finais novos desligadas'),
          findsOneWidget,
        );
        expect(alerts.all, isFalse);
      });

      testWidgets('permissão negada oferece abrir os ajustes', (tester) async {
        push.granted = false;
        await openList(tester);
        await tester.tap(find.byKey(FeaturedKeys.bell));
        await tester.pumpAndSettle();
        expect(find.byKey(FeaturedKeys.bellSettings), findsOneWidget);
        expect(alerts.all, isFalse);
        await tester.tap(find.byKey(FeaturedKeys.bellSettings));
        await tester.pumpAndSettle();
        expect(push.settingsOpened, 1);
      });

      testWidgets('vazio: o sino fica ativo e liga o aviso (H-DES-07)', (
        tester,
      ) async {
        repository.value = FeaturedCatalog.empty;
        push.granted = true;
        await openList(tester);
        expect(find.byKey(FeaturedKeys.listEmpty), findsOneWidget);
        final bell = tester.widget<IconButton>(find.byKey(FeaturedKeys.bell));
        expect(bell.onPressed, isNotNull);
        await tester.tap(find.byKey(FeaturedKeys.bell));
        await tester.pumpAndSettle();
        expect(alerts.all, isTrue);
      });

      testWidgets('carregando e vazio: os mesmos ícones na barra', (
        tester,
      ) async {
        Iterable<Key?> icons() => tester
            .widgetList<IconButton>(
              find.descendant(
                of: find.byType(AppBar),
                matching: find.byType(IconButton),
              ),
            )
            .map((b) => b.key)
            .where((k) => k != null);
        await openList(tester, load: false);
        final loading = icons().toList();
        expect(loading, contains(FeaturedKeys.bell));
        repository.value = FeaturedCatalog.empty;
        await openList(tester);
        expect(icons().toList(), loading);
      });

      testWidgets('carregando, o sino fica desabilitado', (tester) async {
        await openList(tester, load: false);
        final bell = tester.widget<IconButton>(find.byKey(FeaturedKeys.bell));
        expect(bell.onPressed, isNull);
      });
    });
  });

  group('torneio', () {
    Future<void> openTournament(
      WidgetTester tester,
      String id, {
      bool load = true,
    }) => pump(
      tester,
      const FeaturedTournamentScreen(),
      location: '/t/$id',
      path: '/t/:id',
      load: load,
    );

    testWidgets('em andamento: selos, datas, links e finais para praticar', (
      tester,
    ) async {
      await openTournament(tester, 'live');
      expect(find.byKey(FeaturedKeys.tournamentSummary), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentOngoing), findsOneWidget);
      expect(find.text('Oslo · 28 de dezembro a 5 de janeiro'), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentLinkResults), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentLinkLive), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentLinkAbout), findsNothing);
      expect(find.byKey(FeaturedKeys.tournamentPractice), findsOneWidget);
      expect(find.text('Finais para praticar'), findsOneWidget);
      expect(find.byKey(FeaturedKeys.card('b')), findsOneWidget);
    });

    testWidgets('não há aviso por torneio', (tester) async {
      await openTournament(tester, 'live');
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('terminado: só "Sobre o torneio" e sem "Em andamento"', (
      tester,
    ) async {
      repository.value = FeaturedCatalog(
        tournaments: [
          FeaturedTournament(
            id: 'past',
            name: 'Passado',
            year: 2017,
            place: 'Stavanger',
            links: [
              FeaturedLink(
                kind: FeaturedLinkKind.info,
                url: Uri.parse('https://example.org/about'),
              ),
              FeaturedLink(
                kind: FeaturedLinkKind.results,
                url: Uri.parse('https://example.org/results'),
              ),
            ],
          ),
        ],
        finals: const [],
      );
      await openTournament(tester, 'past');
      expect(find.byKey(FeaturedKeys.tournamentOngoing), findsNothing);
      expect(find.byKey(FeaturedKeys.tournamentLinkAbout), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentLinkResults), findsNothing);
      expect(find.text('Stavanger · 2017'), findsOneWidget);
    });

    testWidgets('sem finais: avisa que aparecem quando as partidas acabam', (
      tester,
    ) async {
      repository.value = FeaturedCatalog(
        tournaments: sampleFeaturedCatalog().tournaments,
        finals: const [],
      );
      await openTournament(tester, 'live');
      expect(find.byKey(FeaturedKeys.tournamentNoFinals), findsOneWidget);
      expect(find.byKey(FeaturedKeys.tournamentPractice), findsNothing);
    });

    testWidgets('carregando mostra o esqueleto', (tester) async {
      await openTournament(tester, 'live', load: false);
      expect(find.byKey(FeaturedKeys.tournamentLoading), findsOneWidget);
      expect(find.byKey(CoreKeys.skeleton), findsOneWidget);
    });

    testWidgets('torneio que não existe: conteúdo não encontrado', (
      tester,
    ) async {
      await openTournament(tester, 'nada');
      expect(find.byKey(FeaturedKeys.tournamentMissing), findsOneWidget);
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
    });

    testWidgets('leitura que falha mostra o erro padrão e o Voltar', (
      tester,
    ) async {
      repository.failure = StateError('lixo');
      await openTournament(tester, 'live');
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
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

    testWidgets('o tabuleiro do final recebe o voo com o id = FEN', (
      tester,
    ) async {
      await pump(
        tester,
        const FeaturedEndgameScreen(),
        location: '/e/a',
        path: '/e/:id',
      );
      final hero = find.ancestor(
        of: find.byKey(FeaturedKeys.endgameBoard),
        matching: find.byType(TabuleiroHero),
      );
      expect(hero, findsOneWidget);
      expect(
        tester.widget<TabuleiroHero>(hero).id,
        sampleFeaturedCatalog().finals.firstWhere((f) => f.id == 'a').fen,
      );
      final tags = tester.widgetList<Hero>(find.byType(Hero)).map((h) => h.tag);
      expect(
        tags.whereType<String>().where((t) => t.startsWith('featured.')),
        isEmpty,
      );
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
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
    });
  });

  group('Ache o lance', () {
    Future<void> openFind(WidgetTester tester) => pump(
      tester,
      const FeaturedEndgameScreen(),
      location: '/e/b',
      path: '/e/:id',
    );

    testWidgets('falha na dica e retry pendente reativam tabuleiro', (
      tester,
    ) async {
      final controlled = _ControlledProgress()..failWrite = true;
      progress = controlled;
      await openFind(tester);
      await tester.tap(find.byKey(FeaturedKeys.findHint));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      controlled.failWrite = false;
      controlled.gate = Completer<void>();
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byKey(FeaturedKeys.findBoard), findsOneWidget);
      controlled.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.findHintText), findsOneWidget);
      final board = tester.getRect(find.byKey(FeaturedKeys.findBoard));
      await tester.tapAt(squareCenter(board, 'c8', orientation: Side.black));
      await tester.pump();
      await tester.tapAt(squareCenter(board, 'b8', orientation: Side.black));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.findContinue), findsOneWidget);
      expect(controlled.checkpoints['b']!.phase, FindMovePhase.solved);
    });

    testWidgets('falha ao salvar sem pilha permite voltar para o início', (
      tester,
    ) async {
      progress = _ControlledProgress()..failWrite = true;
      await openFind(tester);
      await tester.tap(find.byKey(FeaturedKeys.findHint));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      await tester.tap(find.byKey(LoadErrorKeys.back));
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
    });

    testWidgets('botão continua com spinner até salvar e retry regrava', (
      tester,
    ) async {
      final controlled = _ControlledProgress();
      progress = controlled;
      await openFind(tester);
      controlled.gate = Completer<void>();
      await tester.tap(find.byKey(FeaturedKeys.findAnswer));
      await tester.pump();
      expect(find.byKey(FeaturedKeys.findScreen), findsOneWidget);
      expect(find.byKey(FeaturedKeys.findAnswer), findsOneWidget);
      expect(find.byKey(FeaturedKeys.findContinue), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(FeaturedKeys.findAnswer),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      controlled.failWrite = true;
      controlled.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      controlled.failWrite = false;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.findContinue), findsOneWidget);
      expect(controlled.checkpoints['b']!.phase, FindMovePhase.revealed);
    });

    testWidgets('erro ao ler checkpoint usa erro padrão e retry', (
      tester,
    ) async {
      final controlled = _ControlledProgress()..failRead = true;
      progress = controlled;
      await openFind(tester);
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      controlled.failRead = false;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.findScreen), findsOneWidget);
    });

    testWidgets('reabrir pelo parent conserva a dica', (tester) async {
      await openFind(tester);
      await tester.tap(find.byKey(FeaturedKeys.findHint));
      await tester.pumpAndSettle();
      expect(find.byKey(FeaturedKeys.findHintText), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await openFind(tester);
      expect(find.byKey(FeaturedKeys.findHintText), findsOneWidget);
    });

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
