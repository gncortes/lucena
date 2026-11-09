import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/account/account_invite_repository.dart';
import '../data/repositories/account/account_repository.dart';
import '../data/repositories/account/avatar_repository.dart';
import '../data/repositories/account/mail_app_repository.dart';
import '../data/repositories/achievements/achievements_repository.dart';
import '../data/repositories/activity/activity_repository.dart';
import '../data/repositories/ads/ads_repository.dart';
import '../data/repositories/alerts/alerts_repository.dart';
import '../data/repositories/alerts/region_prompt_repository.dart';
import '../data/repositories/analysis/analysis_repository.dart';
import '../data/repositories/analysis/learning_analysis_repository.dart';
import '../data/repositories/analytics/analytics_repository.dart';
import '../data/repositories/blind/blind_checkpoint_repository.dart';
import '../data/repositories/blind/blind_log_repository.dart';
import '../data/repositories/blind/speech_input_repository.dart';
import '../data/repositories/campaign/campaign_repository.dart';
import '../data/repositories/characters/character_repository.dart';
import '../data/repositories/characters/talk_repository.dart';
import '../data/repositories/chesscom/chesscom_repository.dart';
import '../data/repositories/conclusion/conclusion_repository.dart';
import '../data/repositories/config/remote_flags_repository.dart';
import '../data/repositories/course_preview/course_preview_repository.dart';
import '../data/repositories/daily/daily_final_repository.dart';
import '../data/repositories/data_export/data_export_repository.dart';
import '../data/repositories/deep_analysis/deep_analysis_repository.dart';
import '../data/repositories/deep_link/deep_link_repository.dart';
import '../data/repositories/device/device_settings_repository.dart';
import '../data/repositories/draw/draw_offer_repository.dart';
import '../data/repositories/endgames/endgame_lesson_repository.dart';
import '../data/repositories/endgames/endgame_progress_repository.dart';
import '../data/repositories/endgames/exercise_feedback_repository.dart';
import '../data/repositories/evaluation/evaluation_repository.dart';
import '../data/repositories/featured/featured_alerts_repository.dart';
import '../data/repositories/featured/featured_progress_repository.dart';
import '../data/repositories/featured/featured_repository.dart';
import '../data/repositories/feedback/feedback_draft_repository.dart';
import '../data/repositories/feedback/feedback_repository.dart';
import '../data/repositories/haptics/haptics_repository.dart';
import '../data/repositories/home/home_layout_repository.dart';
import '../data/repositories/journey/journey_repository.dart';
import '../data/repositories/learning/learning_repository.dart';
import '../data/repositories/legal/legal_consent_repository.dart';
import '../data/repositories/legal/legal_repository.dart';
import '../data/repositories/lesson_ad/course_access_repository.dart';
import '../data/repositories/lesson_ad/course_grants_repository.dart';
import '../data/repositories/lesson_ad/demo_ad_repository.dart';
import '../data/repositories/lichess/lichess_repository.dart';
import '../data/repositories/links/link_repository.dart';
import '../data/repositories/maia/maia_repository.dart';
import '../data/repositories/onboarding/onboarding_repository.dart';
import '../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../data/repositories/opponent/opponent_repository.dart';
import '../data/repositories/pace/pace_repository.dart';
import '../data/repositories/photo/photo_repository.dart';
import '../data/repositories/placement/placement_repository.dart';
import '../data/repositories/positions/positions_repository.dart';
import '../data/repositories/profile/profile_repository.dart';
import '../data/repositories/progress/progress_repository.dart';
import '../data/repositories/purchase/opening_offer_repository.dart';
import '../data/repositories/purchase/purchase_repository.dart';
import '../data/repositories/push/push_repository.dart';
import '../data/repositories/race/race_repository.dart';
import '../data/repositories/rating/rating_repository.dart';
import '../data/repositories/review/game_review_repository.dart';
import '../data/repositories/review/review_repository.dart';
import '../data/repositories/school/lesson_repository.dart';
import '../data/repositories/school/lesson_script_repository.dart';
import '../data/repositories/school/school_progress_repository.dart';
import '../data/repositories/school/star_challenge_repository.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/repositories/share/share_repository.dart';
import '../data/repositories/sound/sound_repository.dart';
import '../data/repositories/speedrun/speedrun_repository.dart';
import '../data/repositories/store/store_listing_repository.dart';
import '../data/repositories/survey/survey_repository.dart';
import '../data/repositories/sync/sync_scheduler.dart';
import '../data/repositories/tablebase/kpk_repository.dart';
import '../data/repositories/tablebase/script_table_repository.dart';
import '../data/repositories/training/course_download_repository.dart';
import '../data/repositories/training/course_training_repository.dart'
    as course_training;
