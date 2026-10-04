import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository_local.dart';
import 'package:lucena/data/repositories/positions/positions_repository_asset.dart';
import 'package:lucena/data/repositories/profile/profile_repository_local.dart';
import 'package:lucena/data/repositories/settings/settings_repository_local.dart';
import 'package:lucena/data/repositories/training/training_repository_local.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';

import 'fakes/fake_haptics_repository.dart';
import 'fakes/fake_now.dart';

/// O relógio dos cenários: só anda quando o cenário manda.
final e2eNow = FakeNow(_e2eStart);

final _e2eStart = DateTime.utc(2026, 1, 1, 12);

// O banco aberto pelo app em execução: fechado antes de abrir o próximo.
AppDatabase? _database;

/// Composição dos cenários Patrol: relógio controlado e o pseudo-idioma na lista,
/// mas com a gravação de verdade no aparelho (preferências e banco), para os
/// cenários de persistência (reiniciar o app e conferir o dado) valerem.
///
/// Cada chamada fecha o banco da anterior e abre outro, como um app reaberto.
Future<Dependencies> e2eDependencies() async {
  await _database?.close();
  final database = _database = AppDatabase();
  return Dependencies(
    now: e2eNow,
    settingsRepository: LocalSettingsRepository(PreferencesService()),
    profileRepository: LocalProfileRepository(database),
    hapticsRepository: FakeHapticsRepository(),
    ongoingGameRepository: LocalOngoingGameRepository(PreferencesService()),
    // O catálogo de verdade: os cenários abrem posições conhecidas dele.
    positionsRepository: AssetPositionsRepository(const AssetService()),
    trainingRepository: LocalTrainingRepository(PreferencesService()),
    languages: AppLanguage.values,
  );
}

/// Apaga o que os cenários anteriores gravaram: cada cenário começa do zero.
Future<void> resetE2EData() async {
  e2eNow.value = _e2eStart;
  await PreferencesService().clear();
  await _database?.close();
  _database = null;
  final database = AppDatabase();
  await database.deleteEverything();
  await database.close();
}
