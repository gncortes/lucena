import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/main.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_dependencies.dart';

void main() {
  for (final action in ['resume', 'cancel-restart', 'confirm-restart']) {
    testWidgets(
      'Jornada: $action preserva ou substitui a partida por escolha',
      (tester) async {
        tester.view.physicalSize = const Size(393, 873);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final challenge = sampleLadder.first.challenges.first;
        final snapshot = GameSnapshot(
          startFen: challenge.position.fen,
          moves: const ['c1d1', 'd7e7'],
          playerSide: Side.white,
          orientation: Side.white,
          onScreen: false,
          mode: GameMode(
            challengeId: challenge.id,
            positionId: challenge.position.id,
            opponent: challenge.opponent.kind,
            level: challenge.opponent.level,
            userSide: Side.white,
            goal: challenge.goal,
          ),
          clock: ClockState(
            config: ClockConfig.same(
              const TimeControl(initial: Duration(minutes: 3)),
            ),
            white: const Duration(seconds: 83),
            black: const Duration(seconds: 101),
          ),
        );
        final games = FakeOngoingGameRepository(snapshot);
        await tester.pumpWidget(
          LucenaApp(
            dependencies: testDependencies(
              now: FakeNow(DateTime.utc(2026, 10, 26)),
              settingsRepository: FakeSettingsRepository(
                const AppSettings(languageCode: 'pt'),
              ),
              ongoingGameRepository: games,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byKey(HomeKeys.screen)));
        router.push(
          Routes.journeyChallenge(sampleLadder.first.id, challenge.position.id),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(JourneyKeys.resume), findsOneWidget);
        expect(games.snapshot, same(snapshot));
        if (action != 'resume') {
          await tester.tap(find.byKey(JourneyKeys.restart));
          await tester.pumpAndSettle();
          expect(games.snapshot, same(snapshot));
          await tester.tap(
            find.byKey(
              action == 'cancel-restart'
                  ? SheetKeys.close
                  : JourneyKeys.restartConfirm,
            ),
          );
          await tester.pumpAndSettle();
          if (action == 'cancel-restart') {
            expect(find.byKey(JourneyKeys.resume), findsOneWidget);
            expect(find.byKey(FreeBoardKeys.screen), findsNothing);
            expect(games.snapshot, same(snapshot));
            expect(games.clearCalls, 0);
            return;
          }
        } else {
          await tester.tap(find.byKey(JourneyKeys.resume));
          await tester.pumpAndSettle();
        }
        final game = tester
            .element(find.byKey(FreeBoardKeys.screen))
            .read<FreeBoardCubit>()
            .state;
        expect(game.mode.challengeId, challenge.id);
        expect(game.playerSide, Side.white);
        if (action == 'resume') {
          var expected = GameRules.fromFen(snapshot.startFen)!;
          for (final uci in snapshot.moves) {
            expected = GameRules.play(expected, Move.parse(uci)!)!.position;
          }
          expect(game.position.fen, expected.fen);
          expect(game.clock!.white, snapshot.clock!.white);
          expect(game.clock!.black, snapshot.clock!.black);
          expect(games.snapshot!.moves, snapshot.moves);
        } else {
          expect(game.position.fen, snapshot.startFen);
          expect(games.snapshot!.moves, isEmpty);
        }
      },
    );
  }
}