import '../data/repositories/training/demo_offer_repository.dart';
import '../data/repositories/training/training_endgame_content.dart';
import '../data/repositories/training/training_history_source.dart';
import '../data/repositories/training/training_repository.dart';
import '../data/repositories/training/training_school_content.dart';
import '../data/repositories/update/app_update_repository.dart';
import '../data/repositories/voice/voice_repository.dart';
import '../data/repositories/week/week_repository.dart';
import '../data/services/preferences_service.dart';
import '../domain/models/app_version.dart';
import '../domain/use_cases/now.dart';
import '../domain/use_cases/position_judge.dart';
import '../domain/use_cases/training/training_analytics.dart';
import '../ui/core/sound/game_haptics.dart';
import '../ui/core/sound/game_sounds.dart';
import 'dependencies.dart';

typedef _Providers = List<RepositoryProvider<Object?>>;

/// Os repositórios do app todo, por área. O [sync] vive com o app.
List<RepositoryProvider<Object?>> appRepositoryProviders(
  Dependencies deps,
  SyncScheduler sync,
) => [
  ..._app(deps),
  ..._account(deps, sync),
  ..._game(deps),
  ..._courses(deps),
  ..._home(deps),
  ..._care(deps),
  ..._store(deps),
];

/// O app em si: relógio, versão, preferências, estatísticas e links.
_Providers _app(Dependencies deps) => [
  RepositoryProvider<Now>.value(value: deps.now),
  RepositoryProvider<AppVersion>.value(value: deps.version),
  RepositoryProvider<AnalyticsRepository>.value(
    value: deps.analyticsRepository,
  ),
  RepositoryProvider<SettingsRepository>.value(value: deps.settingsRepository),
  RepositoryProvider<RemoteFlagsRepository>.value(
    value: deps.remoteFlagsRepository,
  ),
  RepositoryProvider<AppUpdateRepository>.value(
    value: deps.appUpdateRepository,
  ),
  RepositoryProvider<ShareRepository>.value(value: deps.shareRepository),
  RepositoryProvider<DeepLinkRepository>.value(value: deps.deepLinkRepository),
  RepositoryProvider<CampaignRepository>.value(value: deps.campaignRepository),
  RepositoryProvider<DeviceSettingsRepository>.value(
    value: const SystemDeviceSettingsRepository(),
  ),
  RepositoryProvider<LinkRepository>.value(
    value: const UrlLauncherLinkRepository(),
  ),
  RepositoryProvider<LegalRepository>(create: (_) => AssetLegalRepository()),
  RepositoryProvider<LegalConsentRepository>.value(
    value: deps.legalConsentRepository,
  ),
  RepositoryProvider<DataExportRepository>.value(
    value: deps.dataExportRepository,
  ),
];

/// A conta, o perfil, os avisos e o progresso que sobe para a conta.
_Providers _account(Dependencies deps, SyncScheduler sync) => [
  RepositoryProvider<AccountRepository>.value(value: deps.accountRepository),
  RepositoryProvider<AccountInviteRepository>.value(
    value: deps.accountInviteRepository,
  ),
  RepositoryProvider<SyncScheduler>.value(value: sync),
  RepositoryProvider<LichessRepository>.value(value: deps.lichessRepository),
  RepositoryProvider<ChessComRepository>.value(value: deps.chessComRepository),
  RepositoryProvider<PushRepository>.value(value: deps.pushRepository),
  RepositoryProvider<AlertsRepository>.value(value: deps.alertsRepository),
  RepositoryProvider<RegionPromptRepository>.value(
    value: deps.regionPromptRepository,
  ),
  RepositoryProvider<AvatarRepository>.value(value: deps.avatarRepository),
  RepositoryProvider<PhotoRepository>.value(value: deps.photoRepository),
  RepositoryProvider<MailAppRepository>.value(value: deps.mailAppRepository),
  RepositoryProvider<ProfileRepository>.value(value: deps.profileRepository),
  RepositoryProvider<RatingRepository>.value(value: deps.ratingRepository),
  RepositoryProvider<AchievementsRepository>.value(
    value: deps.achievementsRepository,
  ),
  RepositoryProvider<ActivityRepository>.value(value: deps.activityRepository),
  RepositoryProvider<WeekRepository>.value(value: deps.weekRepository),
  RepositoryProvider<OnboardingRepository>.value(
    value: deps.onboardingRepository,
  ),
  RepositoryProvider<PlacementRepository>.value(
    value: deps.placementRepository,
  ),
];

