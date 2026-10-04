import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/settings/settings_repository_local.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  // Cada chamada cria repositório e serviço novos, como ao reabrir o app.
  LocalSettingsRepository reopen() =>
      LocalSettingsRepository(PreferencesService());

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('sem nada gravado, segue o idioma do sistema', () async {
    expect(await reopen().load(), const AppSettings());
  });

  test('o idioma gravado volta ao reabrir', () async {
    await reopen().save(const AppSettings(languageCode: 'es'));

    expect(await reopen().load(), const AppSettings(languageCode: 'es'));
  });

  test('voltar para o idioma do sistema apaga o idioma gravado', () async {
    await reopen().save(const AppSettings(languageCode: 'ar'));
    await reopen().save(const AppSettings());

    expect(await reopen().load(), const AppSettings());
  });
}
