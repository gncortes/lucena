import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/settings/settings_repository_local.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';

import 'fakes/fake_now.dart';

/// Composição dos cenários Patrol: relógio controlado e o pseudo-idioma na lista,
/// mas com a gravação de verdade no aparelho, para os cenários de persistência
/// (reiniciar o app e conferir o dado) valerem.
Dependencies e2eDependencies({FakeNow? now}) {
  return Dependencies(
    now: now ?? FakeNow(DateTime.utc(2026, 1, 1, 12)),
    settingsRepository: LocalSettingsRepository(PreferencesService()),
    languages: AppLanguage.values,
  );
}

/// Apaga o que os cenários anteriores gravaram: cada cenário começa do zero.
Future<void> resetE2EData() => PreferencesService().clear();
