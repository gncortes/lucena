import 'dart:async';

import '../data/repositories/training/course_training_repository.dart'
    as course_training;

import 'dependencies/api_types.dart';
import 'dependencies/normal.dart';
import 'build_flags.dart';

export 'build_flags.dart';

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
    this.learningAnalysisRepository,
    required this.gameReviewRepository,
    required this.deepAnalysisRepository,
    required this.ongoingGameRepository,
    required this.conclusionRepository,
    required this.positionsRepository,
    required this.trainingRepository,
    this.courseTrainingRepository =
        const course_training.NoTrainingRepository(),
    this.courseDownloads = const CourseDownloadRepository.unconfigured(),
    this.trainingAnalytics,
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
    required this.paceRepository,
    required this.lessonRepository,
    this.trainingSchoolContent,
    required this.schoolProgressRepository,
    required this.starChallengeRepository,
    required this.endgameLessonRepository,
    this.trainingEndgameContent,
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
    required this.featuredAlertsRepository,
    this.regionPromptRepository = const NoRegionPromptRepository(),
    this.learningRepository,
    this.requireLessonAccount = false,
    this.syncRepository = const NoSyncRepository(),
    this.accountInviteRepository = const NoAccountInviteRepository(),
    this.avatarRepository = const NoAvatarRepository(),
    this.photoRepository = const NoPhotoRepository(),
    this.mailAppRepository = const NoMailAppRepository(),
    this.analyticsRepository = const NoAnalyticsRepository(),
    this.adsRepository = const NoAdsRepository(),
    this.courseAccessRepository = const FullCourseAccessRepository(),
    this.courseGrantsRepository = const NoCourseGrantsRepository(),
    this.coachRepository = const NoCoachRepository(),
    this.demoAdRepository = const NoDemoAdRepository(),
    this.demoOfferRepository = const NoDemoOfferRepository(),
    this.openingOfferRepository = const NoOpeningOfferRepository(),
    this.purchaseRepository = const NoPurchaseRepository(),
    this.storeListingRepository = const NoStoreListingRepository(),
    this.feedbackRepository = const NoFeedbackRepository(),
    this.dataExportRepository = const NoDataExportRepository(),
    this.legalConsentRepository = const NoLegalConsentRepository(),
    this.feedbackDraftRepository = const NoFeedbackDraftRepository(),
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

  static final _trainingInstallSeeds = TrainingInstallSeedRepository(
    PreferencesService(),
  );

  /// Created once per installation, independently of account and Analytics.
  static Future<String> trainingInstallSeed() => _trainingInstallSeeds.load();

  /// [firebase] diz se o Firebase subiu (`startFirebase`). Sem ele, a conta e
  /// o push ficam desligados e o resto do app funciona igual. [push] troca só
  /// o toque no aviso: os cenários do Patrol no emulador do Firebase
  /// (`testing/emulator_dependencies.dart`) simulam o FCM, que não é emulado;
  /// [pushService] dá a eles um token de mentira (o emulador não registra no
  /// FCM).
  factory Dependencies.normal({
    AppVersion version = const AppVersion(appVersion),
    bool firebase = false,
    String? trainingInstallSeed,
    PushRepository? push,
    PushService? pushService,
  }) => buildNormalDependencies(
    version: version,
    firebase: firebase,
    trainingInstallSeed: trainingInstallSeed,
    push: push,
    pushService: pushService,
  );

  final AppVersion version;

  final Now now;
  final SettingsRepository settingsRepository;
  final ProfileRepository profileRepository;
  final HapticsRepository hapticsRepository;
  final ShareRepository shareRepository;
  final DeepLinkRepository deepLinkRepository;
  final LearningRepository? learningRepository;
  final bool requireLessonAccount;
  final AccountRepository accountRepository;
  final LichessRepository lichessRepository;
  final ChessComRepository chessComRepository;
  final PushRepository pushRepository;
  final AlertsRepository alertsRepository;
  final PlacementRepository placementRepository;
  final SoundRepository soundRepository;
  final AnalysisRepository analysisRepository;
  final LearningAnalysisRepository? learningAnalysisRepository;
  final GameReviewRepository gameReviewRepository;
  final DeepAnalysisRepository deepAnalysisRepository;
  final OngoingGameRepository ongoingGameRepository;
  final ConclusionRepository conclusionRepository;
  final PositionsRepository positionsRepository;
  final TrainingRepository trainingRepository;
  final course_training.TrainingRepository courseTrainingRepository;
  final CourseDownloadRepository courseDownloads;
  final TrainingAnalytics? trainingAnalytics;
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
  final PaceRepository paceRepository;
  final LessonRepository lessonRepository;
  final TrainingSchoolContent? trainingSchoolContent;
  final SchoolProgressRepository schoolProgressRepository;
  final StarChallengeRepository starChallengeRepository;
  final EndgameLessonRepository endgameLessonRepository;
  final TrainingEndgameContent? trainingEndgameContent;
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

  /// O que a pessoa tem do Pilares e o anúncio da demonstração (T85-D1).
  final CourseAccessRepository courseAccessRepository;

  /// Os cursos dados pelo servidor e a tela "Curso liberado" já vista
  /// (H-R5-61/62).
  final CourseGrantsRepository courseGrantsRepository;

  /// O Treinador de partidas: conta ligada, partidas analisadas e o
  /// progresso dos exercícios (T87).
  final CoachRepository coachRepository;
  final DemoAdRepository demoAdRepository;
  final DemoOfferRepository demoOfferRepository;

  /// A oferta do Pilares ao abrir o app (H-INI-14).
  final OpeningOfferRepository openingOfferRepository;
  final PurchaseRepository purchaseRepository;
  final StoreListingRepository storeListingRepository;

  /// "Enviar feedback" (E1.26), em `feedback/{id}`.
  final FeedbackRepository feedbackRepository;

  /// "Baixar meus dados" (H-CON-21): a cópia da conta num JSON.
  final DataExportRepository dataExportRepository;

  /// O aceite dos Termos e da Política logo depois de criar a conta
  /// (H-CON-08).
  final LegalConsentRepository legalConsentRepository;

  /// O rascunho do "Enviar feedback" (H-OPI-11), no aparelho.
  final FeedbackDraftRepository feedbackDraftRepository;

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
