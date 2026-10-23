import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/alerts/alerts_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  LocalAlertsRepository reopen() => LocalAlertsRepository(PreferencesService());

  test('sem nada gravado: as de fábrica', () async {
    expect(await reopen().load(), const AlertSettings());
  });

  test('cada chave e a hora voltam ao reabrir', () async {
    const settings = AlertSettings(
      tournaments: false,
      news: true,
      lessons: false,
      reminderMinutes: 8 * 60 + 30,
    );
    await reopen().save(settings);

    expect(await reopen().load(), settings);
  });
}
