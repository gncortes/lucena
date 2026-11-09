import '../../data/repositories/alerts/alerts_repository.dart';
import '../../data/repositories/alerts/region_prompt_repository.dart';
import '../../data/repositories/campaign/campaign_repository.dart';
import '../../data/repositories/characters/character_repository_asset.dart';
import '../../data/repositories/characters/talk_repository.dart';
import '../../data/repositories/blind/blind_checkpoint_repository.dart';
import '../../data/repositories/blind/blind_log_repository.dart';
import '../../data/repositories/blind/speech_input_repository.dart';
import '../../data/repositories/conclusion/conclusion_repository_local.dart';
import '../../data/repositories/course_preview/course_preview_repository_asset.dart';
import '../../data/repositories/daily/daily_final_repository.dart';
import '../../data/repositories/deep_link/deep_link_repository.dart';
import '../../data/repositories/deep_link/install_referrer_repository.dart';
import '../../data/repositories/endgames/exercise_feedback_repository_asset.dart';
import '../../data/repositories/featured/featured_alerts_repository.dart';
import '../../data/repositories/featured/featured_repository_asset.dart';
import '../../data/repositories/feedback/feedback_draft_repository.dart';
import '../../data/repositories/haptics/haptics_repository_device.dart';
import '../../data/repositories/home/home_layout_repository.dart';
import '../../data/repositories/account/mail_app_repository.dart';
import '../../data/repositories/analysis/learning_analysis_repository.dart';
import '../../data/repositories/ongoing_game/ongoing_game_repository_local.dart';
import '../../data/repositories/photo/photo_repository.dart';
import '../../data/repositories/placement/placement_repository_local.dart';
import '../../data/repositories/push/push_repository.dart';
import '../../data/repositories/school/lesson_script_repository_asset.dart';
import '../../data/repositories/school/visible_lesson_repository.dart';
import '../../data/repositories/share/share_repository_device.dart';
import '../../data/repositories/sound/sound_repository_device.dart';
import '../../data/repositories/survey/survey_repository.dart';
import '../../data/repositories/tablebase/kpk_repository.dart';
import '../../data/repositories/tablebase/script_table_repository.dart';
import '../../data/repositories/training/training_repository_local.dart';
import '../../data/repositories/voice/voice_repository_local.dart';
import '../../data/repositories/wiki/wiki_links_repository_asset.dart';
import '../../data/services/app_links_deep_link_service.dart';
import '../../data/services/firebase/push_service.dart';
import '../../data/services/install_referrer_service.dart';
import '../../data/services/share_service.dart';
import '../../data/services/sound_service.dart';
import '../../data/services/speech_input_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/vibration_service.dart';
import '../../domain/models/app_language.dart';
import '../../domain/models/app_version.dart';
import '../dependencies.dart';
import 'account.dart';
import 'content.dart';
import 'core.dart';
import 'engines.dart';
import 'notifications.dart';
import 'progress.dart';
import 'store.dart';
import 'training.dart';
import 'treinador.dart';

