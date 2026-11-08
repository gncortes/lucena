import 'dart:async';

import 'package:lucena/data/repositories/settings/settings_repository.dart';
import 'package:lucena/domain/models/app_settings.dart';

/// Preferências só na memória. [saved] guarda tudo o que foi gravado, em ordem.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.settings = const AppSettings()]);

  AppSettings settings;
  final saved = <AppSettings>[];

  /// Quando não nulo, a próxima gravação lança este erro (e nada é gravado).
  Object? saveError;

  /// Gravação lenta: cada `save` espera o próximo destes completers, na ordem.
  /// Vazio: grava na hora.
  final holds = <Completer<void>>[];

  /// Gravações que começaram e ainda não terminaram.
  int running = 0;

  /// Maior número de gravações ao mesmo tempo (duas = gravação misturada).
  int maxRunning = 0;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    running++;
    if (running > maxRunning) maxRunning = running;
    try {
      if (holds.isNotEmpty) await holds.removeAt(0).future;
      final error = saveError;
      if (error != null) {
        saveError = null;
        throw error;
      }
      this.settings = settings;
      saved.add(settings);
    } finally {
      running--;
    }
  }
}
