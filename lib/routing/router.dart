import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/conclusion/conclusion_repository.dart';
import '../data/repositories/blind/blind_log_repository.dart';
import '../data/repositories/blind/speech_input_repository.dart';
import '../ui/conclusion/view_models/conclusion_cubit.dart';
import '../ui/conclusion/widgets/conclusion_screen.dart';
import '../domain/models/conclusion.dart';
import '../ui/blind/view_models/blind_game_cubit.dart';
import '../ui/blind/widgets/blind_game_screen.dart';
import '../ui/core/l10n/l10n.dart';
import '../data/repositories/voice/voice_repository.dart';
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
import '../ui/voice/widgets/voice_settings_screen.dart';
import '../data/repositories/home/home_layout_repository.dart';
import '../data/repositories/home/unlock_repository.dart';
import '../data/repositories/journey/journey_repository.dart';
import '../data/repositories/maia/maia_repository.dart';
import '../data/repositories/speedrun/speedrun_repository.dart';
import '../data/repositories/opponent/opponent_repository.dart';
import '../data/repositories/placement/placement_repository.dart';
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
import '../data/repositories/draw/draw_offer_repository.dart';
import '../ui/game_details/view_models/game_details_cubit.dart';
import '../ui/game_details/widgets/game_details_screen.dart';
import '../ui/all_modes/widgets/all_modes_screen.dart';
import '../ui/home/view_models/home_cubit.dart';
import '../ui/home_layout/view_models/home_layout_cubit.dart';
import '../ui/home_layout/widgets/home_layout_screen.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/achievements/view_models/achievement_facts_loader.dart';
import '../ui/achievements/view_models/achievements_cubit.dart';
import '../ui/achievements/widgets/achievements_screen.dart';
import '../data/repositories/endgames/endgame_lesson_repository.dart';
import '../data/repositories/endgames/endgame_progress_repository.dart';
import '../data/repositories/school/lesson_repository.dart';
import '../data/repositories/school/lesson_source.dart';
import '../ui/endgames/view_models/endgame_lesson_cubit.dart';
import '../ui/endgames/view_models/endgames_cubit.dart';
import '../ui/endgames/view_models/exercise_cubit.dart';
import '../ui/endgames/widgets/endgame_info_screen.dart';
import '../ui/endgames/widgets/endgame_lesson_screen.dart';
import '../ui/endgames/widgets/endgames_screen.dart';
import '../ui/endgames/widgets/exercise_screen.dart';
import '../data/repositories/school/school_progress_repository.dart';
import '../data/repositories/school/star_challenge_repository.dart';
import '../domain/models/star_challenge.dart';
import '../ui/school/view_models/star_challenge_cubit.dart';
import '../ui/school/widgets/star_challenge_screen.dart';
import '../ui/school/widgets/star_challenges_screen.dart';
import '../ui/school/view_models/lesson_cubit.dart';
import '../ui/school/view_models/school_cubit.dart';
import '../ui/school/widgets/lesson_screen.dart';
import '../ui/school/widgets/school_screen.dart';
import '../ui/placement/view_models/placement_cubit.dart';
import '../ui/placement/widgets/placement_screen.dart';
import '../ui/tour/view_models/tour_cubit.dart';
import '../ui/tour/widgets/tour_screen.dart';
import '../data/repositories/onboarding/onboarding_repository.dart';
import '../data/repositories/analysis/analysis_repository.dart';
import '../data/repositories/review/game_review_repository.dart';
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
import '../ui/profile/widgets/rating_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/settings/widgets/language_screen.dart';
import '../ui/settings/widgets/about_screen.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/settings/widgets/settings_tiles.dart';
import '../ui/settings/widgets/theme_screen.dart';
import '../ui/core/widgets/reload_on_return.dart';
import '../ui/core/sound/game_haptics.dart';
import '../ui/core/sound/game_sounds.dart';
import 'routes.dart';
import '../domain/use_cases/game_intro.dart';

