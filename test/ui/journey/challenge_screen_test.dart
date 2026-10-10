import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/pace_keys.dart';
import 'package:lucena/ui/core/widgets/game_board_hero.dart';
import 'package:lucena/ui/journey/widgets/journey_ui.dart';
import 'package:lucena/ui/journey/view_models/journey_cubit.dart';
import 'package:lucena/ui/journey/widgets/challenge_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T64: o desafio da Jornada com o tabuleiro no centro do espaço entre a
/// barra do app e o painel do adversário e das partidas.
void main() {
  final rung = sampleLadder.first;
  final challenge = rung.challenges.first;

  Future<void> pump(WidgetTester tester, Size screen, double scale) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = screen;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final cubit = JourneyCubit(
      FakeJourneyRepository(),
      FakeProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load(rungId: rung.id, positionId: challenge.position.id);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: ChallengeScreen(rungId: rung.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (screen, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(412, 915), 1.0),
    (const Size(360, 640), 1.6),
  ]) {
    testWidgets('$screen × $scale: tabuleiro no centro, o painel rola e o '
        'botão de jogar fica à vista', (tester) async {
      await pump(tester, screen, scale);
      final appBar = tester.getRect(find.byType(AppBar));
      final panel = tester.getRect(find.byKey(JourneyKeys.challengePanel));
      final board = tester.getRect(find.byKey(JourneyKeys.challengeBoard));
      expect(board.center.dy, closeTo((appBar.bottom + panel.top) / 2, 1));
      expect(board.bottom, lessThanOrEqualTo(panel.top));
      expect(find.byKey(JourneyKeys.play).hitTestable(), findsOne);
      await tester.scrollUntilVisible(
        find.byKey(JourneyKeys.emptyHistory),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(JourneyKeys.emptyHistory));
      await tester.pumpAndSettle();
      expect(find.byKey(JourneyKeys.emptyHistory).hitTestable(), findsOne);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('"Jogar": o tabuleiro grande voa até o centro da partida e, na '
      'volta, retoma a marca dele sem voar de volta', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final cubit = JourneyCubit(
      FakeJourneyRepository(),
      FakeProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load(rungId: rung.id, positionId: challenge.position.id);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final side = challenge.position.fen.split(' ')[1] == 'b'
        ? Side.black
        : Side.white;
    const gameBoard = Key('test.gameBoard');
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.expand()),
        ),
        GoRoute(
          path: '/challenge/:rung/:position',
          builder: (context, state) => BlocProvider.value(
            value: cubit,
            child: ChallengeScreen(rungId: rung.id),
          ),
        ),
        // A partida, com o tabuleiro no centro.
        GoRoute(
          path: '/board',
          pageBuilder: (context, state) => gamePage(
            context,
            state,
            Scaffold(
              appBar: AppBar(),
              body: Center(
                child: GameBoardHero(
                  orientation: side,
                  child: const SizedBox.square(
                    key: gameBoard,
                    dimension: 400,
                    child: ColoredBox(color: Colors.brown),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    unawaited(router.push('/challenge/${rung.id}/${challenge.position.id}'));
    await tester.pumpAndSettle();
    final start = tester.getRect(find.byKey(JourneyKeys.challengeBoard));

    await tester.tap(find.byKey(JourneyKeys.play));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PaceKeys.confirm));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // No ar: um tabuleiro só, entre o de cima e o do centro da partida.
    expect(find.byType(StaticChessboard), findsOne);
    expect(find.byKey(gameBoard), findsNothing);
    final flying = tester.getRect(find.byType(StaticChessboard));
    expect(flying.center.dy, greaterThanOrEqualTo(start.center.dy - 1));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(gameBoard)).center,
      tester.getCenter(
        find.ancestor(of: find.byKey(gameBoard), matching: find.byType(Center)),
      ),
    );
    expect(find.byType(StaticChessboard), findsNothing);

    // Na volta, nada voa: a marca do voo já não é a do tabuleiro da
    // partida, e o do desafio retoma a marca dele.
    expect(
      tester
          .widget<Hero>(
            find.ancestor(
              of: find.byKey(gameBoard),
              matching: find.byType(Hero),
            ),
          )
          .tag,
      isNot(gameBoardTag(side)),
    );
    router.pop();
    await tester.pumpAndSettle();
    final hero = tester.widget<Hero>(
      find.ancestor(
        of: find.byKey(JourneyKeys.challengeBoard),
        matching: find.byType(Hero),
      ),
    );
    expect(hero.tag, challengeBoardTag(challenge.id));
    expect(tester.getRect(find.byKey(JourneyKeys.challengeBoard)), start);
    expect(tester.takeException(), isNull);
  });
}
