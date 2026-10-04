import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/profile/profile_repository_local.dart';
import 'package:lucena/data/repositories/settings/settings_repository_local.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../testing/fakes/fake_now.dart';
import '../../testing/fakes/fake_profile_repository.dart';
import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/test_dependencies.dart';

void main() {
  test('composição normal: relógio do sistema, gravação no aparelho e sem '
      'pseudo-idioma', () {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    final dependencies = Dependencies.normal();

    expect(dependencies.now, isA<SystemNow>());
    expect(dependencies.settingsRepository, isA<LocalSettingsRepository>());
    expect(dependencies.profileRepository, isA<LocalProfileRepository>());
    expect(dependencies.languages, isNot(contains(AppLanguage.pseudo)));
    expect(dependencies.languages, hasLength(20));
  });

  test('composição de teste: relógio que só anda quando o teste manda', () {
    final dependencies = testDependencies();
    final now = dependencies.now as FakeNow;
    final inicio = now();

    expect(now(), inicio);

    now.advance(const Duration(seconds: 5));

    expect(dependencies.now().difference(inicio), const Duration(seconds: 5));
    expect(dependencies.settingsRepository, isA<FakeSettingsRepository>());
    expect(dependencies.profileRepository, isA<FakeProfileRepository>());
  });
}
