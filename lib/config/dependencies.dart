import '../data/services/lesson_content_service.dart';

import 'dart:async';

import '../data/repositories/activity/activity_repository.dart';
import '../data/repositories/analytics/analytics_repository.dart';
import '../data/services/firebase/analytics_service.dart';
import '../domain/use_cases/analytics_rules.dart';
import '../data/repositories/ads/ads_repository.dart';
import '../data/repositories/purchase/purchase_repository.dart';
import '../data/repositories/store/store_listing_repository.dart';
import '../data/repositories/reminders/reminders_repository.dart';
import '../data/repositories/week/week_repository.dart';
import '../data/repositories/config/remote_flags_repository.dart';
import '../data/repositories/update/app_update_repository.dart';
import '../data/services/app_update_service.dart';
import '../data/services/firebase/remote_config_service.dart';
import '../data/services/notification_service.dart';
import 'push_alerts.dart';
import '../data/repositories/daily/daily_final_repository.dart';
import '../data/repositories/crowd/crowd_repository.dart';
import '../data/repositories/school/lesson_script_repository.dart';
import '../data/repositories/school/lesson_script_repository_asset.dart';
import '../data/repositories/tablebase/engine_judge_repository.dart';
import '../data/repositories/tablebase/kpk_repository.dart';
import '../data/repositories/tablebase/script_table_repository.dart';
import '../domain/use_cases/position_judge.dart';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/repositories/deep_link/deep_link_repository.dart';
import '../data/repositories/deep_link/install_referrer_repository.dart';
import '../data/repositories/campaign/campaign_repository.dart';
import '../data/services/install_referrer_service.dart';
import '../data/repositories/draw/draw_offer_repository.dart';
import '../data/repositories/endgames/endgame_lesson_repository.dart';
import '../data/repositories/endgames/endgame_lesson_repository_asset.dart';
import '../data/repositories/endgames/visible_endgame_lesson_repository.dart';
import '../data/repositories/endgames/endgame_progress_repository.dart';
import '../data/repositories/endgames/exercise_feedback_repository.dart';
import '../data/repositories/endgames/exercise_feedback_repository_asset.dart';
import '../data/repositories/haptics/haptics_repository.dart';
import '../data/repositories/share/share_repository.dart';
import '../data/repositories/placement/placement_repository.dart';
import '../data/repositories/placement/placement_repository_local.dart';
import '../data/repositories/conclusion/conclusion_repository.dart';
import '../data/repositories/conclusion/conclusion_repository_local.dart';
import '../data/repositories/share/share_repository_device.dart';
import '../data/services/share_service.dart';
import '../data/repositories/rating/rating_repository.dart';
import '../data/repositories/achievements/achievements_repository.dart';
import '../data/repositories/characters/character_repository.dart';
import '../data/repositories/evaluation/evaluation_repository.dart';
import '../data/repositories/characters/talk_repository.dart';
import '../data/repositories/home/home_layout_repository.dart';
import '../data/repositories/home/unlock_repository.dart';
import '../data/repositories/onboarding/onboarding_repository.dart';
import '../data/repositories/school/lesson_repository.dart';
import '../data/repositories/school/lesson_repository_asset.dart';
import '../data/repositories/school/visible_lesson_repository.dart';
import '../data/repositories/school/school_progress_repository.dart';
import '../data/repositories/school/star_challenge_repository.dart';
import '../data/repositories/pace/pace_repository.dart';
import '../data/repositories/rating/rating_repository_local.dart';
import '../data/repositories/achievements/achievements_repository_local.dart';
import '../data/repositories/characters/character_repository_asset.dart';
import '../data/repositories/evaluation/evaluation_repository_stockfish.dart';
import '../data/repositories/journey/journey_repository.dart';
import '../data/repositories/journey/journey_repository_asset.dart';
import '../data/repositories/race/race_repository.dart';
import '../data/repositories/race/race_repository_local.dart';
import '../data/repositories/speedrun/speedrun_repository.dart';
import '../data/repositories/speedrun/speedrun_repository_local.dart';
import '../data/repositories/haptics/haptics_repository_device.dart';
import '../data/repositories/analysis/analysis_repository.dart';
import '../data/repositories/analysis/analysis_repository_stockfish.dart';
import '../data/repositories/review/game_review_repository.dart';
import '../data/repositories/sound/sound_repository.dart';
import '../data/repositories/sound/sound_repository_device.dart';
import '../data/services/sound_service.dart';
import '../data/services/tts_service.dart';
import '../data/services/speech_input_service.dart';
import '../data/repositories/blind/blind_log_repository.dart';
import '../data/repositories/blind/blind_checkpoint_repository.dart';
import '../data/repositories/survey/survey_repository.dart';
import '../data/repositories/sync/sync_repository.dart';
import '../data/repositories/endgames/endgame_progress_repository_notifying.dart';
import '../data/repositories/blind/speech_input_repository.dart';
import '../data/repositories/voice/voice_repository.dart';
import '../data/repositories/voice/voice_repository_local.dart';
import '../data/repositories/featured/featured_alerts_repository.dart';
import '../data/repositories/featured/featured_progress_repository.dart';
import '../data/repositories/course_preview/course_preview_repository.dart';
import '../data/repositories/course_preview/course_preview_repository_asset.dart';
import '../data/repositories/featured/featured_repository.dart';
import '../data/repositories/featured/featured_repository_asset.dart';
import '../data/repositories/wiki/wiki_links_repository.dart';
import '../data/repositories/wiki/wiki_links_repository_asset.dart';
import '../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../data/repositories/ongoing_game/ongoing_game_repository_local.dart';
import '../data/repositories/maia/maia_repository.dart';
import '../data/repositories/maia/maia_repository_device.dart';
import '../data/repositories/opponent/opponent_repository.dart';
import '../data/repositories/opponent/opponent_repository_device.dart';
import '../data/repositories/opponent/opponent_repository_maia.dart';
import '../data/repositories/opponent/opponent_repository_stockfish.dart';
import '../data/repositories/positions/positions_repository.dart';
import '../data/repositories/positions/positions_repository_asset.dart';
import '../data/repositories/profile/profile_repository.dart';
import '../data/repositories/progress/progress_repository.dart';
import '../data/repositories/progress/progress_repository_local.dart';
import '../data/repositories/progress/progress_repository_restored.dart';
import '../data/repositories/profile/profile_repository_local.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/repositories/settings/settings_repository_local.dart';
import '../data/repositories/training/training_repository.dart';
import '../data/repositories/training/training_repository_local.dart';
import '../data/services/asset_service.dart';
import '../data/services/database/app_database.dart';
import '../data/services/maia_service.dart';
import '../data/services/preferences_service.dart';
import '../data/services/stockfish_service.dart';
import '../data/services/vibration_service.dart';
import '../data/repositories/account/account_invite_repository.dart';
import '../data/repositories/account/avatar_repository.dart';
import '../data/repositories/account/mail_app_repository.dart';
import '../data/repositories/photo/photo_repository.dart';
import '../data/repositories/account/account_repository.dart';
import '../data/repositories/chesscom/chesscom_repository.dart';
import '../data/repositories/chesscom/chesscom_repository_remote.dart';
import '../data/repositories/lichess/lichess_repository.dart';
import '../data/repositories/lichess/lichess_repository_remote.dart';
import '../data/services/chesscom_service.dart';
import '../data/services/lichess_service.dart';
import '../data/services/secure_storage_service.dart';
import '../data/repositories/alerts/alerts_repository.dart';
import '../data/repositories/alerts/region_prompt_repository.dart';
import '../data/repositories/push/push_repository.dart';
import '../data/services/app_links_deep_link_service.dart';
import '../data/services/firebase/auth_service.dart';
import '../data/services/firebase/cloud_store_service.dart';
import '../data/repositories/feedback/feedback_repository.dart';
import '../data/repositories/review/review_repository.dart';
import '../data/repositories/would_pay/would_pay_repository.dart';
import '../data/services/device_service.dart';
import '../data/services/review_service.dart';
import '../data/services/firebase/file_store_service.dart';
import '../data/services/firebase/push_service.dart';
import '../domain/models/app_language.dart';
import '../domain/models/app_version.dart';
import '../domain/use_cases/now.dart';

