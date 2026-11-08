import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/ambiente.dart';
import 'package:lucena/config/loja.dart';
import 'package:lucena/data/services/ads_service.dart';
import 'package:lucena/data/services/coupon_service.dart';
import 'package:lucena/data/services/dev_store.dart';
import 'package:lucena/data/services/firebase/coupon_functions_service.dart';
import 'package:lucena/data/services/google_ads_service.dart';
import 'package:lucena/data/services/play_purchase_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../testing/fakes/fake_now.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('compras', () {
    test('dev: a Play simulada', () {
      final service = Loja.compras(
        Ambiente.dev,
        preferences: PreferencesService(),
        now: FakeNow(DateTime(2026, 11, 8)),
      );
      expect(service, isA<DevPurchaseService>());
    });

    test('prod: a Play Billing', () {
      final service = Loja.compras(
        Ambiente.prod,
        preferences: PreferencesService(),
        now: FakeNow(DateTime(2026, 11, 8)),
      );
      expect(service, isA<PlayPurchaseService>());
    });
  });

  group('cupons', () {
    test('dev: as promoções simuladas, com ou sem Firebase', () {
      for (final firebase in [true, false]) {
        expect(
          Loja.cupons(
            Ambiente.dev,
            firebase: firebase,
            now: FakeNow(DateTime(2026, 11, 8)),
          ),
          isA<DevCouponService>(),
        );
      }
    });

    test('prod com Firebase: as Cloud Functions', () {
      expect(
        Loja.cupons(
          Ambiente.prod,
          firebase: true,
          now: FakeNow(DateTime(2026, 11, 8)),
        ),
        isA<FirebaseCouponService>(),
      );
    });

    test('prod sem Firebase: sem servidor de promoções', () {
      expect(
        Loja.cupons(
          Ambiente.prod,
          firebase: false,
          now: FakeNow(DateTime(2026, 11, 8)),
        ),
        isA<NoCouponService>(),
      );
    });
  });

  group('anúncios', () {
    test('dev: o AdMob com o bloco de teste', () {
      final id = AdMob.interstitialId(define: '', ambiente: Ambiente.dev);
      expect(Loja.anuncios(interstitialId: id), isA<GoogleAdsService>());
    });

    test('prod com o bloco do CI: o AdMob', () {
      final id = AdMob.interstitialId(
        define: 'ca-app-pub-1/2',
        ambiente: Ambiente.prod,
      );
      expect(Loja.anuncios(interstitialId: id), isA<GoogleAdsService>());
    });

    test('prod sem o bloco do CI: sem anúncio', () {
      final id = AdMob.interstitialId(define: '', ambiente: Ambiente.prod);
      expect(Loja.anuncios(interstitialId: id), isA<NoAdsService>());
    });

    test('cenários do Patrol: sem anúncio', () {
      expect(
        Loja.anuncios(interstitialId: AdMob.testInterstitialId, e2e: true),
        isA<NoAdsService>(),
      );
    });
  });
}
