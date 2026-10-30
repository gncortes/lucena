import 'data/repositories/training/training_endgame_content.dart';
import 'data/repositories/training/course_download_repository.dart';

import 'dart:async';

import 'domain/models/lesson_content.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'config/dependencies.dart';
import 'data/repositories/learning/learning_repository.dart';
import 'data/repositories/training/training_school_content.dart';
import 'data/repositories/training/training_history_source.dart';
import 'domain/use_cases/training/training_analytics.dart';
import 'config/push_alerts.dart';
import 'domain/models/push_alert.dart';
import 'domain/models/campaign.dart';
import 'domain/models/linked_lesson.dart';
import 'data/repositories/campaign/campaign_repository.dart';
import 'routing/routes.dart';
import 'routing/launch_location.dart';
import 'domain/use_cases/visible_lessons.dart';
import 'data/repositories/ads/ads_repository.dart';
import 'data/repositories/alerts/region_prompt_repository.dart';
import 'data/repositories/analytics/analytics_opening.dart';
import 'data/repositories/analytics/analytics_repository.dart';
import 'data/repositories/purchase/purchase_repository.dart';
import 'data/repositories/store/store_listing_repository.dart';
import 'data/repositories/blind/blind_checkpoint_repository.dart';
import 'data/repositories/survey/survey_repository.dart';
import 'data/repositories/week/week_repository.dart';
import 'data/repositories/config/remote_flags_repository.dart';
import 'data/repositories/update/app_update_repository.dart';
import 'data/repositories/rating/rating_repository.dart';
import 'data/repositories/achievements/achievements_repository.dart';
import 'data/repositories/characters/character_repository.dart';
import 'data/repositories/evaluation/evaluation_repository.dart';
import 'data/repositories/characters/talk_repository.dart';
import 'data/repositories/home/home_layout_repository.dart';
import 'data/repositories/featured/featured_alerts_repository.dart';
import 'data/repositories/featured/featured_progress_repository.dart';
import 'data/repositories/course_preview/course_preview_repository.dart';
import 'data/repositories/featured/featured_repository.dart';
import 'data/repositories/home/unlock_repository.dart';
import 'data/repositories/onboarding/onboarding_repository.dart';
import 'data/repositories/pace/pace_repository.dart';
import 'data/repositories/photo/photo_repository.dart';
import 'data/repositories/endgames/endgame_lesson_repository.dart';
import 'data/repositories/feedback/feedback_repository.dart';
import 'data/repositories/review/review_repository.dart';
import 'data/repositories/would_pay/would_pay_repository.dart';
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
import 'data/repositories/account/account_invite_repository.dart';
import 'data/repositories/account/avatar_repository.dart';
import 'data/repositories/account/mail_app_repository.dart';
import 'data/repositories/activity/activity_repository.dart';
import 'data/repositories/daily/daily_final_repository.dart';
import 'data/repositories/crowd/crowd_repository.dart';
import 'data/repositories/account/account_repository.dart';
import 'data/repositories/chesscom/chesscom_repository.dart';
import 'data/repositories/lichess/lichess_repository.dart';
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
import 'data/repositories/sync/sync_scheduler.dart';
import 'data/repositories/training/training_repository.dart';
import 'data/repositories/voice/voice_repository.dart';
import 'data/repositories/blind/blind_log_repository.dart';
import 'data/repositories/training/course_training_repository.dart'
    as course_training;