/// Ligado por `--dart-define=E2E=true` nos cenários Patrol.
const isE2E = bool.fromEnvironment('E2E');

/// O modo das estatísticas deste build (E1.03 §10): `FDROID=true` no build do
/// F-Droid, `ANALYTICS_DEBUG=true` para o DebugView e `CANAL=qa` na QA.
final analyticsMode = AnalyticsRules.mode(
  release: kReleaseMode,
  e2e: isE2E,
  fdroid: const bool.fromEnvironment('FDROID'),
  debugView: const bool.fromEnvironment('ANALYTICS_DEBUG'),
  channel: const String.fromEnvironment('CANAL'),
);

/// A versão do app (`0.3.2-rc.1`), passada pelo CI ao montar o APK assinado.
/// Vazia nos builds locais: aí vale a do aparelho ([Dependencies.installedVersion]).
const appVersion = String.fromEnvironment('APP_VERSION');

/// As telas de desenvolvimento aparecem nos builds de depuração, nos cenários
/// Patrol e nas candidatas de QA (`-rc`); nunca na versão final.
bool get showsDevTools => kDebugMode || isE2E || appVersion.contains('-rc');

/// As implementações que entram no app.
///
/// As composições de teste ficam em `testing/`: código de `lib/` não importa
/// `testing/`.
class Dependencies {
  Dependencies({
    required this.now,
    required this.settingsRepository,
    required this.profileRepository,
    required this.hapticsRepository,
    required this.shareRepository,
    required this.deepLinkRepository,
    required this.accountRepository,
    required this.lichessRepository,
    required this.chessComRepository,
    required this.pushRepository,
    required this.alertsRepository,
    required this.placementRepository,
    required this.soundRepository,
    required this.analysisRepository,
    required this.gameReviewRepository,
    required this.ongoingGameRepository,
    required this.conclusionRepository,
    required this.positionsRepository,
    required this.trainingRepository,
    required this.opponentRepository,
    required this.maiaRepository,
    required this.progressRepository,
    required this.journeyRepository,
    required this.speedrunRepository,
    required this.raceRepository,
    required this.ratingRepository,
    required this.achievementsRepository,
    required this.characterRepository,
    required this.evaluationRepository,
    required this.talkRepository,
    required this.onboardingRepository,
    required this.homeLayoutRepository,
    required this.unlockRepository,
    required this.paceRepository,
    required this.lessonRepository,
    required this.schoolProgressRepository,
    required this.starChallengeRepository,
    required this.endgameLessonRepository,
    required this.lessonScriptRepository,
    required this.kpkRepository,
    required this.scriptTableRepository,
    required this.engineJudge,
    required this.endgameProgressRepository,
    this.exerciseFeedbackRepository = const EmptyExerciseFeedbackRepository(),
    required this.drawOfferRepository,
    required this.voiceRepository,
    required this.speechInputRepository,
    required this.blindLogRepository,
    required this.blindCheckpointRepository,
    required this.surveyRepository,
    required this.wikiLinksRepository,
    required this.featuredRepository,
    required this.coursePreviewRepository,
    required this.featuredProgressRepository,
    required this.activityRepository,
    required this.dailyFinalRepository,
    this.featuredAlertsRepository = const NoFeaturedAlertsRepository(),
    this.regionPromptRepository = const NoRegionPromptRepository(),
    this.syncRepository = const NoSyncRepository(),
    this.crowdRepository = const NoCrowdRepository(),
    this.accountInviteRepository = const NoAccountInviteRepository(),
    this.avatarRepository = const NoAvatarRepository(),
    this.photoRepository = const NoPhotoRepository(),
    this.mailAppRepository = const NoMailAppRepository(),
    this.analyticsRepository = const NoAnalyticsRepository(),
    this.adsRepository = const NoAdsRepository(),
    this.purchaseRepository = const NoPurchaseRepository(),
    this.storeListingRepository = const NoStoreListingRepository(),
    this.feedbackRepository = const NoFeedbackRepository(),
    this.wouldPayRepository = const NoWouldPayRepository(),
    this.reviewRepository = const NoReviewRepository(),
    this.installReferrerRepository = const NoInstallReferrerRepository(),
    this._campaignRepository,
    this.localChanges = const Stream.empty(),
    this._remindersRepository,
    this._weekRepository,
    this._remoteFlagsRepository,
    this._appUpdateRepository,
    required this.languages,
    this.version = const AppVersion(appVersion),
  });

