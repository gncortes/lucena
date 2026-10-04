import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/haptics/haptics_repository.dart';
import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/data/repositories/settings/settings_repository.dart';
import 'package:lucena/domain/models/app_language.dart';

import 'fakes/fake_haptics_repository.dart';
import 'fakes/fake_now.dart';
import 'fakes/fake_ongoing_game_repository.dart';
import 'fakes/fake_profile_repository.dart';
import 'fakes/fake_settings_repository.dart';

/// Composição dos testes de unidade e de widget: tudo falso, nada toca o aparelho.
Dependencies testDependencies({
  FakeNow? now,
  SettingsRepository? settingsRepository,
  ProfileRepository? profileRepository,
  HapticsRepository? hapticsRepository,
  OngoingGameRepository? ongoingGameRepository,
  List<AppLanguage>? languages,
}) {
  return Dependencies(
    now: now ?? FakeNow(DateTime.utc(2026, 1, 1, 12)),
    settingsRepository: settingsRepository ?? FakeSettingsRepository(),
    profileRepository: profileRepository ?? FakeProfileRepository(),
    hapticsRepository: hapticsRepository ?? FakeHapticsRepository(),
    ongoingGameRepository: ongoingGameRepository ?? FakeOngoingGameRepository(),
    languages: languages ?? AppLanguage.selectable,
  );
}
