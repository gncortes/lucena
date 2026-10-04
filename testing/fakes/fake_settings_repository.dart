import 'package:lucena/data/repositories/settings/settings_repository.dart';
import 'package:lucena/domain/models/app_settings.dart';

/// Preferências só na memória. [saved] guarda tudo o que foi gravado, em ordem.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.settings = const AppSettings()]);

  AppSettings settings;
  final saved = <AppSettings>[];

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
    saved.add(settings);
  }
}