  /// A versão do CI ou, nos builds locais, a do `pubspec.yaml` lida do
  /// aparelho.
  static Future<AppVersion> installedVersion() async {
    if (appVersion.isNotEmpty) return const AppVersion(appVersion);
    final info = await PackageInfo.fromPlatform();
    return AppVersion(info.version);
  }

  /// [firebase] diz se o Firebase subiu (`startFirebase`). Sem ele, a conta e
  /// o push ficam desligados e o resto do app funciona igual.
  factory Dependencies.normal({
    AppVersion version = const AppVersion(appVersion),
    bool firebase = false,
  }) {
    final preferences = PreferencesService();
    final settings = LocalSettingsRepository(preferences);
    // Um plugin só para os lembretes e o push (o toque tem um dono só).
    final notifications = DeviceNotificationService();
    final database = AppDatabase();
    const now = SystemNow();
    const assets = AssetService();
    final lessonContent = createLessonContentAssets(
      releaseBuild: kReleaseMode,
      firebase: firebase,
      localUrl: const String.fromEnvironment('CONTENT_URL'),
      publishedRelease: const String.fromEnvironment('CONTENT_RELEASE'),
    );
    final positions = AssetPositionsRepository(assets);
    final maia = MaiaService(() => assets.loadBytes(MaiaService.weightsAsset));
    final stockfish = StockfishService();
    final pace = AssetPaceRepository(assets);
    final profile = LocalProfileRepository(database);
    final maiaRepository = DeviceMaiaRepository(maia);
    final evaluation = StockfishEvaluationRepository(stockfish);
    final lessons = AssetLessonRepository(lessonContent);
    final cloudStore = firebase
        ? FirestoreCloudStoreService()
        : const NoCloudStoreService();
    // Partida ou aula gravada: a conta recebe o progresso pouco depois.
    final changes = StreamController<void>.broadcast();
    final progress = RestoredProgressRepository(
      LocalProgressRepository(database),
      preferences,
      onAdded: () => changes.add(null),
    );
    final activity = LocalActivityRepository(preferences, progress, now);
    // Capítulo terminado: também é dia com atividade (decisão 2b da E1.22).
    void changed() {
      changes.add(null);
      unawaited(activity.markToday());
    }

    final journey = AssetJourneyRepository(assets, positions);
    final speedruns = LocalSpeedrunRepository(database);
    final race = LocalRaceRepository(assets, preferences, now);
    final rating = LocalRatingRepository(
      database,
      maia: maiaRepository,
      profile: profile,
      now: now,
    );
    final onboarding = LocalOnboardingRepository(preferences);
    final school = ActiveSchoolProgressRepository(
      LocalSchoolProgressRepository(preferences),
      activity,
    );
    final stars = LocalStarChallengeRepository(preferences);
    final endgames = NotifyingEndgameProgressRepository(
      LocalEndgameProgressRepository(preferences),
      changed,
    );
    // Só as aulas liberadas (VisibleLessons); as falas comuns vêm todas.
    final endgameLessons = VisibleEndgameLessonRepository(
      AssetEndgameLessonRepository(lessonContent, school: lessons),
    );
    final featured = ActiveFeaturedProgressRepository(
      LocalFeaturedProgressRepository(preferences),
      activity,
    );
    final flags = RemoteConfigFlagsRepository(
      firebase ? FirebaseRemoteConfigService() : NoRemoteConfigService(),
      // Nas versões de teste, o valor novo do console vale na hora.
      minimumFetchInterval: showsDevTools
          ? Duration.zero
          : const Duration(hours: 12),
    );
    // A V1 sai sem anúncios nem "Remover anúncios" (decisão do Gabriel,
    // 2026-10-22): o código da E1.25 fica, com os serviços vazios.
    const purchases = NoPurchaseRepository();
    final analytics = ServiceAnalyticsRepository(
      firebase && analyticsMode != AnalyticsMode.off
          ? FirebaseAnalyticsService()
          : const NoAnalyticsService(),
      preferences,
      mode: analyticsMode,
    );
    const ads = NoAdsRepository();
    final PushService pushService = firebase
        ? FirebasePushService()
        : const NoPushService();
    final avatars = CloudAvatarRepository(
      firebase ? FirebaseFileStoreService() : const NoFileStoreService(),
    );
    return Dependencies(
      now: now,
      settingsRepository: settings,
      profileRepository: profile,
      hapticsRepository: const DeviceHapticsRepository(VibrationService()),
      shareRepository: const DeviceShareRepository(ShareService()),
      deepLinkRepository: ServiceDeepLinkRepository(AppLinksDeepLinkService()),
      installReferrerRepository: ServiceInstallReferrerRepository(
        const PlayInstallReferrerService(),
        preferences,
      ),
      campaignRepository: LocalCampaignRepository(preferences),
      accountRepository: CloudAccountRepository(
        firebase ? FirebaseAuthService() : const NoAuthService(),
        cloudStore,
        avatars: avatars,
        now: now,
        language: () async => (await settings.load()).languageCode,
        push: pushService,
        preferences: preferences,
      ),
      lichessRepository: RemoteLichessRepository(
        service: LichessService(),
        storage: DeviceSecureStorageService(),
        links: AppLinksDeepLinkService(),
        now: now,
      ),
      chessComRepository: RemoteChessComRepository(ChessComService(), now: now),
      pushRepository: FirebasePushRepository(
        pushService,
        preferences,
        notifications: notifications,
        texts: () => loadPushTexts(settings),
      ),
      alertsRepository: LocalAlertsRepository(preferences),
      regionPromptRepository: LocalRegionPromptRepository(preferences),
      placementRepository: LocalPlacementRepository(assets, preferences),
      soundRepository: DeviceSoundRepository(SoundService()),
      analysisRepository: StockfishAnalysisRepository(stockfish),
      gameReviewRepository: LocalGameReviewRepository(preferences),
      ongoingGameRepository: LocalOngoingGameRepository(preferences),
      conclusionRepository: LocalConclusionRepository(preferences),
      positionsRepository: positions,
      trainingRepository: LocalTrainingRepository(preferences),
      opponentRepository: DeviceOpponentRepository(
        maia: MaiaOpponentRepository(maia, now: now, pace: pace),
        stockfish: StockfishOpponentRepository(stockfish),
      ),
      maiaRepository: maiaRepository,
      progressRepository: progress,
      journeyRepository: journey,
      speedrunRepository: speedruns,
      raceRepository: race,
      ratingRepository: rating,
      achievementsRepository: LocalAchievementsRepository(assets, database),
      characterRepository: AssetCharacterRepository(assets),
      // O mesmo Stockfish do adversário: contra o Maia ele está livre.
      evaluationRepository: evaluation,
      talkRepository: LocalTalkRepository(preferences),
      onboardingRepository: onboarding,
      homeLayoutRepository: LocalHomeLayoutRepository(preferences),
      unlockRepository: LocalUnlockRepository(preferences),
      paceRepository: pace,
      lessonRepository: VisibleLessonRepository(lessons),
      schoolProgressRepository: school,
      starChallengeRepository: stars,
      endgameLessonRepository: endgameLessons,
      lessonScriptRepository: AssetLessonScriptRepository(lessonContent),
      kpkRepository: AssetKpkRepository(assets),
      scriptTableRepository: AssetScriptTableRepository(assets),
      // O juiz de reserva da lição em roteiro: o mesmo Stockfish (T76).
      engineJudge: StockfishJudgeRepository(stockfish),
      endgameProgressRepository: endgames,
      exerciseFeedbackRepository: AssetExerciseFeedbackRepository(
        lessonContent,
      ),
      drawOfferRepository: DeviceDrawOfferRepository(
        maia: maiaRepository,
        evaluation: evaluation,
      ),
      voiceRepository: LocalVoiceRepository(preferences, assets, TtsService()),
      speechInputRepository: DeviceSpeechInputRepository(SpeechInputService()),
      blindLogRepository: LocalBlindLogRepository(preferences),
      blindCheckpointRepository: LocalBlindCheckpointRepository(preferences),
      surveyRepository: LocalSurveyRepository(preferences, now),
      wikiLinksRepository: AssetWikiLinksRepository(lessonContent),
      featuredRepository: AssetFeaturedRepository(assets),
      coursePreviewRepository: AssetCoursePreviewRepository(lessonContent),
      featuredProgressRepository: featured,
      activityRepository: activity,
      crowdRepository: CloudCrowdRepository(cloudStore),
      dailyFinalRepository: LocalDailyFinalRepository(
        assets,
        positions,
        preferences,
      ),
      accountInviteRepository: LocalAccountInviteRepository(preferences),
      avatarRepository: avatars,
      photoRepository: DevicePhotoRepository(),
      mailAppRepository: const DeviceMailAppRepository(),
      analyticsRepository: analytics,
      adsRepository: ads,
      purchaseRepository: purchases,
      storeListingRepository: firebase
          ? const PlayStoreListingRepository()
          : const NoStoreListingRepository(),
      // Sem Firebase (F-Droid): nada vai à nuvem e a Play nunca é chamada.
      feedbackRepository: firebase
          ? CloudFeedbackRepository(
              cloudStore,
              PluginDeviceService(),
              version,
              origin: analytics.origin,
            )
          : const NoFeedbackRepository(),
      wouldPayRepository: LocalWouldPayRepository(preferences),
      reviewRepository: LocalReviewRepository(
        preferences,
        firebase ? PlayReviewService() : const NoReviewService(),
        now,
      ),
      syncRepository: CloudSyncRepository(
        store: cloudStore,
        preferences: preferences,
        now: now,
        profile: profile,
        rating: rating,
        progress: progress,
        endgames: endgames,
        school: school,
        stars: stars,
        onboarding: onboarding,
        journey: journey,
        speedruns: speedruns,
        race: race,
        featured: featured,
      ),
      localChanges: changes.stream,
      remindersRepository: LocalRemindersRepository(
        notifications,
        progress: endgames,
        lessons: endgameLessons,
      ),
      remoteFlagsRepository: flags,
      appUpdateRepository: PlayAppUpdateRepository(
        firebase ? const PlayAppUpdateService() : const NoAppUpdateService(),
        preferences,
        build: () async =>
            int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0,
      ),
      languages: AppLanguage.selectable,
      version: version,
    );
  }

