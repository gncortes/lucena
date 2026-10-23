import '../../../domain/models/alert_settings.dart';
import '../../services/preferences_service.dart';

/// As chaves de Perfil > Avisos e a hora dos lembretes (E1.21).
abstract class AlertsRepository {
  Future<AlertSettings> load();

  Future<void> save(AlertSettings settings);
}

/// Gravado nas preferências do aparelho, uma chave por opção.
class LocalAlertsRepository implements AlertsRepository {
  LocalAlertsRepository(this._preferences);

  static const _tournamentsKey = 'alerts.tournaments';
  static const _dailyKey = 'alerts.daily';
  static const _newsKey = 'alerts.news';
  static const _lessonsKey = 'alerts.lessons';
  static const _reminderKey = 'alerts.reminderMinutes';

  final PreferencesService _preferences;

  @override
  Future<AlertSettings> load() async {
    const defaults = AlertSettings();
    final reminder = int.tryParse(
      await _preferences.getString(_reminderKey) ?? '',
    );
    return AlertSettings(
      tournaments:
          await _preferences.getBool(_tournamentsKey) ?? defaults.tournaments,
      daily: await _preferences.getBool(_dailyKey) ?? defaults.daily,
      news: await _preferences.getBool(_newsKey) ?? defaults.news,
      lessons: await _preferences.getBool(_lessonsKey) ?? defaults.lessons,
      reminderMinutes: reminder != null && reminder >= 0 && reminder < 24 * 60
          ? reminder
          : defaults.reminderMinutes,
    );
  }

  @override
  Future<void> save(AlertSettings settings) async {
    await _preferences.setBool(_tournamentsKey, value: settings.tournaments);
    await _preferences.setBool(_dailyKey, value: settings.daily);
    await _preferences.setBool(_newsKey, value: settings.news);
    await _preferences.setBool(_lessonsKey, value: settings.lessons);
    await _preferences.setString(_reminderKey, '${settings.reminderMinutes}');
  }
}
