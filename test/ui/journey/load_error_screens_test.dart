import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/achievement.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/daily_final.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/ui/achievements/view_models/achievements_cubit.dart';
import 'package:lucena/ui/achievements/widgets/achievements_screen.dart';
import 'package:lucena/ui/challenge/view_models/challenge_link_cubit.dart';
import 'package:lucena/ui/challenge/widgets/challenge_link_screen.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/daily/view_models/daily_start_cubit.dart';
import 'package:lucena/ui/daily/widgets/daily_start_screen.dart';
import 'package:lucena/ui/journey/view_models/journey_cubit.dart';
import 'package:lucena/ui/journey/widgets/challenge_screen.dart';
import 'package:lucena/ui/journey/widgets/journey_screen.dart';
import 'package:lucena/ui/journey/widgets/rung_screen.dart';
import 'package:lucena/ui/race/view_models/race_cubit.dart';
import 'package:lucena/ui/race/view_models/race_performance_cubit.dart';
import 'package:lucena/ui/race/view_models/race_warm_up_cubit.dart';
import 'package:lucena/ui/race/widgets/race_performance_screen.dart';
import 'package:lucena/ui/race/widgets/race_screen.dart';
import 'package:lucena/ui/race/widgets/race_warm_up_screen.dart';
import 'package:lucena/ui/school/view_models/star_challenge_cubit.dart';
import 'package:lucena/ui/school/widgets/star_challenge_screen.dart';
import 'package:lucena/ui/school/widgets/star_challenges_screen.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_history_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_attempt_screen.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_history_screen.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_list_screen.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_screen.dart';
import 'package:lucena/ui/streak/view_models/streak_cubit.dart';

import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_daily_final_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/fakes/fake_star_challenge_repository.dart';
import '../../../testing/test_app.dart';

class _Failure {
  Object? error = StateError('database unavailable');
  void check() {
    final error = this.error;
    if (error != null) throw error;
  }
}

class _Journey extends FakeJourneyRepository {
  _Journey(this.failure);
  final _Failure failure;
  @override
  Future<List<Rung>> ladder() async {
    failure.check();
    return super.ladder();
  }

  @override
  Future<List<Speedrun>> speedruns() async {
    failure.check();
    return super.speedruns();
  }
}

class _Characters extends FakeCharacterRepository {
  _Characters(this.failure);
  final _Failure failure;
  @override
  Future<List<Character>> characters() async {
    failure.check();
    return super.characters();
  }
}

class _Race extends FakeRaceRepository {
  _Race(this.failure) : super(now: FakeNow(DateTime(2026, 11, 2)));
  final _Failure failure;
  @override
  Future<List<RaceProblem>> problems() async {
    failure.check();
    return super.problems();
  }
}

class _Daily extends FakeDailyFinalRepository {
  _Daily(this.failure);
  final _Failure failure;
  @override
  Future<DailyFinal?> of(DateTime at) async {
    failure.check();
    return super.of(at);
  }
}

class _Stars extends FakeStarChallengeRepository {
  _Stars(this.failure);
  final _Failure failure;
  @override
  Future<StarChallengeProgress> load() async {
    failure.check();
    return super.load();
  }
}

class _Achievements extends FakeAchievementsRepository {
  _Achievements(this.failure);
  final _Failure failure;
  @override
  Future<List<Achievement>> all() async {
    failure.check();
    return super.all();
  }
}