  final AppVersion version;

  final Now now;
  final SettingsRepository settingsRepository;
  final ProfileRepository profileRepository;
  final HapticsRepository hapticsRepository;
  final ShareRepository shareRepository;
  final DeepLinkRepository deepLinkRepository;
  final AccountRepository accountRepository;
  final LichessRepository lichessRepository;
  final ChessComRepository chessComRepository;
  final PushRepository pushRepository;
  final AlertsRepository alertsRepository;
  final PlacementRepository placementRepository;
  final SoundRepository soundRepository;
  final AnalysisRepository analysisRepository;
  final GameReviewRepository gameReviewRepository;
  final OngoingGameRepository ongoingGameRepository;
  final ConclusionRepository conclusionRepository;
  final PositionsRepository positionsRepository;
  final TrainingRepository trainingRepository;
  final OpponentRepository opponentRepository;
  final MaiaRepository maiaRepository;
  final ProgressRepository progressRepository;
  final JourneyRepository journeyRepository;
  final SpeedrunRepository speedrunRepository;
  final RaceRepository raceRepository;
  final RatingRepository ratingRepository;
  final AchievementsRepository achievementsRepository;
  final CharacterRepository characterRepository;
  final EvaluationRepository evaluationRepository;
  final TalkRepository talkRepository;
  final OnboardingRepository onboardingRepository;
  final HomeLayoutRepository homeLayoutRepository;
  final UnlockRepository unlockRepository;
  final PaceRepository paceRepository;
  final LessonRepository lessonRepository;
  final SchoolProgressRepository schoolProgressRepository;
  final StarChallengeRepository starChallengeRepository;
  final EndgameLessonRepository endgameLessonRepository;
  final LessonScriptRepository lessonScriptRepository;
  final KpkRepository kpkRepository;

