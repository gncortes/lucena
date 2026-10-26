import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/main.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_dependencies.dart';

void main() {
  for (final action in ['close', 'back', 'continue', 'hub-close', 'hub-back']) {
    testWidgets('Clássico: $action preserva o cursor da terceira etapa', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.reset);
      final now = FakeNow(DateTime.utc(2026, 10, 26, 12));
      final progress = FakeProgressRepository();
      final speedruns = FakeSpeedrunRepository(progress);
      final games = FakeOngoingGameRepository();
      final template = sampleSpeedruns[1];
      final base = SpeedrunPaces.withTime(template, sampleSpeedrunTime);
      final attempt = await speedruns.start(base.id, now());
      for (final stage in [0, 1]) {
        now.advance(const Duration(seconds: 20));
        await progress.addAttempt(
          Attempt(
            positionId: samplePositions[0].id,
            playedAt: now(),
            outcome: AttemptOutcome.win,
            fulfilled: true,
            opponent: OpponentKind.maia,
            opponentLevel: 1000,
            userClock: const Duration(seconds: 20),
            userTime: base.time,
            startFen: samplePositions[0].fen,
            endReason: GameEndReason.checkmate,
            speedrunAttemptId: attempt.id,
            speedrunStage: stage,
          ),
        );
      }
      await tester.pumpWidget(
        LucenaApp(
          dependencies: testDependencies(
            now: now,
            progressRepository: progress,
            speedrunRepository: speedruns,
            ongoingGameRepository: games,
            journeyRepository: FakeJourneyRepository(speedruns: [template]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byKey(HomeKeys.screen)));
      if (action.startsWith('hub-')) {
        router.push(Routes.allModes);
        await tester.pumpAndSettle();
        router.push(Routes.speedruns);
        await tester.pumpAndSettle();
        router.push(Routes.speedrun(base.id));
        await tester.pumpAndSettle();
        router.push(Routes.conclusion(2));
      } else {
        router.go(Routes.conclusion(2));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(ConclusionKeys.screen), findsOneWidget);
      expect(games.snapshot, isNull);

      if (action.endsWith('back')) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(
          find.byKey(
            action.endsWith('close')
                ? ConclusionKeys.close
                : ConclusionKeys.action(ConclusionAction.nextStage),
          ),
        );
      }
      await tester.pumpAndSettle();

      if (action != 'continue') {
        expect(find.byKey(SpeedrunKeys.screen), findsOneWidget);
        expect(find.byKey(FreeBoardKeys.screen), findsNothing);
        expect(find.byKey(SpeedrunKeys.resume), findsOneWidget);
        expect(games.snapshot, isNull);
        now.advance(const Duration(minutes: 5));
        await tester.pump();
        expect(games.snapshot, isNull);
        expect(progress.attempts, hasLength(2));
        expect((await speedruns.attempt(attempt.id))!.abandonedAt, isNull);
        if (action.startsWith('hub-')) {
          router.pop();
          await tester.pumpAndSettle();
          expect(find.byKey(SpeedrunKeys.listScreen), findsOneWidget);
          router.pop();
          await tester.pumpAndSettle();
          expect(find.byKey(AllModesKeys.screen), findsOneWidget);
          return;
        }
        await tester.tap(find.byKey(SpeedrunKeys.resume));
        await tester.pumpAndSettle();
      }

      final game = tester
          .element(find.byKey(FreeBoardKeys.screen))
          .read<FreeBoardCubit>();
      expect(game.state.mode.speedrunAttemptId, attempt.id);
      expect(game.state.mode.speedrunStage, 2);
      expect(
        game.state.clock!.config.of(game.state.mode.userSide!).initial,
        base.time.initial,
      );
      expect(progress.attempts, hasLength(2));
      expect((await speedruns.attempt(attempt.id))!.abandonedAt, isNull);
    });
  }
}