/// [initialLocation] é a tela em que o app abre; as telas de baixo dela na
/// árvore de rotas entram junto, para o botão de voltar funcionar.
GoRouter buildRouter({String initialLocation = Routes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      _route(
        path: Routes.tour,
        builder: (context, state) => BlocProvider(
          create: (_) => TourCubit(
            onboarding: context.read<OnboardingRepository>(),
            profile: context.read<ProfileRepository>(),
            characters: context.read<CharacterRepository>(),
            lessons: context.read<LessonRepository>(),
            voice: context.read<VoiceRepository>(),
            home: context.read<HomeLayoutRepository>(),
          )..load(_language(context)),
          child: const TourScreen(),
        ),
      ),
      _route(
        path: Routes.placement,
        builder: (context, state) {
          final fromTour = state.uri.queryParameters['from'] == 'tour';
          return BlocProvider(
            create: (_) => PlacementCubit(
              placement: context.read<PlacementRepository>(),
              profile: context.read<ProfileRepository>(),
              now: context.read<Now>(),
              onboarding: context.read<OnboardingRepository>(),
              characters: context.read<CharacterRepository>(),
              school: context.read<LessonRepository>(),
              schoolProgress: context.read<SchoolProgressRepository>(),
              endgames: context.read<EndgameLessonRepository>(),
              endgameProgress: context.read<EndgameProgressRepository>(),
              language: _language(context),
              // Nos testes de ponta a ponta, sempre as mesmas perguntas.
              seed: isE2E ? 52 : null,
            )..load(),
            // Volta com true quando o resultado foi usado.
            child: Builder(
              builder: (context) => PlacementScreen(
                onDone: () => context.pop(true),
                onChooseByHand: fromTour ? () => context.pop(false) : null,
              ),
            ),
          );
        },
      ),
      _route(
        path: Routes.home,
        builder: (context, state) => BlocProvider(
          create: (_) => HomeCubit(
            journey: context.read<JourneyRepository>(),
            progress: context.read<ProgressRepository>(),
            onboarding: context.read<OnboardingRepository>(),
            characters: context.read<CharacterRepository>(),
            rating: context.read<RatingRepository>(),
            lessons: context.read<LessonRepository>(),
            school: context.read<SchoolProgressRepository>(),
            profile: context.read<ProfileRepository>(),
            endgameLessons: context.read<EndgameLessonRepository>(),
            endgameProgress: context.read<EndgameProgressRepository>(),
            homeLayout: context.read<HomeLayoutRepository>(),
            unlocks: context.read<UnlockRepository>(),
          )..load(_language(context)),
          child: Builder(
            builder: (context) => ReloadOnReturn(
              onReturn: () =>
                  context.read<HomeCubit>().load(_language(context)),
              child: const HomeScreen(),
            ),
          ),
        ),
        routes: [
          _route(
            path: 'blind',
            builder: (context, state) {
              final query = state.uri.queryParameters;
              return BlocProvider(
                create: (_) =>
                    BlindGameCubit(
                      opponent: context.read<OpponentRepository>(),
                      voice: context.read<VoiceRepository>(),
                      input: context.read<SpeechInputRepository>(),
                      log: context.read<BlindLogRepository>(),
                      now: context.read<Now>(),
                      draws: context.read<DrawOfferRepository>(),
                      progress: context.read<ProgressRepository>(),
                    )..load(
                      view: BlindView.values.asNameMap()[query['view']],
                      challengeId: query['challenge'],
                      positionId: query['position'],
                      goal:
                          PositionGoal.fromCode(query['goal']) ??
                          PositionGoal.win,
                      fen: query['fen'] ?? GameRules.initial.fen,
                      userSide:
                          Side.values.asNameMap()[query['user']] ?? Side.white,
                      kind: OpponentKind.fromCode(query['opponent']),
                      level: int.tryParse(query['level'] ?? ''),
                      language: Localizations.localeOf(context).toLanguageTag(),
                      phrases: blindPhrases(context.l10n),
                      clock: _blindClock(query),
                    ),
                child: const BlindGameScreen(),
              );
            },
          ),
          _route(
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
                      sounds: context.read<GameSounds>(),
                      haptics: context.read<HapticsRepository>(),
                      now: context.read<Now>(),
                      settings: context.read<SettingsRepository>(),
                      games: context.read<OngoingGameRepository>(),
                      opponent: context.read<OpponentRepository>(),
                      progress: context.read<ProgressRepository>(),
                      draws: context.read<DrawOfferRepository>(),
                      speedruns: context.read<SpeedrunRepository>(),
                      reporter: GameReporter(
                        rating: context.read<RatingRepository>(),
                        achievements: context.read<AchievementsRepository>(),
                        journey: context.read<JourneyRepository>(),
                        progress: context.read<ProgressRepository>(),
                        speedruns: context.read<SpeedrunRepository>(),
                        positions: context.read<PositionsRepository>(),
                        now: context.read<Now>(),
                        onboarding: context.read<OnboardingRepository>(),
                        characters: context.read<CharacterRepository>(),
                      ),
                      mode: mode,
                      // Partida nova contra a máquina: o relógio espera o
                      // versus sair (T51, A2).
                      hold: GameIntroRule.of(mode) != GameIntro.none,
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
                      school: context.read<SchoolProgressRepository>(),
                    ),
                  ),
                ],
                child: const FreeBoardScreen(),
              );
            },
          ),
          _route(
            path: 'result',
            builder: (context, state) {
              final args = state.extra;
              final language = Localizations.localeOf(context).languageCode;
              return BlocProvider(
                key: ValueKey(state.uri),
                create: (context) {
                  final cubit = _conclusionCubit(context);
                  if (args is ConclusionArgs) {
                    cubit.show(
                      args.conclusion,
                      opponent: args.opponent,
                      replay: args.replay,
                      setup: args.setup,
                      language: language,
                    );
                  } else {
                    cubit.show(
                      const Conclusion(
                        kind: ConclusionKind.game,
                        result: ConclusionResult.draw,
                        actions: [],
                      ),
                    );
                  }
                  return cubit;
                },
                child: const ConclusionScreen(),
              );
            },
          ),
          _route(
            path: 'result/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              final language = Localizations.localeOf(context).languageCode;
              return BlocProvider(
                key: ValueKey(state.uri),
                create: (context) =>
                    _conclusionCubit(context)..load(id ?? -1, language),
                child: ConclusionScreen(
                  fresh: state.uri.queryParameters['fresh'] == '1',
                ),
              );
            },
          ),
          _route(
            path: 'modes',
            builder: (context, state) => const AllModesScreen(),
          ),
          _route(
            path: 'achievements',
            builder: (context, state) => BlocProvider(
              create: (context) => AchievementsCubit(
                context.read<AchievementsRepository>(),
                now: context.read<Now>(),
                characters: context.read<CharacterRepository>(),
                facts: AchievementFactsLoader(
                  journey: context.read<JourneyRepository>(),
                  progress: context.read<ProgressRepository>(),
                  speedruns: context.read<SpeedrunRepository>(),
                  positions: context.read<PositionsRepository>(),
                ),
                speedruns: context.read<SpeedrunRepository>(),
              )..load(),
              child: const AchievementsScreen(),
            ),
          ),
          _route(
            path: 'school',
            builder: (context, state) => BlocProvider(
              create: (_) => SchoolCubit(
                lessons: context.read<LessonRepository>(),
                progress: context.read<SchoolProgressRepository>(),
                characters: context.read<CharacterRepository>(),
                profile: context.read<ProfileRepository>(),
                placement: context.read<PlacementRepository>(),
                endgames: context.read<EndgameLessonRepository>(),
                endgameProgress: context.read<EndgameProgressRepository>(),
              )..load(_language(context)),
              child: Builder(
                builder: (context) => ReloadOnReturn(
                  onReturn: () =>
                      context.read<SchoolCubit>().load(_language(context)),
                  child: const SchoolScreen(),
                ),
              ),
            ),
            routes: [
              // Antes de ':lesson', para 'challenges' não virar id de aula.
              _route(
                path: 'challenges',
                builder: (context, state) => BlocProvider(
                  create: (_) => StarChallengesCubit(
                    progress: context.read<StarChallengeRepository>(),
                  )..load(),
                  child: Builder(
                    builder: (context) => ReloadOnReturn(
                      onReturn: () =>
                          context.read<StarChallengesCubit>().load(),
                      child: const StarChallengesScreen(),
                    ),
                  ),
                ),
                routes: [
                  _route(
                    path: ':piece/:level',
                    builder: (context, state) {
                      final piece = state.pathParameters['piece']!;
                      final level = state.pathParameters['level']!;
                      return BlocProvider(
                        key: ValueKey('starChallenge.$piece.$level'),
                        create: (_) {
                          final cubit = StarChallengeCubit(
                            sounds: context.read<GameSounds>(),
                            haptics: context.read<GameHaptics>(),
                            progress: context.read<StarChallengeRepository>(),
                            now: context.read<Now>(),
                          );
                          final which = ChallengePiece.byName(piece);
                          final how = ChallengeLevel.byName(level);
                          if (which != null && how != null) {
                            cubit.load(which, how);
                          }
                          return cubit;
                        },
                        child: const StarChallengeScreen(),
                      );
                    },
                  ),
                ],
              ),
              _route(
                path: ':lesson',
                builder: (context, state) {
                  final id = state.pathParameters['lesson']!;
                  return BlocProvider(
                    // A aula seguinte (pela tela de fim) troca o view model.
                    key: ValueKey(id),
                    create: (_) => LessonCubit(
                      now: context.read<Now>(),
                      settings: context.read<SettingsRepository>(),
                      sounds: context.read<GameSounds>(),
                      haptics: context.read<GameHaptics>(),
                      lessons: context.read<LessonRepository>(),
                      progress: context.read<SchoolProgressRepository>(),
                      characters: context.read<CharacterRepository>(),
                      opponent: context.read<OpponentRepository>(),
                    )..load(id, _language(context)),
                    child: LessonScreen(key: ValueKey('lesson.$id')),
                  );
                },
              ),
            ],
          ),
          _route(
            path: 'endgames',
            builder: (context, state) => BlocProvider(
              create: (_) => EndgamesCubit(
                lessons: context.read<EndgameLessonRepository>(),
                progress: context.read<EndgameProgressRepository>(),
                characters: context.read<CharacterRepository>(),
                placement: context.read<PlacementRepository>(),
                school: context.read<LessonRepository>(),
                schoolProgress: context.read<SchoolProgressRepository>(),
                settings: context.read<SettingsRepository>(),
              )..load(_language(context)),
              child: Builder(
                builder: (context) => ReloadOnReturn(
                  onReturn: () =>
                      context.read<EndgamesCubit>().load(_language(context)),
                  child: const EndgamesScreen(),
                ),
              ),
            ),
            routes: [
              // Antes de ':lesson', para 'challenges' não virar id de aula.
              _route(
                path: 'challenges',
                builder: (context, state) => BlocProvider(
                  create: (_) => StarChallengesCubit(
                    progress: context.read<StarChallengeRepository>(),
                  )..load(),
                  child: Builder(
                    builder: (context) => ReloadOnReturn(
                      onReturn: () =>
                          context.read<StarChallengesCubit>().load(),
                      child: const StarChallengesScreen(),
                    ),
                  ),
                ),
                routes: [
                  _route(
                    path: ':piece/:level',
                    builder: (context, state) {
                      final piece = state.pathParameters['piece']!;
                      final level = state.pathParameters['level']!;
                      return BlocProvider(
                        key: ValueKey('starChallenge.$piece.$level'),
                        create: (_) {
                          final cubit = StarChallengeCubit(
                            sounds: context.read<GameSounds>(),
                            haptics: context.read<GameHaptics>(),
                            progress: context.read<StarChallengeRepository>(),
                            now: context.read<Now>(),
                          );
                          final which = ChallengePiece.byName(piece);
                          final how = ChallengeLevel.byName(level);
                          if (which != null && how != null) {
                            cubit.load(which, how);
                          }
                          return cubit;
                        },
                        child: const StarChallengeScreen(),
                      );
                    },
                  ),
                ],
              ),
              _route(
                path: ':lesson',
                builder: (context, state) {
                  final id = state.pathParameters['lesson']!;
                  return BlocProvider(
                    key: ValueKey(id),
                    create: (_) => EndgameLessonCubit(
                      lessons: context.read<EndgameLessonRepository>(),
                      progress: context.read<EndgameProgressRepository>(),
                      journey: context.read<JourneyRepository>(),
                      characters: context.read<CharacterRepository>(),
                    )..load(id, _language(context)),
                    child: Builder(
                      builder: (context) => ReloadOnReturn(
                        onReturn: () => context.read<EndgameLessonCubit>().load(
                          id,
                          _language(context),
                        ),
                        child: EndgameLessonScreen(
                          key: ValueKey('endgameLesson.$id'),
                        ),
                      ),
                    ),
                  );
                },
                routes: [
                  // A lição: a mesma tela das aulas da escola.
                  _route(
                    path: 'lesson',
                    builder: (context, state) {
                      final id = state.pathParameters['lesson']!;
                      final part = state.uri.queryParameters['part'];
                      return BlocProvider(
                        key: ValueKey('steps.$id.$part'),
                        create: (_) => LessonCubit(
                          now: context.read<Now>(),
                          settings: context.read<SettingsRepository>(),
                          sounds: context.read<GameSounds>(),
                          haptics: context.read<GameHaptics>(),
                          source: EndgameLessonSource(
                            context.read<EndgameLessonRepository>(),
                            context.read<EndgameProgressRepository>(),
                          ),
                          characters: context.read<CharacterRepository>(),
                          opponent: context.read<OpponentRepository>(),
                        )..load(id, _language(context), part: part),
                        child: LessonScreen(key: ValueKey('lesson.$id.$part')),
                      );
                    },
                  ),
                  _route(
                    path: 'info',
                    builder: (context, state) {
                      final id = state.pathParameters['lesson']!;
                      return BlocProvider(
                        create: (_) => EndgameLessonCubit(
                          lessons: context.read<EndgameLessonRepository>(),
                          progress: context.read<EndgameProgressRepository>(),
                          journey: context.read<JourneyRepository>(),
                          characters: context.read<CharacterRepository>(),
                        )..load(id, _language(context)),
                        child: const EndgameInfoScreen(),
                      );
                    },
                  ),
                  _route(
                    path: 'ex/:exercise',
                    builder: (context, state) {
                      final id = state.pathParameters['lesson']!;
                      final exercise = state.pathParameters['exercise']!;
                      return BlocProvider(
                        // O exercício seguinte troca o view model.
                        key: ValueKey('$id.$exercise'),
                        create: (_) => ExerciseCubit(
                          sounds: context.read<GameSounds>(),
                          haptics: context.read<GameHaptics>(),
                          lessons: context.read<EndgameLessonRepository>(),
                          progress: context.read<EndgameProgressRepository>(),
                          characters: context.read<CharacterRepository>(),
                        )..load(id, exercise, _language(context)),
                        child: ExerciseScreen(
                          key: ValueKey('exercise.$id.$exercise'),
                          lessonId: id,
                          exerciseId: exercise,
                          // A lista manda a posição, para a miniatura voar.
                          previewFen: state.extra as String?,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          _route(
            path: 'journey',
            builder: (context, state) => BlocProvider(
              create: (_) => _journeyCubit(context)..load(),
              child: const JourneyScreen(),
            ),
            routes: [
              _route(
                path: ':rung',
                builder: (context, state) => BlocProvider(
                  create: (_) =>
                      _journeyCubit(context, initial: state.extra)..load(),
                  // A partida termina na conclusão (T51): fechar a conclusão
                  // volta aqui com o desafio já gravado.
                  child: Builder(
                    builder: (context) => ReloadOnReturn(
                      onReturn: () => context.read<JourneyCubit>().load(),
                      child: RungScreen(rungId: state.pathParameters['rung']!),
                    ),
                  ),
                ),
                routes: [
                  _route(
                    path: ':position',
                    builder: (context, state) => BlocProvider(
                      create: (_) =>
                          _journeyCubit(context, initial: state.extra)..load(
                            rungId: state.pathParameters['rung'],
                            positionId: state.pathParameters['position'],
                          ),
                      child: Builder(
                        builder: (context) => ReloadOnReturn(
                          onReturn: () => context.read<JourneyCubit>().load(
                            rungId: state.pathParameters['rung'],
                            positionId: state.pathParameters['position'],
                          ),
                          child: ChallengeScreen(
                            rungId: state.pathParameters['rung']!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _route(
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
              _route(
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
                  _route(
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
          _route(
            path: 'catalog',
            builder: (context, state) => BlocProvider(
              create: (context) => _catalogCubit(context)..load(),
              child: const CatalogScreen(),
            ),
            routes: [
              _route(
                path: ':category',
                builder: (context, state) {
                  final category = state.pathParameters['category']!;
                  return BlocProvider(
                    create: (context) =>
                        _catalogCubit(context)..load(category: category),
                    child: CategoryScreen(category: category),
                  );
                },
              ),
            ],
          ),
          _route(
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
          _route(
            path: 'custom',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  CustomPositionCubit(context.read<TrainingRepository>())
                    ..load(),
              child: const CustomPositionScreen(),
            ),
          ),
          _route(
            path: 'rating',
            builder: (context, state) => BlocProvider(
              create: (context) => RatingCubit(
                context.read<RatingRepository>(),
                progress: context.read<ProgressRepository>(),
                achievements: context.read<AchievementsRepository>(),
                speedruns: context.read<SpeedrunRepository>(),
                journey: context.read<JourneyRepository>(),
                characters: context.read<CharacterRepository>(),
                reviews: context.read<GameReviewRepository>(),
                now: context.read<Now>(),
                // Vindo da conclusão: a partida em destaque.
                highlightedGame: int.tryParse(
                  state.uri.queryParameters['game'] ?? '',
                ),
              )..load(),
              child: const RatingScreen(),
            ),
            routes: [
              _route(
                path: 'game/:id',
                // O idioma é lido aqui: dentro do `create` o provider não
                // pode depender do Localizations.
                builder: (context, state) {
                  final language = _language(context);
                  return BlocProvider(
                    create: (_) => GameDetailsCubit(
                      int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                      progress: context.read<ProgressRepository>(),
                      rating: context.read<RatingRepository>(),
                      characters: context.read<CharacterRepository>(),
                      analysis: context.read<AnalysisRepository>(),
                      reviews: context.read<GameReviewRepository>(),
                      lessons: context.read<LessonRepository>(),
                    )..load(language: language),
                    child: const GameDetailsScreen(),
                  );
                },
              ),
            ],
          ),
          _route(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              _route(
                path: 'profile',
                builder: (context, state) => BlocProvider(
                  create: (context) =>
                      RatingCubit(context.read<RatingRepository>())..load(),
                  child: const ProfileScreen(),
                ),
              ),
              _route(
                path: 'appearance',
                builder: (context, state) => const AppearanceSettingsScreen(),
                routes: [
                  _route(
                    path: 'language',
                    builder: (context, state) => const LanguageScreen(),
                  ),
                  _route(
                    path: 'theme',
                    builder: (context, state) => const ThemeScreen(),
                  ),
                  _route(
                    path: 'board',
                    builder: (context, state) => const BoardAppearanceScreen(),
                  ),
                  _route(
                    path: 'home',
                    builder: (context, state) => BlocProvider(
                      create: (context) => HomeLayoutCubit(
                        layouts: context.read<HomeLayoutRepository>(),
                        profile: context.read<ProfileRepository>(),
                      )..load(),
                      child: const HomeLayoutScreen(),
                    ),
                  ),
                ],
              ),
              _route(
                path: 'game',
                builder: (context, state) => const GameSettingsScreen(),
                routes: [
                  _route(
                    path: 'board',
                    builder: (context, state) => const BoardBehaviorScreen(),
                  ),
                  _route(
                    path: 'clock',
                    builder: (context, state) => const ClockSettingsScreen(),
                  ),
                ],
              ),
              _route(
                path: 'sound',
                builder: (context, state) => const SoundSettingsScreen(),
                routes: [
                  _route(
                    path: 'voice',
                    builder: (context, state) => const VoiceSettingsScreen(),
                  ),
                ],
              ),
              _route(
                path: 'about',
                builder: (context, state) => const AboutScreen(),
              ),
              _route(
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

/// [initial]: o que a tela de antes já leu (vem no `extra` da rota). A tela
/// abre pronta, e o retrato e o tabuleiro voam até ela.
JourneyCubit _journeyCubit(BuildContext context, {Object? initial}) =>
    JourneyCubit(
      context.read<JourneyRepository>(),
      context.read<ProgressRepository>(),
      initial: initial is JourneyState ? initial : null,
      onboarding: context.read<OnboardingRepository>(),
      characters: context.read<CharacterRepository>(),
      school: context.read<SchoolProgressRepository>(),
      lessons: context.read<LessonRepository>(),
      speedruns: context.read<SpeedrunRepository>(),
      language: _language(context),
    );

/// O idioma do app, lido no `builder` da rota (no `create` de um provider não
/// se pode ouvir o `Localizations`).
/// O relógio da partida às cegas (`?white=` e `?black=`). Nulo sem eles.
ClockConfig? _blindClock(Map<String, String> query) {
  final white = TimeControl.tryParse(query['white']);
  final black = TimeControl.tryParse(query['black']);
  if (white == null || black == null) return null;
  return ClockConfig(white: white, black: black);
}

String _language(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

SpeedrunCubit _speedrunCubit(BuildContext context) => SpeedrunCubit(
  journey: context.read<JourneyRepository>(),
  speedruns: context.read<SpeedrunRepository>(),
  games: context.read<OngoingGameRepository>(),
  now: context.read<Now>(),
  settings: context.read<SettingsRepository>(),
  characters: context.read<CharacterRepository>(),
  profile: context.read<ProfileRepository>(),
);

/// Uma rota com página Material (com a transição do tema). O go_router 18
/// procura o `MaterialApp` do pacote `material_ui` e não reconhece o do
/// Flutter: sem isto, as páginas ficariam sem transição nenhuma.
GoRoute _route({
  required String path,
  required GoRouterWidgetBuilder builder,
  GoRouterRedirect? redirect,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  redirect: redirect,
  pageBuilder: (context, state) =>
      MaterialPage<void>(key: state.pageKey, child: builder(context, state)),
  routes: routes,
);

ConclusionCubit _conclusionCubit(BuildContext context) => ConclusionCubit(
  progress: context.read<ProgressRepository>(),
  rating: context.read<RatingRepository>(),
  achievements: context.read<AchievementsRepository>(),
  journey: context.read<JourneyRepository>(),
  speedruns: context.read<SpeedrunRepository>(),
  positions: context.read<PositionsRepository>(),
  characters: context.read<CharacterRepository>(),
  now: context.read<Now>(),
  onboarding: context.read<OnboardingRepository>(),
  pending: context.read<ConclusionRepository>(),
  analysis: context.read<AnalysisRepository>(),
  reviews: context.read<GameReviewRepository>(),
);
