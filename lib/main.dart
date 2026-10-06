import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'config/dependencies.dart';
import 'data/repositories/rating/rating_repository.dart';
import 'data/repositories/achievements/achievements_repository.dart';
import 'data/repositories/characters/character_repository.dart';
import 'data/repositories/evaluation/evaluation_repository.dart';
import 'data/repositories/characters/talk_repository.dart';
import 'data/repositories/onboarding/onboarding_repository.dart';
import 'data/repositories/pace/pace_repository.dart';
import 'data/repositories/endgames/endgame_lesson_repository.dart';
import 'data/repositories/endgames/endgame_progress_repository.dart';
import 'data/repositories/school/lesson_repository.dart';
import 'data/repositories/school/school_progress_repository.dart';
import 'data/repositories/school/star_challenge_repository.dart';
import 'data/repositories/draw/draw_offer_repository.dart';
import 'data/repositories/haptics/haptics_repository.dart';
import 'data/repositories/sound/sound_repository.dart';
import 'data/repositories/ongoing_game/ongoing_game_repository.dart';
import 'data/repositories/journey/journey_repository.dart';
import 'data/repositories/maia/maia_repository.dart';
import 'data/repositories/speedrun/speedrun_repository.dart';
import 'data/repositories/opponent/opponent_repository.dart';
import 'data/repositories/profile/profile_repository.dart';
import 'data/repositories/positions/positions_repository.dart';
import 'data/repositories/progress/progress_repository.dart';
import 'data/repositories/settings/settings_repository.dart';
import 'data/repositories/training/training_repository.dart';
import 'domain/models/app_settings.dart';
import 'domain/use_cases/now.dart';
import 'routing/router.dart';
import 'routing/routes.dart';
import 'ui/core/sound/game_sounds.dart';
import 'ui/core/l10n/l10n.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/core/theme/app_theme_mode_ui.dart';
import 'ui/profile/view_models/profile_cubit.dart';
import 'ui/settings/view_models/settings_cubit.dart';

void main() {
  runApp(LucenaApp(dependencies: Dependencies.normal()));
}

class LucenaApp extends StatefulWidget {
  const LucenaApp({required this.dependencies, super.key});

  final Dependencies dependencies;

  @override
  State<LucenaApp> createState() => _LucenaAppState();
}

class _LucenaAppState extends State<LucenaApp> {
  // Nulo até saber em que tela o app abre.
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _openRouter();
  }

  // Partida ou aula que estava na tela quando o app foi fechado: o app
  // reabre nela.
  Future<void> _openRouter() async {
    final game = await widget.dependencies.ongoingGameRepository.load();
    final school = await widget.dependencies.schoolProgressRepository.load();
    final endgames = await widget.dependencies.endgameProgressRepository.load();
    if (!mounted) return;
    final resume = game != null && game.reopensOnLaunch;
    final lesson = school.ongoing;
    final endgameLesson = endgames.ongoing;
    final exercise = endgames.openExercise;
    setState(() {
      _router = buildRouter(
        initialLocation: resume
            ? Routes.freeBoard
            : lesson != null && lesson.open
            ? Routes.lesson(lesson.lessonId)
            : endgameLesson != null && endgameLesson.open
            ? Routes.endgameLessonSteps(endgameLesson.lessonId)
            : exercise != null
            ? Routes.endgameExercise(exercise.$1, exercise.$2.exerciseId)
            : Routes.home,
      );
    });
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    final router = _router;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Now>.value(value: dependencies.now),
        RepositoryProvider<SettingsRepository>.value(
          value: dependencies.settingsRepository,
        ),
        RepositoryProvider<HapticsRepository>.value(
          value: dependencies.hapticsRepository,
        ),
        RepositoryProvider<SoundRepository>.value(
          value: dependencies.soundRepository,
        ),
        // Os sons do jogo, já com a preferência de ligado ou desligado.
        RepositoryProvider<GameSounds>(
          create: (context) => GameSounds(
            dependencies.settingsRepository,
            dependencies.soundRepository,
          ),
        ),
        RepositoryProvider<OngoingGameRepository>.value(
          value: dependencies.ongoingGameRepository,
        ),
        RepositoryProvider<PositionsRepository>.value(
          value: dependencies.positionsRepository,
        ),
        RepositoryProvider<TrainingRepository>.value(
          value: dependencies.trainingRepository,
        ),
        RepositoryProvider<OpponentRepository>.value(
          value: dependencies.opponentRepository,
        ),
        RepositoryProvider<ProgressRepository>.value(
          value: dependencies.progressRepository,
        ),
        RepositoryProvider<JourneyRepository>.value(
          value: dependencies.journeyRepository,
        ),
        RepositoryProvider<SpeedrunRepository>.value(
          value: dependencies.speedrunRepository,
        ),
        RepositoryProvider<MaiaRepository>.value(
          value: dependencies.maiaRepository,
        ),
        RepositoryProvider<ProfileRepository>.value(
          value: dependencies.profileRepository,
        ),
        RepositoryProvider<RatingRepository>.value(
          value: dependencies.ratingRepository,
        ),
        RepositoryProvider<AchievementsRepository>.value(
          value: dependencies.achievementsRepository,
        ),
        RepositoryProvider<CharacterRepository>.value(
          value: dependencies.characterRepository,
        ),
        RepositoryProvider<EvaluationRepository>.value(
          value: dependencies.evaluationRepository,
        ),
        RepositoryProvider<TalkRepository>.value(
          value: dependencies.talkRepository,
        ),
        RepositoryProvider<OnboardingRepository>.value(
          value: dependencies.onboardingRepository,
        ),
        RepositoryProvider<PaceRepository>.value(
          value: dependencies.paceRepository,
        ),
        RepositoryProvider<LessonRepository>.value(
          value: dependencies.lessonRepository,
        ),
        RepositoryProvider<SchoolProgressRepository>.value(
          value: dependencies.schoolProgressRepository,
        ),
        RepositoryProvider<StarChallengeRepository>.value(
          value: dependencies.starChallengeRepository,
        ),
        RepositoryProvider<EndgameLessonRepository>.value(
          value: dependencies.endgameLessonRepository,
        ),
        RepositoryProvider<EndgameProgressRepository>.value(
          value: dependencies.endgameProgressRepository,
        ),
        RepositoryProvider<DrawOfferRepository>.value(
          value: dependencies.drawOfferRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SettingsCubit(
              dependencies.settingsRepository,
              languages: dependencies.languages,
              sound: dependencies.soundRepository,
            )..load(),
          ),
          BlocProvider(
            create: (context) =>
                ProfileCubit(dependencies.profileRepository)..load(),
          ),
        ],
        child: BlocBuilder<SettingsCubit, AppSettings?>(
          builder: (context, settings) {
            // Até as preferências chegarem, só o fundo: o app nunca aparece
            // no idioma errado nem na tela errada.
            if (settings == null || router == null) {
              return const _LaunchBackground();
            }
            return MaterialApp.router(
              onGenerateTitle: (context) => context.l10n.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.of(Brightness.light, accent: settings.accent),
              darkTheme: AppTheme.of(Brightness.dark, accent: settings.accent),
              themeMode: settings.themeMode.material,
              locale: localeFromCode(settings.languageCode),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: appSupportedLocales,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}

/// O mesmo fundo da abertura nativa e da tela inicial.
class _LaunchBackground extends StatelessWidget {
  const _LaunchBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final theme = isDark ? AppTheme.dark : AppTheme.light;
    return ColoredBox(color: theme.scaffoldBackgroundColor);
  }
}
