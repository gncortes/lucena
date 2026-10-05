import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/haptics/haptics_repository.dart';
import '../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../config/dependencies.dart';
import '../domain/models/clock.dart';
import '../domain/use_cases/game_rules.dart';
import '../domain/use_cases/now.dart';
import '../ui/board_settings/widgets/board_appearance_screen.dart';
import '../ui/board_settings/widgets/board_behavior_screen.dart';
import '../ui/board_settings/widgets/clock_settings_screen.dart';
import '../data/repositories/journey/journey_repository.dart';
import '../data/repositories/maia/maia_repository.dart';
import '../data/repositories/speedrun/speedrun_repository.dart';
import '../data/repositories/opponent/opponent_repository.dart';
import '../data/repositories/profile/profile_repository.dart';
import '../data/repositories/positions/positions_repository.dart';
import '../data/repositories/progress/progress_repository.dart';
import '../data/repositories/training/training_repository.dart';
import '../domain/models/endgame_position.dart';
import '../domain/models/game_mode.dart';
import '../domain/models/game_setup.dart';
import '../ui/catalog/view_models/catalog_cubit.dart';
import '../ui/catalog/widgets/catalog_screen.dart';
import '../ui/catalog/widgets/category_screen.dart';
import '../ui/catalog/widgets/subcategory_screen.dart';
import '../ui/custom_position/view_models/custom_position_cubit.dart';
import '../ui/custom_position/widgets/custom_position_screen.dart';
import '../ui/game_setup/view_models/game_setup_cubit.dart';
import '../ui/game_setup/widgets/game_setup_screen.dart';
import '../ui/free_board/view_models/free_board_cubit.dart';
import '../ui/free_board/view_models/talk_cubit.dart';
import '../ui/free_board/widgets/free_board_screen.dart';
import '../data/repositories/achievements/achievements_repository.dart';
import '../data/repositories/characters/character_repository.dart';
import '../data/repositories/characters/talk_repository.dart';
import '../data/repositories/evaluation/evaluation_repository.dart';
import '../data/repositories/rating/rating_repository.dart';
import '../data/repositories/pace/pace_repository.dart';
import '../ui/home/view_models/home_cubit.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/achievements/view_models/achievements_cubit.dart';
import '../ui/achievements/widgets/achievements_screen.dart';
import '../data/repositories/school/lesson_repository.dart';
import '../data/repositories/school/school_progress_repository.dart';
import '../ui/school/view_models/lesson_cubit.dart';
import '../ui/school/view_models/school_cubit.dart';
import '../ui/school/widgets/lesson_screen.dart';
import '../ui/school/widgets/school_screen.dart';
import '../ui/tour/view_models/tour_cubit.dart';
import '../ui/tour/widgets/tour_screen.dart';
import '../data/repositories/onboarding/onboarding_repository.dart';
import '../ui/journey/view_models/journey_cubit.dart';
import '../ui/journey/widgets/challenge_screen.dart';
import '../ui/journey/widgets/journey_screen.dart';
import '../ui/journey/widgets/rung_screen.dart';
import '../ui/speedrun/view_models/speedrun_cubit.dart';
import '../ui/speedrun/widgets/speedrun_attempt_screen.dart';
import '../ui/speedrun/widgets/speedrun_list_screen.dart';
import '../ui/speedrun/widgets/speedrun_screen.dart';
import '../ui/maia_debug/view_models/maia_debug_cubit.dart';
import '../ui/maia_debug/widgets/maia_debug_screen.dart';
import '../ui/profile/view_models/rating_cubit.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/settings/widgets/language_screen.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/settings/widgets/theme_screen.dart';
import '../ui/core/widgets/reload_on_return.dart';
import 'routes.dart';