import 'data/repositories/blind/speech_input_repository.dart';
import 'domain/models/app_settings.dart';
import 'domain/models/app_version.dart';
import 'domain/use_cases/now.dart';
import 'routing/push_route.dart';
import 'routing/router.dart';
import 'routing/screen_tracker.dart';
import 'routing/stream_refresh.dart';
import 'ui/update/view_models/update_cubit.dart';
import 'ui/update/widgets/update_bridge.dart';
import 'ui/alerts/view_models/alerts_cubit.dart';
import 'ui/reminders/view_models/reminders_cubit.dart';
import 'ui/reminders/widgets/reminders_bridge.dart';
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
  final trainingSeed = await Dependencies.trainingInstallSeed();
  // O push que chega com o app fechado: o app monta a notificação.
  if (firebase) listenPushInBackground();
  runApp(
    LucenaApp(
      dependencies: Dependencies.normal(
        version: version,
        firebase: firebase,
        trainingInstallSeed: trainingSeed,
      ),
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

  // O screen_view de cada tela (E1.03).
  ScreenTracker? _screens;

  // Os desafios que chegam por link com o app aberto.
  StreamSubscription<Uri>? _links;

  // Os avisos de push tocados com o app em segundo plano.
  StreamSubscription<PushOpening>? _pushLinks;

  // As estatísticas da abertura e dos links (E1.03).
  late final AnalyticsOpening _analytics = AnalyticsOpening(
    widget.dependencies.analyticsRepository,
    account: widget.dependencies.accountRepository,
    push: widget.dependencies.pushRepository,
    school: widget.dependencies.schoolProgressRepository,
    endgames: widget.dependencies.endgameProgressRepository,
    activity: widget.dependencies.activityRepository,
    now: widget.dependencies.now,
    profile: widget.dependencies.profileRepository,
    campaigns: widget.dependencies.campaignRepository,
    country: () =>
        WidgetsBinding.instance.platformDispatcher.locale.countryCode,
    schoolLessons: VisibleLessons.schoolLessonIds,
  );

  // O progresso indo para a conta (E1.13).
  late final SyncScheduler _sync = SyncScheduler(
    widget.dependencies.accountRepository,
    widget.dependencies.syncRepository,
    changes: widget.dependencies.localChanges,
  );

  // A versão contra o Remote Config e a Play (E1.32).
  late final UpdateCubit _update = UpdateCubit(
    flags: widget.dependencies.remoteFlagsRepository,
    updates: widget.dependencies.appUpdateRepository,
    analytics: widget.dependencies.analyticsRepository,
  );

  // Refaz o redirect da atualização obrigatória quando ela muda.
  late final StreamRefresh _updateRefresh = StreamRefresh(
    _update.stream.map((state) => state.required).distinct(),
  );
  late final StreamRefresh? _accountRefresh =
      widget.dependencies.requireLessonAccount
      ? StreamRefresh(widget.dependencies.accountRepository.changes)
      : null;

  @override
  void initState() {
    super.initState();
    _sync.start();
    unawaited(_update.start());
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
    // Só o último aparelho em que a conta entrou recebe o push dela.
    unawaited(widget.dependencies.accountRepository.linkPushDevice());
    // O dia da primeira abertura conta para o pedido de avaliação (E1.26).
    unawaited(widget.dependencies.reviewRepository.markFirstOpen());
    final pushOpening = await push.initialOpening();
    final pushed = pushOpening?.link;
    final onboarding = await widget.dependencies.onboardingRepository.load();
    var opened = await deepLinks.initialUri();
    // Deferred deep link (T84): na 1ª abertura sem link nem aviso, o link do
    // post que levou à Play abre como se tivesse sido tocado com o app já
    // instalado.
    var fromReferrer = false;
    if (opened == null && pushOpening == null && !onboarding.done) {
      opened = await widget.dependencies.installReferrerRepository
          .pendingLink();
      fromReferrer = opened != null;
    }
    final link = opened != null
        ? (Routes.appLink(opened) == Routes.invalidLink
              ? null
              : deepLinks.parse(opened))
        : (pushed == null ? null : deepLinks.parse(pushed));
    unawaited(
      _analytics.launched(
        link: link,
        lessonLink: opened == null ? null : LessonLink.tryParse(opened),
        pushed: opened == null && pushOpening != null,
        fromReferrer: fromReferrer,
      ),
    );
    // O anúncio (E1.25): sessão nova e, para quem já respondeu "O que você
    // quer fazer?", o consentimento do Google. Quem veio de um link não vê o
    // formulário agora.
    final profile = await widget.dependencies.profileRepository.load();
    unawaited(
      widget.dependencies.adsRepository.start(
        fromLink: opened != null || link != null,
        goalAnswered: onboarding.done || profile.goal != null,
      ),
    );
    // Missing/unpublished content must not trap an old installation in a
    // restored lesson. Keep its progress; only postpone automatic reopening.
    var showSchool = VisibleLessons.school;
    var visibleEndgames = VisibleLessons.endgameLessonIds;
    if (conclusion == null &&
        !(game?.reopensOnLaunch ?? false) &&
        opened == null &&
        link == null &&
        !onboarding.boardControlsOpen) {
      if (showSchool && (school.ongoing?.open ?? false)) {
        try {
          final course = await widget.dependencies.lessonRepository.course();
          showSchool = course.lesson(school.ongoing!.lessonId) != null;
        } on LessonContentUnavailable {
          showSchool = false;
        }
      }
      if ((endgames.ongoing?.open ?? false) || endgames.openExercise != null) {
        try {
          final trail = await widget.dependencies.endgameLessonRepository
              .trail();
          visibleEndgames = {
            for (final lesson in trail.lessons)
              if (visibleEndgames.contains(lesson.id)) lesson.id,
          };
        } on LessonContentUnavailable {
          visibleEndgames = {};
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _router = buildRouter(
        requireLessonAccount: widget.dependencies.requireLessonAccount,
        initialLocation: launchLocation(
          conclusion: conclusion,
          resumeGame: game != null && game.reopensOnLaunch,
          school: school,
          endgames: endgames,
          stars: stars,
          boardControlsOpen: onboarding.boardControlsOpen,
          link: link,
          // Erro frio é empilhado sobre a retomada, para Voltar recuperá-la.
          uri: opened != null && Routes.appLink(opened) != Routes.invalidLink
              ? opened
              : null,
          showSchool: showSchool,
          visibleEndgameLessons: visibleEndgames,
        ),
        updateRequired: () => _update.state.required,
        refresh: Listenable.merge([_updateRefresh, _accountRefresh]),
      );
      _screens = ScreenTracker(
        _router!,
        widget.dependencies.analyticsRepository,
      );
    });
    if (opened != null && Routes.appLink(opened) == Routes.invalidLink) {
      // Espera o roteador montar a retomada antes de empilhar o erro.
      final router = _router!;
      void openInvalid() {
        if (!mounted || router.routerDelegate.currentConfiguration.isEmpty) {
          return;
        }
        router.routerDelegate.removeListener(openInvalid);
        router.push(Routes.invalidLink);
      }

      router.routerDelegate.addListener(openInvalid);
      openInvalid();
    }
    _links = deepLinks.openedUris.listen((uri) {
      final link = deepLinks.parse(uri);
      if (link != null) unawaited(_analytics.opened(link));
      final lessonLink = LessonLink.tryParse(uri);
      if (lessonLink != null) {
        unawaited(
          _analytics.campaignOpened(Campaign.fromLessonLink(lessonLink)),
        );
      }
      final route = Routes.appLink(uri);
      if (route != null) _router?.push(route);
    });
    // Um aviso pode trazer o link de um desafio ou o de uma tela (final do
    // dia, aula, final ou torneio).
    _pushLinks = push.opened.listen((opening) {
      unawaited(_analytics.pushOpened(opening));
      final uri = opening.link;
      // Sem link: o toque só traz o app para a frente.
      if (uri == null) return;
      final link = deepLinks.parse(uri);
      if (link != null) {
        unawaited(_analytics.opened(link));
        _router?.push(Routes.challenge(link));
      } else {
        unawaited(_openPushed(uri));
      }
    });
    if (pushOpening != null) unawaited(_analytics.pushOpened(pushOpening));
    if (opened == null && pushed != null && deepLinks.parse(pushed) == null) {
      await _openPushed(pushed);
    }
  }

  // A tela do link do aviso; link que esta versão não conhece: o início.
  Future<void> _openPushed(Uri uri) async {
    final route = await pushRoute(
      uri,
      // O idioma só muda o título da aula, que o toque não usa.
      pausedLesson: () =>
          widget.dependencies.remindersRepository.pausedLesson('pt'),
    );
    if (!mounted) return;
    if (route == Routes.home) {
      _router?.go(route);
    } else {
      _router?.push(route);
    }
  }

  @override
  void dispose() {
    unawaited(_links?.cancel());
    unawaited(_pushLinks?.cancel());
    unawaited(_sync.dispose());
    _screens?.dispose();
    _router?.dispose();
    _updateRefresh.dispose();
    _accountRefresh?.dispose();
    unawaited(_update.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    final router = _router;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LearningRepository?>.value(
          value: dependencies.learningRepository,
        ),
        RepositoryProvider<Now>.value(value: dependencies.now),
        RepositoryProvider<AnalyticsRepository>.value(
          value: dependencies.analyticsRepository,
        ),
        RepositoryProvider<TrainingAnalytics>(
          create: (_) =>
              dependencies.trainingAnalytics ??
              TrainingAnalytics(
                now: dependencies.now,
                log: dependencies.analyticsRepository.log,
              ),
        ),
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
        RepositoryProvider<CampaignRepository>.value(
          value: dependencies.campaignRepository,
        ),
        RepositoryProvider<AccountRepository>.value(
          value: dependencies.accountRepository,
        ),
        RepositoryProvider<AccountInviteRepository>.value(
          value: dependencies.accountInviteRepository,
        ),
        RepositoryProvider<ActivityRepository>.value(
          value: dependencies.activityRepository,
        ),
        RepositoryProvider<DailyFinalRepository>.value(
          value: dependencies.dailyFinalRepository,
        ),
        RepositoryProvider<CrowdRepository>.value(
          value: dependencies.crowdRepository,
        ),
        RepositoryProvider<SyncScheduler>.value(value: _sync),
        RepositoryProvider<LichessRepository>.value(
          value: dependencies.lichessRepository,
        ),
        RepositoryProvider<ChessComRepository>.value(
          value: dependencies.chessComRepository,
        ),
        RepositoryProvider<PushRepository>.value(
          value: dependencies.pushRepository,
        ),
        RepositoryProvider<AvatarRepository>.value(
          value: dependencies.avatarRepository,
        ),
        RepositoryProvider<PhotoRepository>.value(
          value: dependencies.photoRepository,
        ),
        RepositoryProvider<MailAppRepository>.value(
          value: dependencies.mailAppRepository,
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
        RepositoryProvider<course_training.TrainingRepository>.value(
          value: dependencies.courseTrainingRepository,
        ),
        RepositoryProvider<CourseDownloadRepository>.value(
          value: dependencies.courseDownloads,
        ),
        RepositoryProvider<TrainingSchoolContent>.value(
          value:
              dependencies.trainingSchoolContent ??
              TrainingSchoolContent(dependencies.lessonRepository),
        ),
        RepositoryProvider<TrainingHistorySource>.value(
          value: TrainingHistorySource(
            dependencies.courseTrainingRepository,
            learning: dependencies.learningRepository,
            now: dependencies.now,
          ),
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
        RepositoryProvider<CoursePreviewRepository>.value(
          value: dependencies.coursePreviewRepository,
        ),
        RepositoryProvider<FeaturedProgressRepository>.value(
          value: dependencies.featuredProgressRepository,
        ),
        RepositoryProvider<FeaturedAlertsRepository>.value(
          value: dependencies.featuredAlertsRepository,
        ),
        RepositoryProvider<RegionPromptRepository>.value(
          value: dependencies.regionPromptRepository,
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
        RepositoryProvider<TrainingEndgameContent?>.value(
          value: dependencies.trainingEndgameContent,
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
        RepositoryProvider<FeedbackRepository>.value(
          value: dependencies.feedbackRepository,
        ),
        RepositoryProvider<WouldPayRepository>.value(
          value: dependencies.wouldPayRepository,
        ),
        RepositoryProvider<ReviewRepository>.value(
          value: dependencies.reviewRepository,
        ),
        RepositoryProvider<WeekRepository>.value(
          value: dependencies.weekRepository,
        ),
        RepositoryProvider<RemoteFlagsRepository>.value(
          value: dependencies.remoteFlagsRepository,
        ),
        RepositoryProvider<AdsRepository>.value(
          value: dependencies.adsRepository,
        ),
        RepositoryProvider<PurchaseRepository>.value(
          value: dependencies.purchaseRepository,
        ),
        RepositoryProvider<StoreListingRepository>.value(
          value: dependencies.storeListingRepository,
        ),
        RepositoryProvider<AppUpdateRepository>.value(
          value: dependencies.appUpdateRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UpdateCubit>.value(value: _update),
          BlocProvider(
            create: (context) => SettingsCubit(
              dependencies.settingsRepository,
              languages: dependencies.languages,
              sound: dependencies.soundRepository,
            )..load(),
          ),
          BlocProvider(
            create: (context) => ProfileCubit(
              dependencies.profileRepository,
              // O país do Perfil vem da região do celular, sem permissão.
              region: () =>
                  WidgetsBinding.instance.platformDispatcher.locale.countryCode,
              analytics: dependencies.analyticsRepository,
            )..load(),
          ),
          BlocProvider(
            // Na abertura, já acerta os tópicos do push com as chaves.
            lazy: false,
            create: (context) => AlertsCubit(
              alerts: dependencies.alertsRepository,
              push: dependencies.pushRepository,
              reminders: dependencies.remindersRepository,
              profile: dependencies.profileRepository,
              region: () =>
                  WidgetsBinding.instance.platformDispatcher.locale.countryCode,
              analytics: dependencies.analyticsRepository,
            )..load(),
          ),
          BlocProvider(
            // Os lembretes locais: o RemindersBridge passa as chaves e os
            // textos.
            lazy: false,
            create: (context) => RemindersCubit(
              reminders: dependencies.remindersRepository,
              activity: dependencies.activityRepository,
              week: dependencies.weekRepository,
              now: dependencies.now,
              changes: dependencies.localChanges,
              training: dependencies.courseTrainingRepository,
              courses: activeTrainingCourses,
              analytics: dependencies.analyticsRepository,
            ),
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
              return const _LaunchBackground();
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
                themeMode: settings.themeMode.material,
                locale: localeFromCode(settings.languageCode),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: appSupportedLocales,
                routerConfig: router,
                // Abaixo das traduções: os textos dos lembretes vêm delas.
                builder: (context, child) => UpdateBridge(
                  router: router,
                  child: RemindersBridge(
                    onOpen: (route) {
                      unawaited(
                        _analytics.alertOpened(route, channel: 'local'),
                      );
                      _router?.push(route);
                    },
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
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
    onHide: () {
      context.read<SpeechCubit>().stop();
      context.read<AdsRepository>().hidden();
    },
    // Mais de 30 minutos fora: sessão nova do anúncio (E1.25).
    onShow: () => context.read<AdsRepository>().visible(),
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
  const _LaunchBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final theme = isDark ? AppTheme.dark : AppTheme.light;
    return ColoredBox(color: theme.scaffoldBackgroundColor);
  }
}
