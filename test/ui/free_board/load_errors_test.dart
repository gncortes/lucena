import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';
import 'package:lucena/ui/free_board/widgets/free_board_screen.dart';
import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';

import '../../../testing/fakes/fake_evaluation_repository.dart';
import '../../../testing/fakes/fake_talk_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/history_filter.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/data/repositories/training/training_repository.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/custom_position/view_models/custom_position_cubit.dart';
import 'package:lucena/ui/custom_position/widgets/custom_position_screen.dart';
import 'package:lucena/ui/game_setup/view_models/game_setup_cubit.dart';
import 'package:lucena/ui/game_setup/widgets/game_setup_screen.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';
import 'package:lucena/ui/game_details/widgets/game_details_screen.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/conclusion/widgets/conclusion_screen.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';
import 'package:lucena/ui/blind/view_models/blind_game_cubit.dart';
import 'package:lucena/ui/blind/widgets/blind_game_screen.dart';
import 'package:lucena/ui/blind/widgets/blind_entry_screen.dart';
import 'package:lucena/ui/history/view_models/history_cubit.dart';
import 'package:lucena/ui/history/widgets/history_screen.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/ui/voice/widgets/voice_settings_screen.dart';

import '../../../testing/fakes/fake_training_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_haptics_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/fakes/fake_speech_input_repository.dart';
import '../../../testing/fakes/fake_blind_log_repository.dart';
import '../../../testing/test_app.dart';

class _Training extends FakeTrainingRepository {
  bool broken = true;
  @override
  Future<GameSetup> loadSetup() async {
    if (broken) throw StateError('setup read failed');
    return super.loadSetup();
  }

  @override
  Future<CustomPositionDraft?> loadCustomDraft() async {
    if (broken) throw StateError('draft read failed');
    return super.loadCustomDraft();
  }
}

class _Progress extends FakeProgressRepository {
  bool broken = true;
  @override
  Future<Map<int, Attempt>> attemptsById(Iterable<int> ids) async {
    if (broken) throw StateError('game read failed');
    return super.attemptsById(ids);
  }
}

class _Settings extends FakeSettingsRepository {
  bool broken = true;
  @override
  Future<AppSettings> load() async {
    if (broken) throw StateError('history read failed');
    return super.load();
  }
}

class _Games extends FakeOngoingGameRepository {
  bool broken = true;
  Completer<void>? pending;
  @override
  Future<GameSnapshot?> load() async {
    await pending?.future;
    if (broken) throw StateError('ongoing read failed');
    return super.load();
  }
}

class _Rating extends FakeRatingRepository {
  bool broken = true;
  @override
  Future<PlayerRating> current() async {
    if (broken) throw StateError('rating read failed');
    return super.current();
  }
}

class _Voice extends FakeVoiceRepository {
  bool broken = true;
  @override
  Future<VoiceSettings> load() async {
    if (broken) throw StateError('voice read failed');
    return super.load();
  }
}