/// A composição do app de verdade (`Dependencies.normal`), montada por área.
Dependencies buildNormalDependencies({
  required AppVersion version,
  required bool firebase,
  String? trainingInstallSeed,
  PushRepository? push,
  PushService? pushService,
}) {
  final core = CoreDependencies.create(firebase: firebase);
  final content = ContentDependencies.create(core);
  final engines = EngineDependencies.create(core);
  final store = StoreDependencies.create(core);
  final treinador = TreinadorDependencies.create(core);
  late final TrainingDependencies training;
  final progress = ProgressDependencies.create(
    core,
    content,
    maia: engines.maiaRepository,
    onUnitCompleted: (completion) => training.learningBridge.call(completion),
  );
  training = TrainingDependencies.create(
    core,
    content,
    progress,
    store,
    trainingInstallSeed: trainingInstallSeed,
  );
  final account = AccountDependencies.create(
    core,
    version: version,
    pushService: pushService,
  );
  final notifications = NotificationDependencies.create(
    core,
    pushes: account.pushes,
    endgames: progress.endgames,
    endgameLessons: content.endgameLessons,
    push: push,
  );
  final now = core.now;
  final preferences = core.preferences;
  final assets = core.assets;
  final lessonContent = content.lessonContent;
  return Dependencies(
    now: now,
    settingsRepository: core.settings,
    profileRepository: progress.profile,
    hapticsRepository: const DeviceHapticsRepository(VibrationService()),
    shareRepository: const DeviceShareRepository(ShareService()),
    deepLinkRepository: ServiceDeepLinkRepository(AppLinksDeepLinkService()),
    installReferrerRepository: ServiceInstallReferrerRepository(
      const PlayInstallReferrerService(),
      preferences,
    ),
    campaignRepository: LocalCampaignRepository(preferences),
    accountRepository: account.account,
    lichessRepository: account.lichess,
    chessComRepository: account.chessCom,
    pushRepository: notifications.push,
    alertsRepository: LocalAlertsRepository(preferences),
    regionPromptRepository: LocalRegionPromptRepository(preferences),
    placementRepository: LocalPlacementRepository(assets, preferences),
    soundRepository: DeviceSoundRepository(SoundService()),
    analysisRepository: engines.analysis,
    learningAnalysisRepository: LearningAnalysisRepository(preferences),
    gameReviewRepository: engines.reviews,
    deepAnalysisRepository: engines.deepAnalysis,
    ongoingGameRepository: LocalOngoingGameRepository(preferences),
    conclusionRepository: LocalConclusionRepository(preferences),
    positionsRepository: content.positions,
    trainingRepository: LocalTrainingRepository(preferences),
    courseTrainingRepository: training.courseTraining,
    courseDownloads: training.courseDownloads,
    trainingAnalytics: training.analytics,
    opponentRepository: engines.opponent,
    maiaRepository: engines.maiaRepository,
    progressRepository: progress.progress,
    journeyRepository: progress.journey,
    speedrunRepository: progress.speedruns,
    raceRepository: progress.race,
    ratingRepository: progress.rating,
    achievementsRepository: progress.achievements,
    characterRepository: AssetCharacterRepository(assets),
    evaluationRepository: engines.evaluation,
    talkRepository: LocalTalkRepository(preferences),
    onboardingRepository: progress.onboarding,
    homeLayoutRepository: LocalHomeLayoutRepository(preferences),
    paceRepository: engines.pace,
    lessonRepository: VisibleLessonRepository(content.lessons),
    trainingSchoolContent: content.trainingSchoolContent,
    schoolProgressRepository: progress.school,
    starChallengeRepository: progress.stars,
    endgameLessonRepository: content.endgameLessons,
    trainingEndgameContent: training.endgameContent,
    lessonScriptRepository: AssetLessonScriptRepository(lessonContent),
    kpkRepository: AssetKpkRepository(assets),
    scriptTableRepository: AssetScriptTableRepository(assets),
    engineJudge: engines.engineJudge,
    endgameProgressRepository: progress.endgames,
    exerciseFeedbackRepository: AssetExerciseFeedbackRepository(lessonContent),
    drawOfferRepository: engines.drawOffer,
    voiceRepository: LocalVoiceRepository(preferences, assets, TtsService()),
    speechInputRepository: DeviceSpeechInputRepository(SpeechInputService()),
    blindLogRepository: LocalBlindLogRepository(preferences),
    blindCheckpointRepository: LocalBlindCheckpointRepository(preferences),
    surveyRepository: LocalSurveyRepository(preferences, now),
    wikiLinksRepository: AssetWikiLinksRepository(lessonContent),
    featuredRepository: AssetFeaturedRepository(assets),
    coursePreviewRepository: AssetCoursePreviewRepository(lessonContent),
    featuredProgressRepository: progress.featured,
    featuredAlertsRepository: LocalFeaturedAlertsRepository(preferences),
    activityRepository: progress.activity,
    dailyFinalRepository: LocalDailyFinalRepository(
      assets,
      content.positions,
      preferences,
    ),
    accountInviteRepository: account.invite,
    avatarRepository: account.avatars,
    photoRepository: DevicePhotoRepository(),
    mailAppRepository: const DeviceMailAppRepository(),
    analyticsRepository: core.analytics,
    adsRepository: store.ads,
    demoAdRepository: store.demoAd,
    demoOfferRepository: store.demoOffer,
    openingOfferRepository: store.openingOffer,
    purchaseRepository: store.purchases,
    courseAccessRepository: store.courseAccess,
    courseGrantsRepository: store.courseGrants,
    treinadorRepository: treinador.treinador,
    storeListingRepository: store.storeListing,
    feedbackRepository: account.feedback,
    dataExportRepository: account.dataExport,
    legalConsentRepository: account.legalConsent,
    feedbackDraftRepository: LocalFeedbackDraftRepository(preferences),
    reviewRepository: account.review,
    learningRepository: progress.learning,
    requireLessonAccount: firebase,
    syncRepository: progress.sync(core),
    localChanges: progress.changes.stream,
    remindersRepository: notifications.reminders,
    remoteFlagsRepository: notifications.flags,
    appUpdateRepository: notifications.appUpdate,
    languages: AppLanguage.selectable,
    version: version,
  );
}
