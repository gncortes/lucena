import 'package:dartchess/dartchess.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository_local.dart';
import 'package:lucena/data/repositories/rating/rating_repository_local.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/platform_rating.dart';
import 'package:lucena/domain/use_cases/rating_conversion.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/profile/widgets/profile_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/settings/widgets/settings_screen.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_chesscom_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_lichess_repository.dart';
import '../../../testing/fakes/fake_maia_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

/// B1 (T85): o rating do jogador é um só em toda tela. Repositórios reais
/// (banco em memória), nenhum que devolva número pronto: o estado é "sem
/// conta, nível informado 1450, venceu uma partida".
void main() {
  late AppDatabase database;
  late LocalProfileRepository profiles;
  late LocalRatingRepository ratings;
  final now = FakeNow(DateTime.utc(2026, 10, 4, 12));

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    profiles = LocalProfileRepository(database);
    ratings = LocalRatingRepository(
      database,
      maia: FakeMaiaRepository(),
      profile: profiles,
      now: now,
    );
  });

  late ProfileCubit staleProfile;

  setUp(() async {
    // Lido na abertura do app, antes de qualquer nível informado.
    staleProfile = ProfileCubit(profiles);
    await staleProfile.load();
    addTearDown(staleProfile.close);
  });

  tearDown(() => database.close());

  /// Devolve o rating que o jogador tem depois da vitória.
  Future<int> informedThenWon() async {
    await profiles.save(
      const UserProfile(rating: 1450, levelSource: LevelSource.manual),
    );
    await ratings.rate(
      Attempt(
        positionId: 'basic.queen.0001',
        playedAt: now(),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 1600,
        startFen: '4k3/8/8/8/8/8/8/3QK3 w - - 0 1',
      ),
      userSide: Side.white,
      drawGoal: false,
      gameId: 1,
    );
    final rating = (await ratings.current()).rounded;
    expect(rating, isNot(1450), reason: 'a vitória mexeu no rating');
    return rating;
  }

  Future<int> homeRating() async {
    final cubit = HomeCubit(
      journey: FakeJourneyRepository(),
      progress: FakeProgressRepository(),
      onboarding: FakeOnboardingRepository(
        const Onboarding(done: true, boardControlsDone: true),
      ),
      characters: FakeCharacterRepository(),
      rating: ratings,
      lessons: FakeLessonRepository(),
      school: FakeSchoolProgressRepository(),
      profile: profiles,
      endgameLessons: FakeEndgameLessonRepository(),
      endgameProgress: FakeEndgameProgressRepository(),
      homeLayout: FakeHomeLayoutRepository(),
      positions: FakePositionsRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit.state.rating!;
  }

  /// Monta [screen] com o perfil já lido (como o do app, antes do jogador
  /// informar o nível: valor padrão) e os repositórios reais.
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 1400);
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings(languageCode: 'pt')),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final accounts = FakeAccountRepository();
    final scheduler = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(scheduler.dispose);
    await tester.pumpWidget(
      TestApp(
        profileCubit: staleProfile,
        settingsCubit: settings,
        ratingRepository: ratings,
        locale: const Locale('pt', 'BR'),
        router: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => MultiRepositoryProvider(
                providers: [
                  RepositoryProvider<AccountRepository>.value(value: accounts),
                  RepositoryProvider<SyncScheduler>.value(value: scheduler),
                  RepositoryProvider<LichessRepository>.value(
                    value: FakeLichessRepository(),
                  ),
                  RepositoryProvider<ProfileRepository>.value(value: profiles),
                  RepositoryProvider<Now>.value(value: now),
                ],
                child: screen,
              ),
            ),
          ],
        ),
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectEverywhere(WidgetTester tester, int expected) async {
    expect(await homeRating(), expected);
    await pumpScreen(tester, const SettingsScreen());
    expect(
      tester.widget<Text>(find.byKey(SettingsKeys.profileValue)).data,
      endsWith(' · $expected'),
    );
    await pumpScreen(tester, const ProfileScreen());
    expect(
      find.descendant(
        of: find.byKey(ProfileKeys.rowLevel),
        matching: find.textContaining('$expected'),
      ),
      findsOneWidget,
    );
  }

  testWidgets('sem conta, nível 1450 e uma vitória: o mesmo rating em Início, '
      'Configurações e Perfil', (tester) async {
    final expected = await informedThenWon();
    await expectEverywhere(tester, expected);
  });

  /// Quem já jogou (1450 informado, uma vitória) abre a tela de nível pelo
  /// Perfil, como no app, com repositórios reais.
  Future<LevelCubit> levelAfterGames(FakeLichessRepository lichess) async {
    await informedThenWon();
    final cubit = LevelCubit(
      onboarding: FakeOnboardingRepository(
        const Onboarding(done: true, boardControlsDone: true),
      ),
      profile: profiles,
      characters: FakeCharacterRepository(),
      lichess: lichess,
      chessCom: FakeChessComRepository(),
      home: FakeHomeLayoutRepository(),
      fromProfile: true,
      rating: ratings,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  testWidgets('conectar o Lichess (1800) depois de partidas: o 1800 vira o '
      'rating em toda tela', (tester) async {
    final lichess = PlatformRating(
      user: 'zuri',
      readAt: DateTime.utc(2026, 10, 4),
      blitz: const ModeRating(rating: 1800, games: 200),
    );
    expect(RatingConversion.toLucena(RatingOrigin.lichess, 1800), 1800);
    final level = await levelAfterGames(FakeLichessRepository(rating: lichess));
    level.select(LevelChoice.lichess);
    await level.connectLichess();
    await level.useLichess();
    await expectEverywhere(tester, 1800);
  });

  testWidgets('escolher a faixa depois de partidas: a faixa vira o rating '
      'em toda tela', (tester) async {
    final level = await levelAfterGames(FakeLichessRepository());
    level.select(LevelChoice.band);
    level.selectBand(RatingLevel.advanced);
    await level.finish();
    await expectEverywhere(tester, RatingLevel.advanced.rating);
  });
}
