import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/ads/ads_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_ads_service.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/fakes/fake_remote_flags_repository.dart';

void main() {
  late FakeAdsService service;
  late FakePurchaseRepository purchases;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = FakeAdsService();
    purchases = FakePurchaseRepository();
  });

  PrivacyCubit cubit({FakeAccountRepository? accounts}) => PrivacyCubit(
    ads: ServiceAdsRepository(
      service: service,
      preferences: PreferencesService(),
      flags: FakeRemoteFlagsRepository(),
      purchases: purchases,
      now: FakeNow(DateTime.utc(2026, 10, 22)),
    ),
    purchases: purchases,
    accounts: accounts ?? FakeAccountRepository(),
  );

  test('fora da região que exige, sem "Escolhas de anúncios"', () async {
    final privacy = cubit();
    await privacy.load();
    expect(privacy.state.ready, isTrue);
    expect(privacy.state.showsAdChoices, isFalse);
    expect(privacy.state.hasAccount, isFalse);
    await privacy.close();
  });

  test('onde o Google exige, a linha aparece e reabre a janela', () async {
    service.optionsRequired = true;
    final privacy = cubit(
      accounts: FakeAccountRepository(account: FakeAccountRepository.google),
    );
    await privacy.load();
    expect(privacy.state.showsAdChoices, isTrue);
    expect(privacy.state.hasAccount, isTrue);
    await privacy.openAdChoices();
    expect(service.privacyOptionsShown, 1);
    await privacy.close();
  });

  test('depois da compra, o cartão vira "Sem anúncios"', () async {
    service.optionsRequired = true;
    final privacy = cubit();
    await privacy.load();
    purchases.state = const PurchaseState(adFree: true);
    await pumpEventQueue();
    expect(privacy.state.adFree, isTrue);
    expect(privacy.state.showsAdChoices, isFalse);
    await privacy.close();
  });
}