/// A partida: motores, adversários, análise, voz, sons e às cegas.
_Providers _game(Dependencies deps) => [
  RepositoryProvider<OngoingGameRepository>.value(
    value: deps.ongoingGameRepository,
  ),
  RepositoryProvider<PositionsRepository>.value(
    value: deps.positionsRepository,
  ),
  RepositoryProvider<OpponentRepository>.value(value: deps.opponentRepository),
  RepositoryProvider<MaiaRepository>.value(value: deps.maiaRepository),
  RepositoryProvider<PositionJudge>.value(value: deps.engineJudge),
  RepositoryProvider<KpkRepository>.value(value: deps.kpkRepository),
  RepositoryProvider<ScriptTableRepository>.value(
    value: deps.scriptTableRepository,
  ),
  RepositoryProvider<DrawOfferRepository>.value(
    value: deps.drawOfferRepository,
  ),
  RepositoryProvider<ConclusionRepository>.value(
    value: deps.conclusionRepository,
  ),
  RepositoryProvider<ProgressRepository>.value(value: deps.progressRepository),
  RepositoryProvider<JourneyRepository>.value(value: deps.journeyRepository),
  RepositoryProvider<SpeedrunRepository>.value(value: deps.speedrunRepository),
  RepositoryProvider<RaceRepository>.value(value: deps.raceRepository),
  RepositoryProvider<AnalysisRepository>.value(value: deps.analysisRepository),
  RepositoryProvider<LearningAnalysisRepository>(
    create: (_) =>
        deps.learningAnalysisRepository ??
        LearningAnalysisRepository(PreferencesService()),
  ),
  RepositoryProvider<DeepAnalysisRepository>.value(
    value: deps.deepAnalysisRepository,
  ),
  RepositoryProvider<GameReviewRepository>.value(
    value: deps.gameReviewRepository,
  ),
  RepositoryProvider<HapticsRepository>.value(value: deps.hapticsRepository),
  RepositoryProvider<SoundRepository>.value(value: deps.soundRepository),
  // A vibração, já com a preferência de ligada ou desligada.
  RepositoryProvider<GameHaptics>(
    create: (context) =>
        GameHaptics(deps.settingsRepository, deps.hapticsRepository),
  ),
  // Os sons do jogo, já com a preferência de ligado ou desligado.
  RepositoryProvider<GameSounds>(
    create: (context) =>
        GameSounds(deps.settingsRepository, deps.soundRepository),
  ),
  RepositoryProvider<VoiceRepository>.value(value: deps.voiceRepository),
  RepositoryProvider<SpeechInputRepository>.value(
    value: deps.speechInputRepository,
  ),
  RepositoryProvider<BlindCheckpointRepository>.value(
    value: deps.blindCheckpointRepository,
  ),
  RepositoryProvider<BlindLogRepository>.value(value: deps.blindLogRepository),
  RepositoryProvider<CharacterRepository>.value(
    value: deps.characterRepository,
  ),
  RepositoryProvider<EvaluationRepository>.value(
    value: deps.evaluationRepository,
  ),
  RepositoryProvider<TalkRepository>.value(value: deps.talkRepository),
];

