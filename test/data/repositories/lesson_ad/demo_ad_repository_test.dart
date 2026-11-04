import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_ad/demo_ad_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('o aviso aparece uma vez e sobrevive a reabrir o app', () async {
    var repo = LocalDemoAdRepository(PreferencesService());
    expect(await repo.noticeSeen(), isFalse);
    await repo.markNoticeSeen();
    repo = LocalDemoAdRepository(PreferencesService());
    expect(await repo.noticeSeen(), isTrue);
  });

  test('o anúncio da V1 sempre carrega', () async {
    expect(await LocalDemoAdRepository(PreferencesService()).load(), isTrue);
  });
}
