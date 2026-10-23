import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/ads/ads_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/ads_state.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_ads_service.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_purchase_service.dart';
import '../../../../testing/fakes/fake_remote_flags_repository.dart';

/// Os eventos da E1.03 no consentimento e no pedido de anúncio (E1.25).
void main() {
  late FakeAdsService service;
  late FakeAnalyticsRepository analytics;
  late FakePurchaseRepository purchases;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = FakeAdsService();
    analytics = FakeAnalyticsRepository();
    purchases = FakePurchaseRepository();
  });

  Future<ServiceAdsRepository> session() async {
    final ads = ServiceAdsRepository(
      service: service,
      preferences: PreferencesService(),
      flags: FakeRemoteFlagsRepository(
        adsEnabled: true,
        adsFreeLessons: 1,
        adsMinGapSeconds: 180,
      ),
      purchases: purchases,
      now: FakeNow(DateTime.utc(2026, 10, 22, 10)),
      analytics: analytics,
    );
    await ads.start(fromLink: false, goalAnswered: true);
    await pumpEventQueue();
    return ads;
  }

  Future<AdOutcome> lesson(ServiceAdsRepository ads, String id) =>
      ads.beforeLesson(lessonId: id, kind: LessonKind.endgame);

  test('o consentimento conta o resultado e manda o Consent Mode', () async {
    await session();
    expect(analytics.eventsNamed('anuncio_consentimento').single.params, {
      'resultado': 'obtido',
      'origem': 'primeira_abertura',
    });
    expect(analytics.consent, (analytics: true, ads: true));
  });

  test('negado na janela de privacidade', () async {
    final ads = await session();
    service.consent = false;
    await ads.showPrivacyOptions();
    expect(analytics.eventsNamed('anuncio_consentimento').last.params, {
      'resultado': 'negado',
      'origem': 'privacidade',
    });
    expect(analytics.consent, (analytics: false, ads: false));
  });

  test('cada pedido conta o motivo, nunca o "desligado"', () async {
    await session();
    final ads = await session();
    await lesson(ads, 'a');
    await lesson(ads, 'b');
    await lesson(ads, 'c');
    final asked = analytics.eventsNamed('anuncio_pedido');
    expect(
      [for (final event in asked) event.params['resultado']],
      ['carencia', 'ok', 'intervalo'],
    );
    expect(asked[1].params, {
      'resultado': 'ok',
      'aula_id': 'b',
      'licoes_abertas': 2,
    });
  });

  test('sem anúncios comprado conta como comprado', () async {
    purchases.state = const PurchaseState(adFree: true);
    await session();
    final ads = await session();
    await lesson(ads, 'a');
    await lesson(ads, 'b');
    expect(
      analytics.eventsNamed('anuncio_pedido').last.params['resultado'],
      'comprado',
    );
  });
}