/// Os cursos: Escola, aulas de finais, treino diário e o aprendizado.
_Providers _courses(Dependencies deps) => [
  RepositoryProvider<LearningRepository?>.value(value: deps.learningRepository),
  RepositoryProvider<TrainingAnalytics>(
    create: (_) =>
        deps.trainingAnalytics ??
        TrainingAnalytics(now: deps.now, log: deps.analyticsRepository.log),
  ),
  RepositoryProvider<TrainingRepository>.value(value: deps.trainingRepository),
  RepositoryProvider<course_training.TrainingRepository>.value(
    value: deps.courseTrainingRepository,
  ),
  RepositoryProvider<CourseDownloadRepository>.value(
    value: deps.courseDownloads,
  ),
  RepositoryProvider<TrainingSchoolContent>.value(
    value:
        deps.trainingSchoolContent ??
        TrainingSchoolContent(deps.lessonRepository),
  ),
  RepositoryProvider<TrainingHistorySource>.value(
    value: TrainingHistorySource(
      deps.courseTrainingRepository,
      learning: deps.learningRepository,
      now: deps.now,
    ),
  ),
  RepositoryProvider<TrainingEndgameContent?>.value(
    value: deps.trainingEndgameContent,
  ),
  RepositoryProvider<PaceRepository>.value(value: deps.paceRepository),
  RepositoryProvider<LessonRepository>.value(value: deps.lessonRepository),
  RepositoryProvider<LessonScriptRepository>.value(
    value: deps.lessonScriptRepository,
  ),
  RepositoryProvider<SchoolProgressRepository>.value(
    value: deps.schoolProgressRepository,
  ),
  RepositoryProvider<StarChallengeRepository>.value(
    value: deps.starChallengeRepository,
  ),
  RepositoryProvider<EndgameLessonRepository>.value(
    value: deps.endgameLessonRepository,
  ),
  RepositoryProvider<EndgameProgressRepository>.value(
    value: deps.endgameProgressRepository,
  ),
  RepositoryProvider<ExerciseFeedbackRepository>.value(
    value: deps.exerciseFeedbackRepository,
  ),
  RepositoryProvider<DailyFinalRepository>.value(
    value: deps.dailyFinalRepository,
  ),
];

/// O Início: layout, destaques e a prévia dos cursos.
_Providers _home(Dependencies deps) => [
  RepositoryProvider<HomeLayoutRepository>.value(
    value: deps.homeLayoutRepository,
  ),
  RepositoryProvider<FeaturedRepository>.value(value: deps.featuredRepository),
  RepositoryProvider<CoursePreviewRepository>.value(
    value: deps.coursePreviewRepository,
  ),
  RepositoryProvider<FeaturedProgressRepository>.value(
    value: deps.featuredProgressRepository,
  ),
  RepositoryProvider<FeaturedAlertsRepository>.value(
    value: deps.featuredAlertsRepository,
  ),
];

/// A opinião de quem usa: pesquisa, feedback e o pedido de avaliação.
_Providers _care(Dependencies deps) => [
  RepositoryProvider<SurveyRepository>.value(value: deps.surveyRepository),
  RepositoryProvider<FeedbackRepository>.value(value: deps.feedbackRepository),
  RepositoryProvider<FeedbackDraftRepository>.value(
    value: deps.feedbackDraftRepository,
  ),
  RepositoryProvider<ReviewRepository>.value(value: deps.reviewRepository),
];

/// Anúncios, acesso aos cursos e compras.
_Providers _store(Dependencies deps) => [
  RepositoryProvider<AdsRepository>.value(value: deps.adsRepository),
  RepositoryProvider<CourseAccessRepository>.value(
    value: deps.courseAccessRepository,
  ),
  RepositoryProvider<CourseGrantsRepository>.value(
    value: deps.courseGrantsRepository,
  ),
  RepositoryProvider<DemoAdRepository>.value(value: deps.demoAdRepository),
  RepositoryProvider<DemoOfferRepository>.value(
    value: deps.demoOfferRepository,
  ),
  RepositoryProvider<OpeningOfferRepository>.value(
    value: deps.openingOfferRepository,
  ),
  RepositoryProvider<PurchaseRepository>.value(value: deps.purchaseRepository),
  RepositoryProvider<StoreListingRepository>.value(
    value: deps.storeListingRepository,
  ),
];
