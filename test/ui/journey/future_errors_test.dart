import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/journey/view_models/journey_cubit.dart';
import 'package:lucena/ui/journey/widgets/challenge_screen.dart';
import 'package:lucena/ui/school/view_models/star_challenge_cubit.dart';
import 'package:lucena/ui/school/widgets/star_challenge_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/fakes/fake_star_challenge_repository.dart';
import '../../../testing/test_app.dart';

class _Games extends FakeOngoingGameRepository {
  _Games(super.snapshot);
  bool fails = true;
  int reads = 0;
  Completer<void>? gate;

  @override
  Future<GameSnapshot?> load() async {
    reads++;
    await gate?.future;
    if (fails) throw StateError('saved-read-failed');
    return super.load();
  }
}

void main() {
  final rung = sampleLadder.first;
  final challenge = rung.challenges.first;
  late SettingsCubit settings;
  late FakeNow now;
  late List<String> diagnostics;
  late void Function(String?, {int? wrapWidth}) previousPrint;

  setUp(() async {
    final previous = debugPrint;
    previousPrint = previous;
    diagnostics = [];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) diagnostics.add(message);
    };
    addTearDown(() => debugPrint = previous);
    now = FakeNow(DateTime(2026, 11, 2));
    settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TestApp(settingsCubit: settings, child: child));
    await tester.pumpAndSettle();
  }

  JourneyCubit journey() {
    final cubit = JourneyCubit(
      FakeJourneyRepository(),
      FakeProgressRepository(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  testWidgets(
    'partida salva: erro bloqueia jogar; retry aguarda e retoma sem sobrescrever',
    (tester) async {
      final snapshot = GameSnapshot(
        startFen: challenge.position.fen,
        moves: const ['c1d1'],
        mode: GameMode(
          challengeId: challenge.id,
          positionId: challenge.position.id,
          opponent: challenge.opponent.kind,
          level: challenge.opponent.level,
          goal: challenge.goal,
        ),
      );
      final games = _Games(snapshot);
      final cubit = journey();
      await cubit.load(rungId: rung.id, positionId: challenge.position.id);
      await pump(
        tester,
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<OngoingGameRepository>.value(value: games),
            RepositoryProvider<CharacterRepository>.value(
              value: FakeCharacterRepository(),
            ),
          ],
          child: BlocProvider.value(
            value: cubit,
            child: ChallengeScreen(rungId: rung.id),
          ),
        ),
      );
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byKey(JourneyKeys.play), findsNothing);
      expect(
        diagnostics.where((m) => m.contains('saved-read-failed')),
        hasLength(1),
      );
      debugPrint = previousPrint;

      games.gate = Completer<void>();
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      games.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      games.fails = false;
      games.gate = Completer<void>();
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      games.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsNothing);
      expect(find.byKey(JourneyKeys.resume), findsOneWidget);
      expect(games.reads, 3);
      expect(games.snapshot, same(snapshot));
      expect(games.saved, isEmpty);
      expect(games.clearCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final name in ['challenge', 'speedrun', 'star']) {
    for (final synchronous in [false, true]) {
      testWidgets(
        '$name: falha opcional $synchronous diagnosticada mantém ação',
        (tester) async {
          Future<bool> failure() {
            if (synchronous) throw StateError('optional-goal-failed');
            return Future<bool>.error(StateError('optional-goal-failed'));
          }

          late Widget child;
          late Key action;
          if (name == 'challenge') {
            final cubit = journey();
            await cubit.load(
              rungId: rung.id,
              positionId: challenge.position.id,
            );
            child = BlocProvider.value(
              value: cubit,
              child: ChallengeScreen(
                rungId: rung.id,
                trainingGoalDone: failure,
              ),
            );
            action = JourneyKeys.play;
          } else if (name == 'speedrun') {
            final cubit = SpeedrunCubit(
              journey: FakeJourneyRepository(),
              speedruns: FakeSpeedrunRepository(FakeProgressRepository()),
              games: FakeOngoingGameRepository(),
              now: now,
            );
            addTearDown(cubit.close);
            await cubit.load(speedrunId: 'ending.queen');
            child = BlocProvider.value(
              value: cubit,
              child: SpeedrunScreen(trainingGoalDone: failure),
            );
            action = SpeedrunKeys.start;
          } else {
            final cubit = StarChallengeCubit(
              progress: FakeStarChallengeRepository(),
              now: now,
              tickEvery: const Duration(hours: 1),
            );
            addTearDown(cubit.close);
            await cubit.load(ChallengePiece.rook, ChallengeLevel.easy);
            cubit.start();
            now.advance(const Duration(minutes: 1));
            cubit.tick();
            await tester.pump();
            child = BlocProvider.value(
              value: cubit,
              child: StarChallengeScreen(trainingGoalDone: failure),
            );
            action = StarChallengeKeys.retryButton;
          }
          await pump(tester, child);
          debugPrint = previousPrint;
          expect(find.byKey(action), findsOneWidget);
          expect(find.byKey(TrainingKeys.nextGoal), findsNothing);
          expect(find.byKey(LoadErrorKeys.screen), findsNothing);
          expect(
            diagnostics.any((m) => m.contains('optional-goal-failed')),
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