/// [initialLocation] é a tela em que o app abre; as telas de baixo dela na
/// árvore de rotas entram junto, para o botão de voltar funcionar.
GoRouter buildRouter({String initialLocation = Routes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.tour,
        builder: (context, state) => BlocProvider(
          create: (context) => TourCubit(
            onboarding: context.read<OnboardingRepository>(),
            profile: context.read<ProfileRepository>(),
            characters: context.read<CharacterRepository>(),
            lessons: context.read<LessonRepository>(),
          )..load(Localizations.localeOf(context).languageCode),
          child: const TourScreen(),
        ),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => BlocProvider(
          create: (context) => HomeCubit(
            journey: context.read<JourneyRepository>(),
            progress: context.read<ProgressRepository>(),
            onboarding: context.read<OnboardingRepository>(),
            characters: context.read<CharacterRepository>(),
            rating: context.read<RatingRepository>(),
            lessons: context.read<LessonRepository>(),
            school: context.read<SchoolProgressRepository>(),
            profile: context.read<ProfileRepository>(),
          )..load(),
          child: Builder(
            builder: (context) => ReloadOnReturn(
              onReturn: () => context.read<HomeCubit>().load(),
              child: const HomeScreen(),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'board',
            builder: (context, state) {
              // Sem parâmetros, a tela continua a partida em andamento (ou
              // começa uma do início). Com parâmetros, começa uma partida nova:
              // `?fen=` abre numa posição preparada; FEN inválido cai na inicial.
              // `?side=` deixa o jogador mover só as peças de um lado.
              final fen = state.uri.queryParameters['fen'];
              final side = state.uri.queryParameters['side'];
              final view = state.uri.queryParameters['view'];
              // `?white=` e `?black=` (tempo de cada lado) ligam o relógio.
              final white = TimeControl.tryParse(
                state.uri.queryParameters['white'],
              );
              final black = TimeControl.tryParse(
                state.uri.queryParameters['black'],
              );
              final isNewGame = state.uri.queryParameters.isNotEmpty;
              final query = state.uri.queryParameters;
              final sides = Side.values.asNameMap();
              final opponent = query['opponent'];
              final mode = GameMode(
                opponent: opponent == null
                    ? OpponentKind.twoPlayers
                    : OpponentKind.fromCode(opponent),
                level: int.tryParse(query['level'] ?? ''),
                userSide: sides[query['user']],
                goal: PositionGoal.fromCode(query['goal']),
                positionId: query['position'],
                challengeId: query['challenge'],
                speedrunId: query['speedrun'],
                speedrunAttemptId: int.tryParse(query['attempt'] ?? ''),
                speedrunStage: int.tryParse(query['stage'] ?? ''),
              );
              final start = fen == null ? null : GameRules.fromFen(fen);
              // As falas vêm no idioma do app (as que faltam, em inglês).
              final language = Localizations.localeOf(context).languageCode;
              return MultiBlocProvider(
                key: ValueKey(state.uri),
                providers: [
                  BlocProvider(
                    create: (context) => FreeBoardCubit(
                      now: context.read<Now>(),
                      haptics: context.read<HapticsRepository>(),
                      settings: context.read<SettingsRepository>(),
                      games: context.read<OngoingGameRepository>(),
                      opponent: context.read<OpponentRepository>(),
                      progress: context.read<ProgressRepository>(),
                      reporter: GameReporter(
                        rating: context.read<RatingRepository>(),
                        achievements: context.read<AchievementsRepository>(),
                        journey: context.read<JourneyRepository>(),
                        progress: context.read<ProgressRepository>(),
                        speedruns: context.read<SpeedrunRepository>(),
                        positions: context.read<PositionsRepository>(),
                        now: context.read<Now>(),
                      ),
                      mode: mode,
                      start: isNewGame ? start ?? GameRules.initial : null,
                      playerSide: Side.values.asNameMap()[side],
                      orientation: Side.values.asNameMap()[view],
                      clock: white == null || black == null
                          ? null
                          : ClockConfig(white: white, black: black),
                    )..open(),
                  ),
                  BlocProvider(
                    create: (context) => TalkCubit(
                      characters: context.read<CharacterRepository>(),
                      evaluation: context.read<EvaluationRepository>(),
                      talk: context.read<TalkRepository>(),
                      settings: context.read<SettingsRepository>(),
                      now: context.read<Now>(),
                      language: language,
                    ),
                  ),
                ],
                child: const FreeBoardScreen(),
              );
            },
          ),
          GoRoute(
            path: 'achievements',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  AchievementsCubit(context.read<AchievementsRepository>())
                    ..load(),
              child: const AchievementsScreen(),
            ),
          ),
          GoRoute(
            path: 'school',
            builder: (context, state) => BlocProvider(
              create: (context) => SchoolCubit(
                lessons: context.read<LessonRepository>(),
                progress: context.read<SchoolProgressRepository>(),
                characters: context.read<CharacterRepository>(),
                profile: context.read<ProfileRepository>(),
              )..load(Localizations.localeOf(context).languageCode),
              child: Builder(
                builder: (context) => ReloadOnReturn(
                  onReturn: () => context.read<SchoolCubit>().load(
                    Localizations.localeOf(context).languageCode,
                  ),
                  child: const SchoolScreen(),
                ),
              ),
            ),
            routes: [
              GoRoute(
                path: ':lesson',
                builder: (context, state) {
                  final id = state.pathParameters['lesson']!;
                  return BlocProvider(
                    // A aula seguinte (pela tela de fim) troca o view model.
                    key: ValueKey(id),
                    create: (context) => LessonCubit(
                      lessons: context.read<LessonRepository>(),
                      progress: context.read<SchoolProgressRepository>(),
                      characters: context.read<CharacterRepository>(),
                      opponent: context.read<OpponentRepository>(),
                    )..load(id, Localizations.localeOf(context).languageCode),
                    child: LessonScreen(key: ValueKey('lesson.$id')),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'journey',
            builder: (context, state) => BlocProvider(
              create: (context) => _journeyCubit(context)..load(),
              child: const JourneyScreen(),
            ),
            routes: [
              GoRoute(
                path: ':rung',
                builder: (context, state) => BlocProvider(
                  create: (context) => _journeyCubit(context)..load(),
                  child: RungScreen(rungId: state.pathParameters['rung']!),
                ),
                routes: [
                  GoRoute(
                    path: ':position',
                    builder: (context, state) => BlocProvider(
                      create: (context) => _journeyCubit(context)
                        ..load(
                          rungId: state.pathParameters['rung'],
                          positionId: state.pathParameters['position'],
                        ),
                      child: const ChallengeScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'speedruns',
            builder: (context, state) => BlocProvider(
              create: (context) => _speedrunCubit(context)..load(),
              child: Builder(
                builder: (context) => ReloadOnReturn(
                  onReturn: () => context.read<SpeedrunCubit>().load(),
                  child: const SpeedrunListScreen(),
                ),
              ),
            ),
            routes: [
              GoRoute(
                path: ':speedrun',
                builder: (context, state) => BlocProvider(
                  create: (context) =>
                      _speedrunCubit(context)
                        ..load(speedrunId: state.pathParameters['speedrun']),
                  child: Builder(
                    builder: (context) => ReloadOnReturn(
                      onReturn: () => context.read<SpeedrunCubit>().load(
                        speedrunId: state.pathParameters['speedrun'],
                      ),
                      child: const SpeedrunScreen(),
                    ),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: ':attempt',
                    builder: (context, state) => BlocProvider(
                      // A tentativa é refeita a cada visita (as etapas
                      // terminam no tabuleiro).
                      key: ValueKey(state.uri),
                      create: (context) => _speedrunCubit(context)
                        ..load(
                          speedrunId: state.pathParameters['speedrun'],
                          attemptId: int.tryParse(
                            state.pathParameters['attempt']!,
                          ),
                        ),
                      child: const SpeedrunAttemptScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'catalog',
            builder: (context, state) => BlocProvider(
              create: (context) => _catalogCubit(context)..load(),
              child: const CatalogScreen(),
            ),
            routes: [
              GoRoute(
                path: ':category',
                builder: (context, state) => BlocProvider(
                  create: (context) => _catalogCubit(context)..load(),
                  child: CategoryScreen(
                    category: state.pathParameters['category']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: ':subcategory',
                    builder: (context, state) {
                      final subcategory = state.pathParameters['subcategory']!;
                      return BlocProvider(
                        create: (context) =>
                            _catalogCubit(context)
                              ..load(subcategory: subcategory),
                        child: SubcategoryScreen(
                          category: state.pathParameters['category']!,
                          subcategory: subcategory,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'setup',
            builder: (context, state) {
              final query = state.uri.queryParameters;
              // FEN inválido aqui só viria de um link quebrado: cai na inicial.
              final position =
                  GameRules.fromFen(query['fen'] ?? '') ?? GameRules.initial;
              return BlocProvider(
                key: ValueKey(state.uri),
                create: (context) => GameSetupCubit(
                  context.read<TrainingRepository>(),
                  position: position,
                  progress: context.read<ProgressRepository>(),
                  profile: context.read<ProfileRepository>(),
                  rating: context.read<RatingRepository>(),
                  pace: context.read<PaceRepository>(),
                  characters: context.read<CharacterRepository>(),
                  goal:
                      PositionGoal.fromCode(query['goal']) ?? PositionGoal.win,
                  positionId: query['position'],
                )..load(),
                child: const GameSetupScreen(),
              );
            },
          ),
          GoRoute(
            path: 'custom',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  CustomPositionCubit(context.read<TrainingRepository>())
                    ..load(),
              child: const CustomPositionScreen(),
            ),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'language',
                builder: (context, state) => const LanguageScreen(),
              ),
              GoRoute(
                path: 'theme',
                builder: (context, state) => const ThemeScreen(),
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => BlocProvider(
                  create: (context) =>
                      RatingCubit(context.read<RatingRepository>())..load(),
                  child: const ProfileScreen(),
                ),
              ),
              GoRoute(
                path: 'board-appearance',
                builder: (context, state) => const BoardAppearanceScreen(),
              ),
              GoRoute(
                path: 'board-behavior',
                builder: (context, state) => const BoardBehaviorScreen(),
              ),
              GoRoute(
                path: 'clock',
                builder: (context, state) => const ClockSettingsScreen(),
              ),
              GoRoute(
                path: 'maia',
                // Só existe em build de desenvolvimento e de teste.
                redirect: (context, state) =>
                    showsDevTools ? null : Routes.settings,
                builder: (context, state) => BlocProvider(
                  create: (context) =>
                      MaiaDebugCubit(context.read<MaiaRepository>()),
                  child: const MaiaDebugScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

CatalogCubit _catalogCubit(BuildContext context) => CatalogCubit(
  context.read<PositionsRepository>(),
  context.read<TrainingRepository>(),
  context.read<ProgressRepository>(),
);

JourneyCubit _journeyCubit(BuildContext context) => JourneyCubit(
  context.read<JourneyRepository>(),
  context.read<ProgressRepository>(),
  onboarding: context.read<OnboardingRepository>(),
  characters: context.read<CharacterRepository>(),
);

SpeedrunCubit _speedrunCubit(BuildContext context) => SpeedrunCubit(
  journey: context.read<JourneyRepository>(),
  speedruns: context.read<SpeedrunRepository>(),
  games: context.read<OngoingGameRepository>(),
  now: context.read<Now>(),
);
