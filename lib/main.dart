import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'config/dependencies.dart';
import 'domain/models/challenge_link.dart';
import 'routing/routes.dart';
import 'routing/launch_location.dart';
import 'domain/use_cases/visible_lessons.dart';
import 'data/repositories/blind/blind_checkpoint_repository.dart';
import 'data/repositories/survey/survey_repository.dart';
import 'data/repositories/rating/rating_repository.dart';
import 'data/repositories/achievements/achievements_repository.dart';
import 'data/repositories/characters/character_repository.dart';
import 'data/repositories/evaluation/evaluation_repository.dart';
import 'data/repositories/characters/talk_repository.dart';
import 'data/repositories/home/home_layout_repository.dart';
import 'data/repositories/featured/featured_alerts_repository.dart';
import 'data/repositories/featured/featured_progress_repository.dart';
import 'data/repositories/featured/featured_repository.dart';
import 'data/repositories/home/unlock_repository.dart';
import 'data/repositories/onboarding/onboarding_repository.dart';
import 'data/repositories/pace/pace_repository.dart';
import 'data/repositories/endgames/endgame_lesson_repository.dart';
import 'data/repositories/endgames/exercise_feedback_repository.dart';
import 'data/repositories/endgames/endgame_progress_repository.dart';
import 'data/repositories/school/lesson_repository.dart';
import 'data/repositories/school/lesson_script_repository.dart';
import 'data/repositories/tablebase/kpk_repository.dart';
import 'data/repositories/tablebase/script_table_repository.dart';
import 'domain/use_cases/position_judge.dart';
import 'data/repositories/school/school_progress_repository.dart';
import 'data/repositories/school/star_challenge_repository.dart';
import 'data/repositories/draw/draw_offer_repository.dart';
import 'data/repositories/haptics/haptics_repository.dart';
import 'data/repositories/account/account_repository.dart';
import 'data/repositories/deep_link/deep_link_repository.dart';
import 'data/repositories/push/push_repository.dart';
import 'data/services/firebase/firebase_bootstrap.dart';
import 'data/repositories/share/share_repository.dart';
import 'data/repositories/placement/placement_repository.dart';
import 'data/repositories/conclusion/conclusion_repository.dart';
import 'data/repositories/analysis/analysis_repository.dart';
import 'data/repositories/review/game_review_repository.dart';
import 'data/repositories/sound/sound_repository.dart';
import 'data/repositories/ongoing_game/ongoing_game_repository.dart';
import 'data/repositories/journey/journey_repository.dart';
import 'data/repositories/maia/maia_repository.dart';
import 'data/repositories/race/race_repository.dart';
import 'data/repositories/speedrun/speedrun_repository.dart';
import 'data/repositories/opponent/opponent_repository.dart';
import 'data/repositories/profile/profile_repository.dart';
import 'data/repositories/positions/positions_repository.dart';
import 'data/repositories/progress/progress_repository.dart';
import 'data/repositories/settings/settings_repository.dart';
import 'data/repositories/training/training_repository.dart';
import 'data/repositories/voice/voice_repository.dart';
import 'data/repositories/blind/blind_log_repository.dart';
import 'data/repositories/blind/speech_input_repository.dart';
import 'domain/models/app_settings.dart';
import 'domain/models/app_version.dart';
import 'domain/use_cases/now.dart';
import 'routing/router.dart';
import 'ui/core/sound/game_haptics.dart';
import 'ui/core/sound/game_sounds.dart';
import 'ui/core/l10n/l10n.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/core/theme/app_theme_mode_ui.dart';
import 'ui/profile/view_models/profile_cubit.dart';
import 'ui/settings/view_models/settings_cubit.dart';
import 'ui/voice/view_models/speech_cubit.dart';
import 'ui/wiki/view_models/wiki_links_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final version = await Dependencies.installedVersion();
  final firebase = await startFirebase();
  runApp(
    LucenaApp(
      dependencies: Dependencies.normal(version: version, firebase: firebase),
    ),
  );
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

  // Os desafios que chegam por link com o app aberto.
  StreamSubscription<ChallengeLink>? _links;

  // Os avisos de push tocados com o app em segundo plano.
  StreamSubscription<Uri>? _pushLinks;

  @override
  void initState() {
    super.initState();
    _openRouter();
  }

  // Partida ou aula que estava na tela quando o app foi fechado: o app
  // reabre nela.
  Future<void> _openRouter() async {
    final game = await widget.dependencies.ongoingGameRepository.load();
    final conclusion = await widget.dependencies.conclusionRepository.pending();
    final school = await widget.dependencies.schoolProgressRepository.load();
    final endgames = await widget.dependencies.endgameProgressRepository.load();
    final stars = await widget.dependencies.starChallengeRepository.open();
    final deepLinks = widget.dependencies.deepLinkRepository;
    final push = widget.dependencies.pushRepository;
    unawaited(push.start());
    final pushed = await push.initialLink();
    final link =
        await deepLinks.initial() ??
        (pushed == null ? null : deepLinks.parse(pushed));
    if (!mounted) return;
    setState(() {
      _router = buildRouter(
        initialLocation: launchLocation(
          conclusion: conclusion,
          resumeGame: game != null && game.reopensOnLaunch,
          school: school,
          endgames: endgames,
          stars: stars,
          link: link,
          showSchool: VisibleLessons.school,
          visibleEndgameLessons: VisibleLessons.endgameLessonIds,
        ),
      );
    });
    _links = deepLinks.opened.listen(
      (link) => _router?.push(Routes.challenge(link)),
    );
    // Um aviso pode trazer o link de um desafio ou final.
    _pushLinks = push.openedLinks.listen((uri) {
      final link = deepLinks.parse(uri);
      if (link != null) _router?.push(Routes.challenge(link));
    });
  }

  @override
  void dispose() {
    unawaited(_links?.cancel());
    unawaited(_pushLinks?.cancel());
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
        RepositoryProvider<PlacementRepository>.value(
          value: dependencies.placementRepository,
        ),
        RepositoryProvider<ShareRepository>.value(
          value: dependencies.shareRepository,
        ),
        RepositoryProvider<DeepLinkRepository>.value(
          value: dependencies.deepLinkRepository,
        ),
        RepositoryProvider<AccountRepository>.value(
          value: dependencies.accountRepository,
        ),
        RepositoryProvider<PushRepository>.value(
          value: dependencies.pushRepository,
        ),
        RepositoryProvider<HapticsRepository>.value(
          value: dependencies.hapticsRepository,
        ),
        RepositoryProvider<SoundRepository>.value(
          value: dependencies.soundRepository,
        ),
        RepositoryProvider<AnalysisRepository>.value(
          value: dependencies.analysisRepository,
        ),
        RepositoryProvider<GameReviewRepository>.value(
          value: dependencies.gameReviewRepository,
        ),
        // A vibração, já com a preferência de ligada ou desligada.
        RepositoryProvider<GameHaptics>(
          create: (context) => GameHaptics(
            dependencies.settingsRepository,
            dependencies.hapticsRepository,
          ),
        ),
        // Os sons do jogo, já com a preferência de ligado ou desligado.
        RepositoryProvider<GameSounds>(
          create: (context) => GameSounds(
            dependencies.settingsRepository,
            dependencies.soundRepository,
          ),
        ),
        RepositoryProvider<ConclusionRepository>.value(
          value: dependencies.conclusionRepository,
        ),
        RepositoryProvider<AppVersion>.value(value: dependencies.version),
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
        RepositoryProvider<RaceRepository>.value(
          value: dependencies.raceRepository,
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
        RepositoryProvider<HomeLayoutRepository>.value(
          value: dependencies.homeLayoutRepository,
        ),
        RepositoryProvider<FeaturedRepository>.value(
          value: dependencies.featuredRepository,
        ),
        RepositoryProvider<FeaturedProgressRepository>.value(
          value: dependencies.featuredProgressRepository,
        ),
        RepositoryProvider<FeaturedAlertsRepository>.value(
          value: dependencies.featuredAlertsRepository,
        ),
        RepositoryProvider<UnlockRepository>.value(
          value: dependencies.unlockRepository,
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
        RepositoryProvider<LessonScriptRepository>.value(
          value: dependencies.lessonScriptRepository,
        ),
        RepositoryProvider<KpkRepository>.value(
          value: dependencies.kpkRepository,
        ),
        RepositoryProvider<ScriptTableRepository>.value(
          value: dependencies.scriptTableRepository,
        ),
        RepositoryProvider<PositionJudge>.value(
          value: dependencies.engineJudge,
        ),
        RepositoryProvider<ExerciseFeedbackRepository>.value(
          value: dependencies.exerciseFeedbackRepository,
        ),
        RepositoryProvider<EndgameProgressRepository>.value(
          value: dependencies.endgameProgressRepository,
        ),
        RepositoryProvider<DrawOfferRepository>.value(
          value: dependencies.drawOfferRepository,
        ),
        RepositoryProvider<VoiceRepository>.value(
          value: dependencies.voiceRepository,
        ),
        RepositoryProvider<SpeechInputRepository>.value(
          value: dependencies.speechInputRepository,
        ),
        RepositoryProvider<BlindCheckpointRepository>.value(
          value: dependencies.blindCheckpointRepository,
        ),
        RepositoryProvider<BlindLogRepository>.value(
          value: dependencies.blindLogRepository,
        ),
        RepositoryProvider<SurveyRepository>.value(
          value: dependencies.surveyRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SettingsCubit(
              dependencies.settingsRepository,
              languages: dependencies.languages,
              darkTheme: dependencies.darkTheme,
              sound: dependencies.soundRepository,
            )..load(),
          ),
          BlocProvider(
            create: (context) =>
                ProfileCubit(dependencies.profileRepository)..load(),
          ),
          BlocProvider(
            create: (context) =>
                WikiLinksCubit(dependencies.wikiLinksRepository)..load(),
          ),
          BlocProvider(
            create: (context) => SpeechCubit(
              dependencies.voiceRepository,
              characters: dependencies.characterRepository,
            )..load(),
          ),
        ],
        child: BlocBuilder<SettingsCubit, AppSettings?>(
          builder: (context, settings) {
            // Até as preferências chegarem, só o fundo: o app nunca aparece
            // no idioma errado nem na tela errada.
            if (settings == null || router == null) {
              return _LaunchBackground(darkTheme: dependencies.darkTheme);
            }
            return _QuietInBackground(
              child: MaterialApp.router(
                onGenerateTitle: (context) => context.l10n.appTitle,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.of(Brightness.light, accent: settings.accent),
                darkTheme: AppTheme.of(
                  Brightness.dark,
                  accent: settings.accent,
                ),
                themeMode: dependencies.darkTheme
                    ? settings.themeMode.material
                    : ThemeMode.light,
                locale: localeFromCode(settings.languageCode),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: appSupportedLocales,
                routerConfig: router,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// O app foi para segundo plano (ou foi fechado): a voz para.
class _QuietInBackground extends StatefulWidget {
  const _QuietInBackground({required this.child});

  final Widget child;

  @override
  State<_QuietInBackground> createState() => _QuietInBackgroundState();
}

class _QuietInBackgroundState extends State<_QuietInBackground> {
  late final AppLifecycleListener _listener = AppLifecycleListener(
    onHide: () => context.read<SpeechCubit>().stop(),
    // De volta (talvez das configurações de voz do aparelho): uma voz nova
    // pode ter sido baixada.
    onResume: () => context.read<SpeechCubit>().reloadVoices(),
  );

  @override
  void initState() {
    super.initState();
    _listener;
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// O mesmo fundo da abertura nativa e da tela inicial.
class _LaunchBackground extends StatelessWidget {
  const _LaunchBackground({required this.darkTheme});

  final bool darkTheme;

  @override
  Widget build(BuildContext context) {
    final isDark =
        darkTheme &&
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final theme = isDark ? AppTheme.dark : AppTheme.light;
    return ColoredBox(color: theme.scaffoldBackgroundColor);
  }
}
