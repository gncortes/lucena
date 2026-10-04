import '../../../domain/models/app_settings.dart';

/// Fonte da verdade das preferências do app.
abstract class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
