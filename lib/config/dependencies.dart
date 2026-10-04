import '../data/repositories/haptics/haptics_repository.dart';
import '../data/repositories/haptics/haptics_repository_device.dart';
import '../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../data/repositories/ongoing_game/ongoing_game_repository_local.dart';
import '../data/repositories/opponent/opponent_repository.dart';
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
import '../data/services/preferences_service.dart';
import '../data/services/stockfish_service.dart';
import '../data/services/vibration_service.dart';
import '../domain/models/app_language.dart';
import '../domain/use_cases/now.dart';

/// Ligado por `--dart-define=E2E=true` nos cenários Patrol.
const isE2E = bool.fromEnvironment('E2E');

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
    required this.progressRepository,
    required this.languages,
  });

  factory Dependencies.normal() {
    final preferences = PreferencesService();
    final database = AppDatabase();
    return Dependencies(
      now: const SystemNow(),
      settingsRepository: LocalSettingsRepository(preferences),
      profileRepository: LocalProfileRepository(database),
      hapticsRepository: const DeviceHapticsRepository(VibrationService()),
      ongoingGameRepository: LocalOngoingGameRepository(preferences),
      positionsRepository: AssetPositionsRepository(const AssetService()),
      trainingRepository: LocalTrainingRepository(preferences),
      opponentRepository: StockfishOpponentRepository(StockfishService()),
      progressRepository: LocalProgressRepository(database),
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
  final ProgressRepository progressRepository;

  /// Idiomas oferecidos em Configurações.
  final List<AppLanguage> languages;
}
