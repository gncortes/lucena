import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/core/widgets/game_board_hero.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';
import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';
import 'package:lucena/ui/free_board/widgets/free_board_screen.dart';
import 'package:lucena/ui/free_board/widgets/move_list.dart';
import 'package:lucena/ui/game_setup/view_models/game_setup_cubit.dart';
import 'package:lucena/ui/game_setup/widgets/game_setup_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_evaluation_repository.dart';
import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_opponent_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_talk_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';
import '../../../../testing/test_app.dart';

/// Começar a partida na Nova partida: o tabuleiro de cima desliza e cresce
/// até o centro da partida (um tabuleiro só no ar, sem girar), e o resto da
/// tela aparece em volta.
void main() {
  const fen = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';

  Future<void> pump(WidgetTester tester, {required Side gameSide}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final repository = FakeSettingsRepository(const AppSettings());
    final settings = SettingsCubit(
      repository,
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final setup = GameSetupCubit(
      FakeTrainingRepository(),
      progress: FakeProgressRepository(),
      profile: FakeProfileRepository(),
      position: GameRules.fromFen(fen)!,
      goal: PositionGoal.win,
    );
    addTearDown(setup.close);
    await setup.load();
    final now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    // A partida de dois, vista pelo lado pedido (a rota de teste ignora os
    // parâmetros da preparação).
    final game = FreeBoardCubit(
      now: now,
      haptics: FakeHapticsRepository(),
      settings: repository,
      games: FakeOngoingGameRepository(),
      opponent: FakeOpponentRepository(now: now),
      progress: FakeProgressRepository(),
      start: GameRules.fromFen(fen),
      orientation: gameSide,
      mode: const GameMode(opponent: OpponentKind.twoPlayers),
    );
    addTearDown(game.close);
    final talk = TalkCubit(
      characters: FakeCharacterRepository(),
      evaluation: FakeEvaluationRepository(),
      talk: FakeTalkRepository(),
      settings: repository,
      now: now,
      language: 'en',
      random: Random(1),
    );
    addTearDown(talk.close);
    final router = GoRouter(
      routes: [
        // A tela de onde a posição veio (o catálogo, a aula).
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.expand()),
        ),
        GoRoute(
          path: '/setup',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: BlocProvider.value(
              value: setup,
              child: const GameSetupScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/board',
          pageBuilder: (context, state) => gamePage(
            context,
            state,
            MultiBlocProvider(
              providers: [
                BlocProvider.value(value: game),
                BlocProvider.value(value: talk),
              ],
              child: const FreeBoardScreen(),
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
    await tester.pumpAndSettle();
    unawaited(router.push('/setup'));
    await tester.pumpAndSettle();
  }

  Rect boardOf(WidgetTester tester, Finder finder) =>
      tester.getRect(finder.first);

  testWidgets('o tabuleiro de cima desliza e cresce até o centro da partida, '
      'sem girar nem piscar', (tester) async {
    await pump(tester, gameSide: Side.white);
    final preview = boardOf(tester, find.byKey(GameSetupKeys.preview));

    await tester.tap(find.byKey(GameSetupKeys.startButton));
    await tester.pump();
    await tester.pump();

    // No ar: um tabuleiro só, o da viagem; o da partida espera escondido.
    final flights = <Rect>[];
    while (find.byKey(FreeBoardKeys.board).evaluate().isEmpty ||
        find.byType(StaticChessboard).evaluate().isNotEmpty) {
      expect(find.byType(StaticChessboard), findsOne);
      expect(find.byType(Chessboard), findsNothing);
      // Sem girar: nenhuma rotação em volta do tabuleiro no ar.
      final turns = find.ancestor(
        of: find.byType(StaticChessboard),
        matching: find.byWidgetPredicate(
          (w) => w is Transform && !w.transform.isIdentity(),
        ),
      );
      expect(turns, findsNothing);
      flights.add(boardOf(tester, find.byType(StaticChessboard)));
      expect(tester.takeException(), isNull);
      if (flights.length > 100) fail('o voo não terminou');
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final board = boardOf(tester, find.byKey(FreeBoardKeys.board));
    expect(flights.length, greaterThan(5));
    // Sai de onde estava e chega aonde o tabuleiro da partida fica: nada
    // salta no começo nem no fim.
    expect(flights.first.center.dx, closeTo(preview.center.dx, 4));
    expect(flights.first.center.dy, closeTo(preview.center.dy, 12));
    expect(flights.last.width, closeTo(board.width, 4));
    expect(flights.last.center.dy, closeTo(board.center.dy, 4));
    // Só cresce e desce.
    for (var i = 1; i < flights.length; i++) {
      expect(flights[i].width, greaterThanOrEqualTo(flights[i - 1].width - 1));
      expect(
        flights[i].center.dy,
        greaterThanOrEqualTo(flights[i - 1].center.dy - 1),
      );
      expect(flights[i].width, closeTo(flights[i].height, 0.5));
    }

    // O tabuleiro final fica no centro do layout de partida.
    final area = tester.getRect(find.byKey(FreeBoardKeys.scrollArea));
    expect(board.center.dx, closeTo(area.center.dx, 1));
    expect(
      board.center.dy,
      closeTo((area.top - MoveList.height + area.bottom) / 2, 1),
    );
    expect(find.byType(StaticChessboard), findsNothing);
    expect(find.byKey(GameSetupKeys.preview), findsNothing);

    // A marca do voo é só de ida: o tabuleiro da partida já não a usa.
    final hero = tester.widget<Hero>(
      find.ancestor(
        of: find.byKey(FreeBoardKeys.board),
        matching: find.byType(Hero),
      ),
    );
    expect(hero.tag, isNot(gameBoardTag(Side.white)));
  });

  testWidgets('a partida vista pelo outro lado: nada voa, a tela só aparece '
      'num fade', (tester) async {
    await pump(tester, gameSide: Side.black);
    final preview = boardOf(tester, find.byKey(GameSetupKeys.preview));

    await tester.tap(find.byKey(GameSetupKeys.startButton));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // A prévia fica parada embaixo, e o tabuleiro da partida já está no
    // lugar dele, aparecendo com o resto.
    expect(boardOf(tester, find.byKey(GameSetupKeys.preview)), preview);
    expect(find.byKey(FreeBoardKeys.board), findsOne);
    expect(
      tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.byKey(FreeBoardKeys.board),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value,
      inExclusiveRange(0, 1),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(GameSetupKeys.preview), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
