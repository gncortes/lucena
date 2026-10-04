import '../../../domain/models/app_settings.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../services/preferences_service.dart';
import 'settings_repository.dart';

/// Preferências gravadas no aparelho.
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._preferences);

  static const _languageKey = 'settings.language';
  static const _themeKey = 'settings.theme';

  final PreferencesService _preferences;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      languageCode: await _preferences.getString(_languageKey),
      themeMode: AppThemeMode.fromCode(await _preferences.getString(_themeKey)),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final languageCode = settings.languageCode;
    if (languageCode == null) {
      await _preferences.remove(_languageKey);
    } else {
      await _preferences.setString(_languageKey, languageCode);
    }
    await _preferences.setString(_themeKey, settings.themeMode.code);
  }
}