void main() {
  final now = FakeNow(DateTime.utc(2026, 11, 2));
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    SpeechCubit? speech,
    bool settle = true,
  }) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final router = GoRouter(
      initialLocation: '/case',
      routes: [
        GoRoute(path: '/case', builder: (_, _) => child),
        GoRoute(path: Routes.home, builder: (_, _) => const SizedBox()),
        GoRoute(path: Routes.blindCatalog, builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        speechCubit: speech,
        settingsCubit: settings,
        router: router,
        child: child,
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  void generic() {
    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
  }

  for (final screen in ['custom', 'blind', 'voice']) {
    testWidgets('$screen initial load has shimmer', (tester) async {
      if (screen == 'custom') {
        final cubit = CustomPositionCubit(FakeTrainingRepository());
        addTearDown(cubit.close);
        await pump(
          tester,
          BlocProvider.value(value: cubit, child: const CustomPositionScreen()),
          settle: false,
        );
      } else if (screen == 'blind') {
        final cubit = BlindGameCubit(
          opponent: FakeOpponentRepository(),
          voice: FakeVoiceRepository(),
          input: FakeSpeechInputRepository(),
          log: FakeBlindLogRepository(),
          now: now,
        );
        addTearDown(cubit.close);
        await pump(
          tester,
          BlocProvider.value(value: cubit, child: const BlindGameScreen()),
          settle: false,
        );
      } else {
        final cubit = SpeechCubit(FakeVoiceRepository());
        addTearDown(cubit.close);
        await pump(
          tester,
          const VoiceSettingsScreen(),
          speech: cubit,
          settle: false,
        );
      }
      expect(find.byType(SkeletonBlock), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
  for (final pendingLoad in [false, true]) {
    testWidgets('FreeBoard UI pending=$pendingLoad', (tester) async {
      final games = _Games();
      final cubit = FreeBoardCubit(
        now: now,
        haptics: FakeHapticsRepository(),
        settings: FakeSettingsRepository(),
        games: games,
        opponent: FakeOpponentRepository(),
        progress: FakeProgressRepository(),
      );
      final talk = TalkCubit(
        characters: FakeCharacterRepository(),
        evaluation: FakeEvaluationRepository(),
        talk: FakeTalkRepository(),
        settings: FakeSettingsRepository(),
        now: now,
        language: 'pt',
      );
      addTearDown(cubit.close);
      addTearDown(talk.close);
      final pending = Completer<void>();
      if (pendingLoad) games.pending = pending;
      final loading = cubit.open();
      if (!pendingLoad) await loading;
      await pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: talk),
          ],
          child: const FreeBoardScreen(),
        ),
        settle: !pendingLoad,
      );
      if (pendingLoad) {
        expect(find.byType(SkeletonBlock), findsWidgets);
        games.broken = false;
        pending.complete();
        await loading;
      } else {
        generic();
        games.broken = false;
        await tester.tap(find.byKey(LoadErrorKeys.action));
      }
      await tester.pumpAndSettle();
      expect(cubit.state.ready, isTrue);
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(find.byType(SkeletonBlock), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('posição própria: falha de leitura e retry recupera editor', (
    tester,
  ) async {
    final training = _Training();
    final cubit = CustomPositionCubit(training);
    addTearDown(cubit.close);
    await cubit.load();
    await pump(
      tester,
      BlocProvider.value(value: cubit, child: const CustomPositionScreen()),
    );
    generic();
    training.broken = false;
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pumpAndSettle();
    expect(find.byType(LoadErrorScreen), findsNothing);
    expect(cubit.state.ready, isTrue);
  });

  testWidgets('setup: falha de leitura e retry recupera configuração', (
    tester,
  ) async {
    final training = _Training();
    final cubit = GameSetupCubit(
      training,
      progress: FakeProgressRepository(),
      profile: FakeProfileRepository(),
      position: GameRules.initial,
      goal: PositionGoal.win,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await pump(
      tester,
      BlocProvider.value(value: cubit, child: const GameSetupScreen()),
    );
    generic();
    training.broken = false;
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pumpAndSettle();
    expect(find.byType(LoadErrorScreen), findsNothing);
    expect(cubit.state.ready, isTrue);
  });

  for (final missing in [false, true]) {
    testWidgets('detalhes: ${missing ? 'id ausente' : 'falha e retry'}', (
      tester,
    ) async {
      final progress = _Progress()..broken = !missing;
      final id = missing
          ? 999
          : await progress.addAttempt(
              Attempt(
                positionId: 'test',
                playedAt: now(),
                outcome: AttemptOutcome.draw,
                fulfilled: false,
                opponent: OpponentKind.twoPlayers,
                startFen: GameRules.initial.fen,
              ),
            );
      final cubit = GameDetailsCubit(id, progress: progress);
      addTearDown(cubit.close);
      await cubit.load(language: 'pt');
      await pump(
        tester,
        BlocProvider.value(value: cubit, child: const GameDetailsScreen()),
      );
      if (missing) {
        expect(find.text('Conteúdo não encontrado'), findsOneWidget);
        expect(find.text('Ir para o início'), findsOneWidget);
        expect(find.byKey(LoadErrorKeys.back), findsNothing);
      } else {
        generic();
        progress.broken = false;
        await tester.tap(find.byKey(LoadErrorKeys.action));
        await tester.pumpAndSettle();
        expect(find.byType(LoadErrorScreen), findsNothing);
        expect(cubit.state.attempt, isNotNull);
      }
    });

    testWidgets('resultado: ${missing ? 'id ausente' : 'falha e retry'}', (
      tester,
    ) async {
      final progress = _Progress()..broken = !missing;
      final id = missing
          ? 999
          : await progress.addAttempt(
              Attempt(
                positionId: 'test',
                playedAt: now(),
                outcome: AttemptOutcome.draw,
                fulfilled: false,
                opponent: OpponentKind.twoPlayers,
                startFen: GameRules.initial.fen,
              ),
            );
      final cubit = ConclusionCubit(
        progress: progress,
        rating: FakeRatingRepository(),
        achievements: FakeAchievementsRepository(),
        journey: FakeJourneyRepository(),
        speedruns: FakeSpeedrunRepository(progress),
        positions: FakePositionsRepository(),
        characters: FakeCharacterRepository(),
        now: now,
      );
      addTearDown(cubit.close);
      await cubit.load(id, 'pt');
      await pump(
        tester,
        BlocProvider.value(value: cubit, child: const ConclusionScreen()),
      );
      if (missing) {
        expect(find.text('Conteúdo não encontrado'), findsOneWidget);
        expect(find.text('Ir para o início'), findsOneWidget);
        expect(find.byKey(LoadErrorKeys.back), findsNothing);
      } else {
        generic();
        progress.broken = false;
        await tester.tap(find.byKey(LoadErrorKeys.action));
        await tester.pumpAndSettle();
        expect(find.byType(LoadErrorScreen), findsNothing);
        expect(cubit.state.conclusion, isNotNull);
      }
    });
  }

  testWidgets('histórico: falha e retry recupera abas', (tester) async {
    final settings = _Settings()
      ..settings = const AppSettings(historyTab: HistoryTab.classic);
    final progress = FakeProgressRepository();
    final cubit = HistoryCubit(
      rating: FakeRatingRepository(),
      progress: progress,
      speedruns: FakeSpeedrunRepository(progress),
      journey: FakeJourneyRepository(),
      characters: FakeCharacterRepository(),
      reviews: FakeGameReviewRepository(),
      settings: settings,
      now: now,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await pump(
      tester,
      BlocProvider.value(value: cubit, child: const HistoryScreen()),
    );
    generic();
    settings.broken = false;
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pumpAndSettle();
    expect(find.byType(LoadErrorScreen), findsNothing);
    expect(cubit.state.loaded, isTrue);
    expect(
      tester.widget<TabBarView>(find.byType(TabBarView)).controller!.index,
      HistoryTab.classic.index,
    );
  });

  test(
    'tabuleiro: falha ao restaurar é recuperável sem perder retry',
    () async {
      final games = _Games();
      final cubit = FreeBoardCubit(
        now: now,
        haptics: FakeHapticsRepository(),
        settings: FakeSettingsRepository(),
        games: games,
        opponent: FakeOpponentRepository(),
        progress: FakeProgressRepository(),
      );
      addTearDown(cubit.close);
      await cubit.open();
      expect((cubit.state as dynamic).failed, isTrue);
      games.broken = false;
      await cubit.open();
      expect(cubit.state.ready, isTrue);
      expect((cubit.state as dynamic).failed, isFalse);
    },
  );

  test('rating legado: falha de carga e recuperação', () async {
    final rating = _Rating();
    final cubit = RatingCubit(rating);
    addTearDown(cubit.close);
    await cubit.load();
    expect((cubit.state as dynamic).failed, isTrue);
    rating.broken = false;
    await cubit.load();
    expect(cubit.state.current, isNotNull);
    expect((cubit.state as dynamic).failed, isFalse);
  });

  testWidgets('às cegas: falha ao carregar voz e retry abre partida', (
    tester,
  ) async {
    final voice = _Voice();
    final cubit = BlindGameCubit(
      opponent: FakeOpponentRepository(),
      voice: voice,
      input: FakeSpeechInputRepository(),
      log: FakeBlindLogRepository(),
      now: now,
    );
    addTearDown(cubit.close);
    final t = await AppLocalizations.delegate.load(const Locale('pt'));
    await cubit.load(
      fen: GameRules.initial.fen,
      userSide: Side.white,
      kind: OpponentKind.maia,
      language: 'pt',
      phrases: blindPhrases(t),
    );
    await pump(
      tester,
      BlocProvider.value(value: cubit, child: const BlindGameScreen()),
    );
    generic();
    voice.broken = false;
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pumpAndSettle();
    expect(find.byType(LoadErrorScreen), findsNothing);
    expect(cubit.state.ready, isTrue);
  });

  for (final entry in [false, true]) {
    testWidgets(
      'voz ${entry ? 'entrada às cegas' : 'ajustes'}: falha e recuperação',
      (tester) async {
        final voice = _Voice();
        final speech = SpeechCubit(voice);
        addTearDown(speech.close);
        await speech.load();
        await pump(
          tester,
          entry ? const BlindEntryScreen() : const VoiceSettingsScreen(),
          speech: speech,
        );
        generic();
        voice.broken = false;
        await tester.tap(find.byKey(LoadErrorKeys.action));
        await tester.pumpAndSettle();
        expect(find.byType(LoadErrorScreen), findsNothing);
        expect(speech.state.loaded, isTrue);
      },
    );
  }
}