  /// As tabelas dos roteiros com mais de 3 peças (T76).
  final ScriptTableRepository scriptTableRepository;

  /// O juiz de reserva da lição em roteiro, fora das tabelas (T76).
  final PositionJudge engineJudge;
  final EndgameProgressRepository endgameProgressRepository;
  final ExerciseFeedbackRepository exerciseFeedbackRepository;
  final DrawOfferRepository drawOfferRepository;
  final VoiceRepository voiceRepository;
  final SpeechInputRepository speechInputRepository;
  final BlindLogRepository blindLogRepository;
  final BlindCheckpointRepository blindCheckpointRepository;

  /// O questionário "Sua opinião" (E1.05), guardado no aparelho.
  final SurveyRepository surveyRepository;

  /// As páginas da Wikipedia dos nomes marcados nas falas das aulas.
  final WikiLinksRepository wikiLinksRepository;

  /// Os finais em destaque, o que o jogador já fez com eles e o aviso de
  /// final novo (sem canal por enquanto: E1.20 e E1.21).
  final FeaturedRepository featuredRepository;

  /// A prévia do Pilares do Xadrez (T82, só em desenvolvimento).
  final CoursePreviewRepository coursePreviewRepository;
  final FeaturedProgressRepository featuredProgressRepository;
  final FeaturedAlertsRepository featuredAlertsRepository;

