import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/purchase/purchase_repository.dart';
import '../../ui/core/analytics/analytics_context.dart';
import '../../ui/pilares_sale/view_models/pilares_prices_cubit.dart';
import '../../ui/pilares_sale/widgets/pilares_subscription_ended_screen.dart';
import '../../ui/pilares_sale/view_models/pilares_offer_cubit.dart';
import '../../ui/pilares_sale/view_models/pilares_restore_cubit.dart';
import '../../ui/pilares_sale/widgets/pilares_offer_screen.dart';
import '../../ui/pilares_sale/widgets/pilares_purchase_result_screens.dart';
import '../../ui/pilares_sale/widgets/pilares_restore_screen.dart';
import '../route_names.dart';
import '../router.dart' show appRoute;

import '../../domain/models/pilares_access.dart';
import '../../domain/models/training/training_course.dart';
import '../routes.dart';

/// Telas novas da frente D2 (Venda + Conta + Ajustes, T85). A frente registra as rotas na
/// lista [d2Routes] com `appRoute(name: RouteNames.x, path: D2Paths.x, ...)`,
/// do `router.dart`, e navega por nome. Só esta frente mexe neste arquivo.
abstract final class D2Paths {
  /// Apresentação do Pilares (H-VEN-14).
  static const pilaresPresentation = '/pilares';

  /// Para quem é, a faixa (H-VEN-02).
  static const pilaresForWhom = '/pilares/for-whom';

  /// Sobre o Pilares, 3 abas (H-VEN-03).
  static const pilaresAbout = '/pilares/about';

  /// Fim da demonstração (H-VEN-04).
  static const pilaresDemoEnd = '/pilares/demo-end';

  /// Oferta vitalício/mensal (H-VEN-05).
  static const pilaresOffer = '/pilares/offer';

  /// Compra processando (H-VEN-07).
  static const pilaresPurchaseProcessing = '/pilares/purchase/processing';

  /// Compra concluída (H-VEN-07).
  static const pilaresPurchaseDone = '/pilares/purchase/done';

  /// Compra pendente (H-VEN-08).
  static const pilaresPurchasePending = '/pilares/purchase/pending';

  /// Restaurar compra (H-VEN-09).
  static const pilaresRestore = '/pilares/restore';

  /// "Comprou pelo site?", entrar com a conta da compra (H-VEN-08).
  static const pilaresRestoreSite = '/pilares/restore/site';

  /// Já tem o curso (H-VEN-09).
  static const pilaresOwned = '/pilares/owned';

  /// Assinatura encerrada (H-VEN-10).
  static const pilaresSubscriptionEnded = '/pilares/subscription-ended';

  /// Oferta antes do Início, variante A (H-VEN-15).
  static const pilaresBeforeHome = '/pilares/before-home';

  /// Plano como venda (H-VEN-14).
  static const pilaresPlan = '/pilares/plan';

  /// Esqueci a senha (H-CON-08).
  static const accountForgot = '/conta/esqueci-senha';

  /// Aceite dos Termos (H-CON-09).
  static const accountTerms = '/conta/termos';

  /// Convite por link, tela cheia com X (H-CON-18).
  static const accountInvite = '/conta/convite';

  /// Compra exige conta (H-CON-19).
  static const accountRequired = '/conta/exige';

  /// Perfil Lichess / Chess.com (H-CON-20).
  static const accountExternal = '/conta/externo/:site';

  /// A oferta com o plano marcado (o vitalício, sem `plano`) e a origem
  /// do analytics.
  static String offer({
    PilaresPlan plan = PilaresPlan.lifetime,
    String? origin,
  }) => Uri(
    path: pilaresOffer,
    queryParameters: {
      if (plan == PilaresPlan.monthly) 'plano': plan.analytics,
      'origem': ?origin,
    },
  ).toString();

  /// O plano da query da oferta (`plano=mensal`).
  static PilaresPlan planOf(String? value) =>
      value == PilaresPlan.monthly.analytics
      ? PilaresPlan.monthly
      : PilaresPlan.lifetime;

  /// "Seu objetivo" do Pilares (H-TRE-06, rota da D4).
  static String get pilaresGoal =>
      '${Routes.training(TrainingCourse.pilares.name)}/goal';
}

PilaresRestoreCubit _restoreCubit(BuildContext context) => PilaresRestoreCubit(
  purchases: context.read<PurchaseRepository>(),
  accounts: context.read<AccountRepository>(),
  analytics: context.analytics,
);

final List<RouteBase> d2Routes = [
  // A oferta (H-VEN-03): `plano=mensal` marca o mensal; `origem` vai ao
  // analytics.
  appRoute(
    name: RouteNames.pilaresOffer,
    path: D2Paths.pilaresOffer,
    builder: (context, state) => BlocProvider(
      create: (context) => PilaresOfferCubit(
        purchases: context.read<PurchaseRepository>(),
        accounts: context.read<AccountRepository>(),
        analytics: context.analytics,
        plan: D2Paths.planOf(state.uri.queryParameters['plano']),
        origin: state.uri.queryParameters['origem'] ?? 'perfil',
      ),
      child: const PilaresOfferScreen(),
    ),
  ),
  appRoute(
    name: RouteNames.pilaresPurchaseDone,
    path: D2Paths.pilaresPurchaseDone,
    builder: (context, state) => const PilaresPurchaseDoneScreen(),
  ),
  appRoute(
    name: RouteNames.pilaresPurchasePending,
    path: D2Paths.pilaresPurchasePending,
    builder: (context, state) => const PilaresPurchasePendingScreen(),
  ),
  appRoute(
    name: RouteNames.pilaresRestore,
    path: D2Paths.pilaresRestore,
    builder: (context, state) => BlocProvider(
      create: _restoreCubit,
      child: const PilaresRestoreScreen(),
    ),
  ),
  // "Comprou pelo site?" usa o view model da Restaurar que a abriu; aberta
  // sozinha (fechou à força), um novo.
  appRoute(
    name: RouteNames.pilaresRestoreSite,
    path: D2Paths.pilaresRestoreSite,
    builder: (context, state) => switch (state.extra) {
      final PilaresRestoreCubit cubit => BlocProvider.value(
        value: cubit,
        child: const PilaresRestoreSiteScreen(),
      ),
      _ => BlocProvider(
        create: _restoreCubit,
        child: const PilaresRestoreSiteScreen(),
      ),
    },
  ),
  appRoute(
    name: RouteNames.pilaresSubscriptionEnded,
    path: D2Paths.pilaresSubscriptionEnded,
    builder: (context, state) => BlocProvider(
      create: (context) =>
          PilaresPricesCubit(purchases: context.read<PurchaseRepository>()),
      child: const PilaresSubscriptionEndedScreen(),
    ),
  ),
];
