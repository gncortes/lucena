import '../data/repositories/haptics/haptics_repository.dart';
import '../data/repositories/haptics/haptics_repository_device.dart';
import '../data/repositories/profile/profile_repository.dart';
import '../data/repositories/profile/profile_repository_local.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/repositories/settings/settings_repository_local.dart';
import '../data/services/database/app_database.dart';
import '../data/services/preferences_service.dart';
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
    required this.languages,
  });

  factory Dependencies.normal() {
    return Dependencies(
      now: const SystemNow(),
      settingsRepository: LocalSettingsRepository(PreferencesService()),
      profileRepository: LocalProfileRepository(AppDatabase()),
      hapticsRepository: const DeviceHapticsRepository(VibrationService()),
      languages: AppLanguage.selectable,
    );
  }

  final Now now;
  final SettingsRepository settingsRepository;
  final ProfileRepository profileRepository;
  final HapticsRepository hapticsRepository;

  /// Idiomas oferecidos em Configurações.
  final List<AppLanguage> languages;
}
