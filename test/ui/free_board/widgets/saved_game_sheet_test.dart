import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/free_board/widgets/saved_game_sheet.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

// Coco (1000) de pretas, o jogador de brancas, depois de 1. e4 e5 2. Nf3.
final _journey = GameSnapshot(
  startFen: Chess.initial.fen,
  moves: const ['e2e4', 'e7e5', 'g1f3'],
  mode: const GameMode(
    opponent: OpponentKind.maia,
    level: 1000,
    userSide: Side.white,
    challengeId: 'coco.queen',
    positionId: 'basic.queen',
  ),
);

void main() {
  group('loadSavedGame', () {
    test(
      'sem partida ou com o tabuleiro intocado, não há o que perguntar',
      () async {
        final characters = FakeCharacterRepository();

        expect(
          await loadSavedGame(FakeOngoingGameRepository(), characters),
          isNull,
        );
        expect(
          await loadSavedGame(
            FakeOngoingGameRepository(
              GameSnapshot(startFen: Chess.initial.fen),
            ),
            characters,
          ),
          isNull,
        );
      },
    );

    test(
      'com lances: a posição em que parou e o personagem do nível',
      () async {
        final saved = await loadSavedGame(
          FakeOngoingGameRepository(_journey),
          FakeCharacterRepository(),
        );

        expect(saved!.position.fullmoves, 2);
        expect(saved.lastMove, Move.parse('g1f3'));
        expect(saved.character?.name, 'Coco');
      },
    );
  });

  group('openFreeBoard', () {
    Future<GoRouter> pump(WidgetTester tester, GameSnapshot? snapshot) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => openFreeBoard(context),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/board',
            builder: (context, state) => const Text('tabuleiro'),
          ),
        ],
      );
      addTearDown(router.dispose);
      final settings = SettingsCubit(
        FakeSettingsRepository(const AppSettings()),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await settings.load();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<OngoingGameRepository>.value(
              value: FakeOngoingGameRepository(snapshot),
            ),
            RepositoryProvider<CharacterRepository>.value(
              value: FakeCharacterRepository(),
            ),
          ],
          child: TestApp(
            locale: const Locale('pt'),
            settingsCubit: settings,
            router: router,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return router;
    }

    String location(GoRouter router) =>
        router.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('sem partida guardada, abre o tabuleiro direto', (
      tester,
    ) async {
      final router = await pump(tester, null);

      expect(find.byKey(FreeBoardKeys.savedGameSheet), findsNothing);
      expect(location(router), '/board');
    });

    testWidgets('com partida guardada, mostra a partida e pergunta antes', (
      tester,
    ) async {
      final router = await pump(tester, _journey);

      expect(find.byKey(FreeBoardKeys.savedGameSheet), findsOneWidget);
      expect(find.text('Você tem uma partida em andamento'), findsOneWidget);
      expect(find.text('Coco · 1000'), findsOneWidget);
      expect(find.textContaining('Jornada · '), findsOneWidget);
      expect(find.text('Você está de brancas · lance 2'), findsOneWidget);
      expect(location(router), '/');
    });

    testWidgets('"Continuar a partida" volta à partida guardada', (
      tester,
    ) async {
      final router = await pump(tester, _journey);

      await tester.tap(find.byKey(FreeBoardKeys.savedGameContinue));
      await tester.pumpAndSettle();

      expect(location(router), '/board');
    });

    testWidgets('"Começar um tabuleiro novo" abre a posição inicial', (
      tester,
    ) async {
      final router = await pump(tester, _journey);

      await tester.tap(find.byKey(FreeBoardKeys.savedGameNew));
      await tester.pumpAndSettle();

      final uri = router.routerDelegate.currentConfiguration.uri;
      expect(uri.path, '/board');
      expect(uri.queryParameters['fen'], Chess.initial.fen);
    });

    testWidgets('fechar a folha não abre nada', (tester) async {
      final router = await pump(tester, _journey);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.savedGameSheet), findsNothing);
      expect(location(router), '/');
    });
  });
}