void main() {
  final now = FakeNow(DateTime(2026, 11, 2));
  const screens = [
    'journey',
    'rung',
    'challenge',
    'link',
    'speedruns',
    'speedrun',
    'attempt',
    'history',
    'race',
    'performance',
    'warm-up',
    'daily',
    'achievements',
    'stars',
    'star',
    'rung-missing',
    'challenge-missing',
    'speedrun-missing',
    'attempt-missing',
    'history-missing',
    'star-invalid',
  ];

  for (final screen in screens) {
    testWidgets('$screen: erro externo e nova tentativa com dados bons', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 917);
      addTearDown(tester.view.reset);
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await settings.load();
      final missing = screen.endsWith('-missing') || screen == 'star-invalid';
      final failure = _Failure();
      if (missing) failure.error = null;
      final journey = _Journey(failure);
      final progress = FakeProgressRepository();
      final speedruns = FakeSpeedrunRepository(progress);
      final attempt = await speedruns.start('rung.1000', now());
      final j = JourneyCubit(journey, progress);
      final s = SpeedrunCubit(
        journey: journey,
        speedruns: speedruns,
        games: FakeOngoingGameRepository(),
        now: now,
      );
      final h = SpeedrunHistoryCubit(
        journey: journey,
        speedruns: speedruns,
        rating: FakeRatingRepository(),
        now: now,
      );
      final c = ChallengeLinkCubit(
        _Characters(failure),
        FakeProfileRepository(),
        FakeRatingRepository(),
        link: ChallengeLink(
          fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
          userSide: Side.white,
          opponent: OpponentKind.maia,
          locked: true,
        ),
      );
      final r = RaceCubit(_Race(failure), now);
      final p = RacePerformanceCubit(_Race(failure));
      final w = RaceWarmUpCubit(_Race(failure));
      final d = DailyStartCubit(
        daily: _Daily(failure),
        rating: FakeRatingRepository(),
        now: now,
      );
      final a = AchievementsCubit(_Achievements(failure), now: now);
      final st = StarChallengesCubit(progress: _Stars(failure));
      final star = StarChallengeCubit(progress: _Stars(failure), now: now);
      final streak = StreakCubit(activity: FakeActivityRepository(), now: now);
      for (final cubit in <BlocBase<dynamic>>[
        j,
        s,
        h,
        c,
        r,
        p,
        w,
        d,
        a,
        st,
        star,
        streak,
      ]) {
        addTearDown(cubit.close);
      }
      await streak.load();
      final (load, child) = switch (screen) {
        'rung-missing' => (
          () => j.load(rungId: 'absent'),
          const RungScreen(rungId: 'absent'),
        ),
        'challenge-missing' => (
          () => j.load(rungId: '1000', positionId: 'absent'),
          const ChallengeScreen(rungId: '1000'),
        ),
        'speedrun-missing' => (
          () => s.load(speedrunId: 'absent'),
          const SpeedrunScreen(),
        ),
        'attempt-missing' => (
          () => s.load(speedrunId: 'rung.1000', attemptId: -1),
          const SpeedrunAttemptScreen(),
        ),
        'history-missing' => (
          () => h.load('absent'),
          const SpeedrunHistoryScreen(),
        ),
        'journey' => (j.load, const JourneyScreen()),
        'rung' => (
          () => j.load(rungId: '1000'),
          const RungScreen(rungId: '1000'),
        ),
        'challenge' => (
          () => j.load(rungId: '1000', positionId: 'basic.queen.0001'),
          const ChallengeScreen(rungId: '1000'),
        ),
        'link' => (c.load, const ChallengeLinkScreen()),
        'speedruns' => (s.load, const SpeedrunListScreen()),
        'speedrun' => (
          () => s.load(speedrunId: 'rung.1000'),
          const SpeedrunScreen(),
        ),
        'attempt' => (
          () => s.load(speedrunId: 'rung.1000', attemptId: attempt.id),
          const SpeedrunAttemptScreen(),
        ),
        'history' => (() => h.load('rung.1000'), const SpeedrunHistoryScreen()),
        'race' => (r.load, const RaceScreen()),
        'performance' => (p.load, const RacePerformanceScreen()),
        'warm-up' => (
          w.load,
          RaceWarmUpScreen(
            args: RaceWarmUpArgs(opponent: 'Maia', onPlay: (_) {}),
          ),
        ),
        'daily' => (d.load, const DailyStartScreen()),
        'achievements' => (a.load, const AchievementsScreen()),
        'stars' => (st.load, const StarChallengesScreen()),
        _ => (
          () => star.load(
            ChallengePiece.values.first,
            ChallengeLevel.values.first,
          ),
          const StarChallengeScreen(),
        ),
      };
      await load();
      final router = GoRouter(
        initialLocation: screen == 'star-invalid'
            ? '/test/invalid/invalid'
            : '/test',
        routes: [
          GoRoute(
            path: screen == 'star-invalid' ? '/test/:piece/:level' : '/test',
            builder: (_, _) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: j),
                BlocProvider.value(value: s),
                BlocProvider.value(value: h),
                BlocProvider.value(value: c),
                BlocProvider.value(value: r),
                BlocProvider.value(value: p),
                BlocProvider.value(value: w),
                BlocProvider.value(value: d),
                BlocProvider.value(value: a),
                BlocProvider.value(value: st),
                BlocProvider.value(value: star),
                BlocProvider.value(value: streak),
              ],
              child: child,
            ),
          ),
          GoRoute(path: '/', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/board', builder: (_, _) => const Scaffold()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          locale: const Locale('pt'),
          router: router,
          child: const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(
        tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
        missing ? LoadErrorKind.notFound : LoadErrorKind.generic,
      );
      if (missing) expect(find.byKey(LoadErrorKeys.back), findsNothing);
      failure.error = null;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (error, kind) in <(Object, LoadErrorKind)>[
    (const LessonContentNetworkUnavailable(), LoadErrorKind.offline),
    (const LessonContentStorageUnavailable(1), LoadErrorKind.noSpace),
    (const LessonContentUnavailable(), LoadErrorKind.unavailable),
  ]) {
    testWidgets('Jornada distingue $kind e retry mantém parâmetros', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 917);
      addTearDown(tester.view.reset);
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await settings.load();
      final failure = _Failure()..error = error;
      final cubit = JourneyCubit(_Journey(failure), FakeProgressRepository());
      addTearDown(cubit.close);
      await cubit.load(rungId: '1000');
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          child: BlocProvider.value(
            value: cubit,
            child: const RungScreen(rungId: '1000'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
        kind,
      );
      failure.error = null;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsNothing);
    });
  }
}
