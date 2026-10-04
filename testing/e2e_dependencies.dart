import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/profile/profile_repository_local.dart';
import 'package:lucena/data/repositories/settings/settings_repository_local.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';

import 'fakes/fake_now.dart';

// O banco aberto pelo app em execução: fechado antes de abrir o próximo.
AppDatabase? _database;

/// Composição dos cenários Patrol: relógio controlado e o pseudo-idioma na lista,
/// mas com a gravação de verdade no aparelho (preferências e banco), para os
/// cenários de persistência (reiniciar o app e conferir o dado) valerem.
///
/// Cada chamada fecha o banco da anterior e abre outro, como um app reaberto.
Future<Dependencies> e2eDependencies({FakeNow? now}) async {
  await _database?.close();
  final database = _database = AppDatabase();
  return Dependencies(
    now: now ?? FakeNow(DateTime.utc(2026, 1, 1, 12)),
    settingsRepository: LocalSettingsRepository(PreferencesService()),
    profileRepository: LocalProfileRepository(database),
    languages: AppLanguage.values,
  );
}

/// Apaga o que os cenários anteriores gravaram: cada cenário começa do zero.
Future<void> resetE2EData() async {
  await PreferencesService().clear();
  await _database?.close();
  _database = null;
  final database = AppDatabase();
  await database.deleteEverything();
  await database.close();
}
