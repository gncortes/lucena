import 'package:flutter/widgets.dart';

/// A venda do Pilares (T85, Venda): oferta, compra, restaurar, assinatura
/// encerrada e o cartão do curso no Perfil.
abstract final class PurchaseKeys {
  /// A oferta (H-VEN-03).
  static const offerScreen = Key('purchase.offer');
  static const planLifetime = Key('purchase.offer.planLifetime');
  static const planMonthly = Key('purchase.offer.planMonthly');
  static const planBest = Key('purchase.offer.planBest');
  static const subscriptionInfo = Key('purchase.offer.subscriptionInfo');
  static const buy = Key('purchase.offer.buy');
  static const restore = Key('purchase.offer.restore');

  /// Os avisos da compra que não terminou (H-VEN-06).
  static const errorBanner = Key('purchase.error.banner');
  static const offlineBanner = Key('purchase.offline.banner');
  static const canceled = Key('purchase.snackbar.cancelled');

  /// Concluída (H-VEN-05) e Pendente (H-VEN-06).
  static const doneScreen = Key('purchase.done');
  static const doneTitle = Key('purchase.done.title');
  static const doneGoal = Key('purchase.done.goal');
  static const doneSeeCourse = Key('purchase.done.seeCourse');
  static const pendingScreen = Key('purchase.pending');
  static const pendingOk = Key('purchase.pending.ok');

  /// Restaurar compra (H-VEN-08).
  static const restoreScreen = Key('purchase.restore');
  static const restoreEmail = Key('purchase.restore.email');
  static const restoreSearch = Key('purchase.restore.search');
  static const restoreNotFound = Key('purchase.restore.notFound');
  static const restoreOtherAccount = Key('purchase.restore.otherAccount');
  static const restoreSeeFull = Key('purchase.restore.seeFull');
  static const restoredScreen = Key('purchase.restore.done');
  static const restoredText = Key('purchase.restore.done.text');
  static const restoredContinue = Key('purchase.restore.done.continue');
  static const restoredGoal = Key('purchase.restore.done.goal');
  static const siteScreen = Key('purchase.restore.site');
  static const siteGoogle = Key('purchase.restore.site.google');
  static const siteEmail = Key('purchase.restore.site.email');

  /// Assinatura encerrada (H-VEN-10).
  static const endedScreen = Key('subscription.ended');
  static const endedRenew = Key('subscription.ended.renew');
  static const endedLifetime = Key('subscription.ended.lifetime');

  /// O cartão do curso no Perfil (H-VEN-04/09).
  static const courseCard = Key('profile.course');
  static const courseBadge = Key('profile.course.badge');
  static const courseSeeFull = Key('profile.course.seeFull');
  static const courseLine = Key('profile.course.line');
  static const courseSubscription = Key('profile.course.subscription');
  static const courseGrace = Key('profile.course.grace');
  static const courseManage = Key('profile.course.manage');
  static const courseFixPayment = Key('profile.course.fixPayment');
  static const courseDetails = Key('profile.course.details');
  static const courseRestore = Key('profile.course.restore');

  // Fim da demonstração (H-VEN-04, PropV2DemoOferta).
  static const demoEndScreen = Key('demo.offer');
  static const demoEndPrice = Key('demo.offer.price');
  static const demoEndSeeOptions = Key('demo.offer.seeOptions');
  static const demoEndLater = Key('demo.offer.later');

  // Oferta antes do Início (H-VEN-15, PropV2OfertaAntesInicio).
  static const beforeHomeSheet = Key('offer.beforeHome');
  static const beforeHomeClose = Key('offer.beforeHome.close');
  static const beforeHomeLearn = Key('offer.beforeHome.learn');

  // Plano como venda (H-VEN-14, PropV2VendaPlano).
  static const planSaleScreen = Key('pilares.plan');
  static const planSaleChapters = Key('pilares.plan.chapters');
  static const planSaleCompare = Key('pilares.plan.compare');
  static const planSaleStart = Key('pilares.plan.start');
  static const planSaleFull = Key('pilares.plan.full');

  // Catálogo da demonstração (H-VEN-11, PropV2DemoCatalogoCompra).
  static const demoCatalogBanner = Key('demo.catalog.banner');
  static Key demoCatalogLockedChapter(int number) =>
      Key('demo.catalog.lockedChapter.$number');
  static const demoCatalogLearnMore = Key('demo.catalog.learnMore');

  // Guia, Metas e Estatísticas da demonstração (H-VEN-12).
  static const demoGuide = Key('demo.guide');
  static const demoGuideLearnMore = Key('demo.guide.learnMore');
  static const demoGuidePlan = Key('demo.guide.plan');
  static Key demoGoalsLockedTile(String kind, String ref) =>
      Key('demo.goals.lockedTile.$kind.$ref');
  static const demoGoalsLearnMore = Key('demo.goals.learnMore');
  static const demoGoalsLockSheet = Key('demo.goals.lockSheet');
  static const demoGoalsLockSheetLearn = Key('demo.goals.lockSheet.learn');
  static const demoGoalsLockSheetLater = Key('demo.goals.lockSheet.later');
  static const demoStatsLearnMore = Key('demo.stats.learnMore');
}