  /// A folha de estado e cidade, uma vez só (E1.21).
  final RegionPromptRepository regionPromptRepository;

  /// Os dias com atividade, para a sequência (E1.22).
  final ActivityRepository activityRepository;
  final DailyFinalRepository dailyFinalRepository;

  /// O "x% acertaram" (E1.24), lido da nuvem.
  final CrowdRepository crowdRepository;

  /// O progresso na conta (E1.13). Sem conta, ninguém chama.
  final SyncRepository syncRepository;
  final AccountInviteRepository accountInviteRepository;

  /// A foto de perfil enviada (§2.12), no Storage da conta.
  final AvatarRepository avatarRepository;

  /// A câmera e a galeria, para a foto do perfil.
  final PhotoRepository photoRepository;

  /// "Abrir o e-mail" depois do link de senha nova.
  final MailAppRepository mailAppRepository;

  /// As estatísticas de uso (E1.03).
  final AnalyticsRepository analyticsRepository;

  /// Os anúncios antes das aulas, a compra que os tira e a página do app na
  /// Play (E1.25). Fora da Play, nenhum.
  final AdsRepository adsRepository;
  final PurchaseRepository purchaseRepository;
  final StoreListingRepository storeListingRepository;

  /// "Enviar feedback" e o "Você pagaria?" (E1.26), em `feedback/{id}`.
  final FeedbackRepository feedbackRepository;
  final WouldPayRepository wouldPayRepository;

