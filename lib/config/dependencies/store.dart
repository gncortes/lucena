import 'dart:async';

import '../../data/repositories/ads/ads_repository.dart';
import '../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../data/repositories/lesson_ad/demo_ad_repository.dart';
import '../../data/repositories/purchase/opening_offer_repository.dart';
import '../../data/repositories/purchase/purchase_repository.dart';
import '../../data/repositories/store/store_listing_repository.dart';
import '../../data/repositories/training/demo_offer_repository.dart';
import '../../data/services/dev_store.dart';
import '../../data/services/firebase/course_grants_service.dart';
import '../ambiente.dart';
import 'core.dart';

/// Anúncios, compras e o acesso aos cursos.
class StoreDependencies {
  StoreDependencies._({
    required this.purchases,
    required this.courseGrants,
    required this.courseAccess,
    required this.demoAd,
    required this.demoOffer,
    required this.openingOffer,
    required this.storeListing,
  });

  factory StoreDependencies.create(CoreDependencies core) {
    final now = core.now;
    final preferences = core.preferences;
    final auth = core.auth;
    // A V1 sai sem anúncios nem "Remover anúncios" (decisão do Gabriel,
    // 2026-10-22): o código da E1.25 fica, com os serviços vazios.
    // No flavor dev a Play é simulada (H-R5-66): preço, ofertas com
    // desconto, link e compra com o token de teste, sem trancar o curso.
    final devStore = !Ambiente.atual().isProd;
    final PurchaseRepository purchases = devStore
        ? PlayPurchaseRepository(
            DevPurchaseService(preferences, now: now),
            preferences,
            now: now,
            analytics: core.analytics,
            accountChanges: auth.changes,
            coupons: DevCouponService(now: now),
            uid: core.uid,
          )
        : const NoPurchaseRepository();
    // Sem loja (V1 sem compra) o curso segue aberto; com a Play ligada
    // (H-VEN-16), a lição tranca e mostra o anúncio pela compra.
    final CourseAccessRepository storeAccess =
        devStore || purchases is NoPurchaseRepository
        ? const FullCourseAccessRepository()
        : PurchaseCourseAccessRepository(purchases);
    // O curso dado ou comprado pelo servidor (`acessos/{uid}`, H-R5-61).
    final CourseGrantsRepository courseGrants = core.firebase
        ? CloudCourseGrantsRepository(
            FirestoreCourseGrantsService(),
            preferences,
            uids: auth.changes.map((account) => account?.uid),
            currentUid: core.uid,
            now: now,
          )
        : const NoCourseGrantsRepository();
    unawaited(courseGrants.start());
    return StoreDependencies._(
      purchases: purchases,
      courseGrants: courseGrants,
      courseAccess: ServerCourseAccessRepository(
        storeAccess,
        courseGrants,
        now: now,
      ),
      demoAd: LocalDemoAdRepository(preferences),
      demoOffer: LocalDemoOfferRepository(preferences, now),
      openingOffer: LocalOpeningOfferRepository(preferences, now),
      storeListing: core.firebase
          ? const PlayStoreListingRepository()
          : const NoStoreListingRepository(),
    );
  }

  /// Sem anúncios na V1.
  final AdsRepository ads = const NoAdsRepository();
  final PurchaseRepository purchases;
  final CourseGrantsRepository courseGrants;
  final CourseAccessRepository courseAccess;
  final DemoAdRepository demoAd;
  final DemoOfferRepository demoOffer;
  final OpeningOfferRepository openingOffer;
  final StoreListingRepository storeListing;
}
