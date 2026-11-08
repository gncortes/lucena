import '../data/services/ads_service.dart';
import '../data/services/coupon_service.dart';
import '../data/services/dev_store.dart';
import '../data/services/firebase/coupon_functions_service.dart';
import '../data/services/google_ads_service.dart';
import '../data/services/play_purchase_service.dart';
import '../data/services/preferences_service.dart';
import '../data/services/purchase_service.dart';
import '../domain/use_cases/now.dart';
import 'ambiente.dart';

/// A loja e o anúncio de cada ambiente (E1.22), separados da composição para
/// o teste.
///
/// - `dev`: a Play simulada (H-R5-66) e o bloco de teste do AdMob;
/// - `prod`: a Play Billing, as Functions das promoções (com Firebase) e o
///   AdMob com o bloco do CI; sem bloco, sem anúncio.
abstract final class Loja {
  static PurchaseService compras(
    Ambiente ambiente, {
    required PreferencesService preferences,
    required Now now,
  }) => ambiente.isProd
      ? PlayPurchaseService()
      : DevPurchaseService(preferences, now: now);

  static CouponService cupons(
    Ambiente ambiente, {
    required bool firebase,
    required Now now,
  }) => !ambiente.isProd
      ? DevCouponService(now: now)
      : firebase
      ? FirebaseCouponService()
      : const NoCouponService();

  /// O serviço de anúncio, ou [NoAdsService] sem bloco ([interstitialId]
  /// nulo, `prod` sem `ADMOB_INTERSTITIAL_ID`) ou nos cenários do Patrol
  /// ([e2e]). [testAds]: o modo equipe vê o bloco de teste.
  static AdsService anuncios({
    required String? interstitialId,
    bool e2e = false,
    Future<bool> Function()? testAds,
  }) => interstitialId == null || e2e
      ? NoAdsService()
      : GoogleAdsService(interstitialId: interstitialId, testAds: testAds);
}