  /// O pedido de avaliação da Play (E1.26).
  final ReviewRepository reviewRepository;

  /// O link de campanha da instalação pela Play (deferred deep link, T84).
  final InstallReferrerRepository installReferrerRepository;

  /// A campanha do último link de post (T84). Sem nenhuma, só na memória.
  CampaignRepository get campaignRepository =>
      _campaignRepository ??= MemoryCampaignRepository();
  CampaignRepository? _campaignRepository;

  /// Avisa que o aparelho gravou progresso (partida ou aula terminada).
  final Stream<void> localChanges;

  /// Os lembretes locais (E1.23). Sem nenhum, o aparelho não agenda nada.
  RemindersRepository get remindersRepository =>
      _remindersRepository ??= LocalRemindersRepository(
        const NoNotificationService(),
        progress: endgameProgressRepository,
        lessons: endgameLessonRepository,
      );
  RemindersRepository? _remindersRepository;

  /// Sua semana (E1.23), das partidas, do rating e dos finais do dia.
  WeekRepository get weekRepository => _weekRepository ??= LocalWeekRepository(
    progress: progressRepository,
    rating: ratingRepository,
    activity: activityRepository,
    daily: dailyFinalRepository,
    now: now,
  );
  WeekRepository? _weekRepository;

  /// As chaves do Remote Config (E1.32), com os padrões do app sem rede.
  RemoteFlagsRepository get remoteFlagsRepository => _remoteFlagsRepository ??=
      RemoteConfigFlagsRepository(NoRemoteConfigService());
  RemoteFlagsRepository? _remoteFlagsRepository;

  /// A versão instalada contra a da Play (E1.32).
  AppUpdateRepository get appUpdateRepository =>
      _appUpdateRepository ??= const NoAppUpdateRepository();
  AppUpdateRepository? _appUpdateRepository;

  /// Idiomas oferecidos em Configurações.
  final List<AppLanguage> languages;
}
