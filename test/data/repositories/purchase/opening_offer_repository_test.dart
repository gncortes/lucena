import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/purchase/opening_offer_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_now.dart';

/// H-INI-14 / H-VEN-15: o contador da oferta ao abrir o app.
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('começa sem nenhuma vez e grava vezes e a última data nas chaves '
      'venda.oferta.*', () async {
    final now = FakeNow(DateTime(2026, 11, 4, 9));
    final preferences = PreferencesService();
    final repository = LocalOpeningOfferRepository(preferences, now);
    expect((await repository.load()).count, 0);

    await repository.markShown();

    expect(await preferences.getString('venda.oferta.vezes'), '1');
    expect(
      await preferences.getString('venda.oferta.ultima'),
      DateTime(2026, 11, 4, 9).toIso8601String(),
    );
    // Outro processo (o app reaberto) lê o mesmo contador.
    final reopened = LocalOpeningOfferRepository(preferences, now);
    final state = await reopened.load();
    expect(state.count, 1);
    expect(state.lastShown, DateTime(2026, 11, 4, 9));
    expect(reopened.shownThisOpening, isFalse);
    expect(repository.shownThisOpening, isTrue);
  });

  test('o tour marca só esta abertura (fica em memória)', () async {
    final now = FakeNow(DateTime(2026, 11, 4, 9));
    final preferences = PreferencesService();
    final repository = LocalOpeningOfferRepository(preferences, now);
    expect(repository.tourThisOpening, isFalse);
    repository.markTour();
    expect(repository.tourThisOpening, isTrue);
    expect(
      LocalOpeningOfferRepository(preferences, now).tourThisOpening,
      isFalse,
    );
  });

  test('valor ilegível conta como nenhuma vez', () async {
    final preferences = PreferencesService();
    await preferences.setString('venda.oferta.vezes', 'x');
    await preferences.setString('venda.oferta.ultima', 'ontem');
    final state = await LocalOpeningOfferRepository(
      preferences,
      FakeNow(DateTime(2026, 11, 4)),
    ).load();
    expect(state.count, 0);
    expect(state.lastShown, isNull);
  });
}
