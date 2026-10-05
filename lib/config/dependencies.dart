import 'package:flutter/foundation.dart';

import '../data/repositories/haptics/haptics_repository.dart';
import '../data/repositories/rating/rating_repository.dart';
import '../data/repositories/achievements/achievements_repository.dart';
import '../data/repositories/characters/character_repository.dart';
import '../data/repositories/evaluation/evaluation_repository.dart';
import '../data/repositories/characters/talk_repository.dart';
import '../data/repositories/onboarding/onboarding_repository.dart';
import '../data/repositories/pace/pace_repository.dart';
import '../data/repositories/rating/rating_repository_local.dart';
import '../data/repositories/achievements/achievements_repository_local.dart';
import '../data/repositories/characters/character_repository_asset.dart';
import '../data/repositories/evaluation/evaluation_repository_stockfish.dart';
import '../data/repositories/journey/journey_repository.dart';
import '../data/repositories/journey/journey_repository_asset.dart';
import '../data/repositories/speedrun/speedrun_repository.dart';
import '../data/repositories/speedrun/speedrun_repository_local.dart';
import '../data/repositories/haptics/haptics_repository_device.dart';
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
import '../domain/models/app_language.dart';
import '../domain/use_cases/now.dart';

/// Ligado por `--dart-define=E2E=true` nos cenários Patrol.
const isE2E = bool.fromEnvironment('E2E');

/// A versão do app (`0.3.2-rc.1`), passada pelo CI ao montar o APK assinado.
/// Vazia nos builds locais.
const appVersion = String.fromEnvironment('APP_VERSION');

/// As telas de desenvolvimento aparecem nos builds de depuração, nos cenários
/// Patrol e nas candidatas de QA (`-rc`); nunca na versão final.
bool get showsDevTools => kDebugMode || isE2E || appVersion.contains('-rc');

/// As implementações que entram no app.
///
/// As composições de teste ficam em `testing/`: código de `lib/` não importa
/// `testing/`.
class Dependencies {
  const Dependencies({
    required this.now,
    required this.settingsRepository,
    required this.profileRepository,
    required this.hapticsRepository,
    required this.ongoingGameRepository,
    required this.positionsRepository,
    required this.trainingRepository,
    required this.opponentRepository,
    required this.maiaRepository,
    required this.progressRepository,
    required this.journeyRepository,
    required this.speedrunRepository,
    required this.ratingRepository,
    required this.achievementsRepository,
    required this.characterRepository,
    required this.evaluationRepository,
    required this.talkRepository,
    required this.onboardingRepository,
    required this.paceRepository,
    required this.languages,
  });

  factory Dependencies.normal() {
    final preferences = PreferencesService();
    final database = AppDatabase();
    const now = SystemNow();
    const assets = AssetService();
    final positions = AssetPositionsRepository(assets);
    final maia = MaiaService(() => assets.loadBytes(MaiaService.weightsAsset));
    final stockfish = StockfishService();
    final pace = AssetPaceRepository(assets);
    final profile = LocalProfileRepository(database);
    final maiaRepository = DeviceMaiaRepository(maia);
    return Dependencies(
      now: now,
      settingsRepository: LocalSettingsRepository(preferences),
      profileRepository: profile,
      hapticsRepository: const DeviceHapticsRepository(VibrationService()),
      ongoingGameRepository: LocalOngoingGameRepository(preferences),
      positionsRepository: positions,
      trainingRepository: LocalTrainingRepository(preferences),
      opponentRepository: DeviceOpponentRepository(
        maia: MaiaOpponentRepository(maia, now: now, pace: pace),
        stockfish: StockfishOpponentRepository(stockfish),
      ),
      maiaRepository: maiaRepository,
      progressRepository: LocalProgressRepository(database),
      journeyRepository: AssetJourneyRepository(assets, positions),
      speedrunRepository: LocalSpeedrunRepository(database),
      ratingRepository: LocalRatingRepository(
        database,
        maia: maiaRepository,
        profile: profile,
        now: now,
      ),
      achievementsRepository: LocalAchievementsRepository(assets, database),
      characterRepository: AssetCharacterRepository(assets),
      // O mesmo Stockfish do adversário: contra o Maia ele está livre.
      evaluationRepository: StockfishEvaluationRepository(stockfish),
      talkRepository: LocalTalkRepository(preferences),
      onboardingRepository: LocalOnboardingRepository(preferences),
      paceRepository: pace,
      languages: AppLanguage.selectable,
    );
  }

  final Now now;
  final SettingsRepository settingsRepository;
  final ProfileRepository profileRepository;
  final HapticsRepository hapticsRepository;
  final OngoingGameRepository ongoingGameRepository;
  final PositionsRepository positionsRepository;
  final TrainingRepository trainingRepository;
  final OpponentRepository opponentRepository;
  final MaiaRepository maiaRepository;
  final ProgressRepository progressRepository;
  final JourneyRepository journeyRepository;
  final SpeedrunRepository speedrunRepository;
  final RatingRepository ratingRepository;
  final AchievementsRepository achievementsRepository;
  final CharacterRepository characterRepository;
  final EvaluationRepository evaluationRepository;
  final TalkRepository talkRepository;
  final OnboardingRepository onboardingRepository;
  final PaceRepository paceRepository;

  /// Idiomas oferecidos em Configurações.
  final List<AppLanguage> languages;
}
