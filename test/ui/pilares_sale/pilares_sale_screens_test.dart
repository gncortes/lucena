import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/pilares_sale/view_models/pilares_purchase_watch_cubit.dart';
import 'package:lucena/ui/pilares_sale/widgets/pilares_purchase_bridge.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakePurchaseRepository purchases;
  late FakeAccountRepository accounts;
  late FakeAnalyticsRepository analytics;

  setUp(() {
    purchases = FakePurchaseRepository(
      const PurchaseState(
        pricesReady: true,
        prices: {
          PilaresPlan.lifetime: r'R$ 99,90',
          PilaresPlan.monthly: r'R$ 19,90',
        },
      ),
    );
    accounts = FakeAccountRepository(account: FakeAccountRepository.google);
    analytics = FakeAnalyticsRepository();
  });

  Future<GoRouter> pump(WidgetTester tester, String location) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('inicio')),
        ),
        GoRoute(
          path: Routes.accountEnter,
          builder: (_, state) => Scaffold(body: Text('conta ${state.uri}')),
        ),
        GoRoute(
          path: Routes.settingsProfile,
          builder: (_, _) => const Scaffold(body: Text('perfil')),
        ),
        ...d2Routes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider<AccountRepository>.value(
        value: accounts,
        child: TestApp(
          locale: const Locale('pt'),
          purchaseRepository: purchases,
          analytics: analytics,
          router: router,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (location != Routes.home) {
      router.push(location);
      await tester.pumpAndSettle();
    }
    return router;
  }

  /// Rola a lista até a key aparecer (a oferta é mais alta que a tela).
  Future<Finder> show(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return finder;
  }

  /// Regra transversal da app bar: sem subtítulo e os mesmos ícones.
  void expectPlainAppBar(WidgetTester tester) {
    for (final bar in tester.widgetList<AppBar>(find.byType(AppBar))) {
      expect(bar.bottom, isNull);
    }
  }

  group('Oferta (H-VEN-03)', () {
    testWidgets('vitalício escolhido, com o selo e o preço no botão', (
      tester,
    ) async {
      await pump(tester, D2Paths.offer());
      expect(find.byKey(PurchaseKeys.offerScreen), findsOneWidget);
      expect(await show(tester, PurchaseKeys.planBest), findsOneWidget);
      expect(find.text(r'Comprar por R$ 99,90'), findsOneWidget);
      expect(
        find.byKey(PurchaseKeys.subscriptionInfo, skipOffstage: false),
        findsNothing,
      );
      expectPlainAppBar(tester);
    });

    testWidgets('mensal mostra a assinatura e assina pelo preço do mês', (
      tester,
    ) async {
      await pump(tester, D2Paths.offer());
      await tester.tap(await show(tester, PurchaseKeys.planMonthly));
      await tester.pumpAndSettle();
      expect(await show(tester, PurchaseKeys.subscriptionInfo), findsOneWidget);
      expect(find.text(r'Assinar por R$ 19,90/mês'), findsOneWidget);
      await tester.tap(find.byKey(PurchaseKeys.buy));
      await tester.pump();
      expect(purchases.buys, [PilaresPlan.monthly]);
    });

    testWidgets('a oferta aberta com plano=mensal já vem no mensal', (
      tester,
    ) async {
      await pump(tester, D2Paths.offer(plan: PilaresPlan.monthly));
      expect(await show(tester, PurchaseKeys.subscriptionInfo), findsOneWidget);
    });

    testWidgets('sem conta, comprar abre a conta', (tester) async {
      accounts = FakeAccountRepository();
      await pump(tester, D2Paths.offer());
      await tester.tap(find.byKey(PurchaseKeys.buy));
      await tester.pumpAndSettle();
      expect(find.textContaining('conta /conta'), findsOneWidget);
      expect(purchases.buys, isEmpty);
    });

    testWidgets('cancelada mostra o aviso; erro mostra a faixa', (
      tester,
    ) async {
      await pump(tester, D2Paths.offer());
      final icons = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(BackButton),
      );
      expect(icons, findsOneWidget);
      purchases.state = purchases.state.copyWith(
        outcome: PurchaseOutcome.canceled,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.canceled), findsOneWidget);
      purchases.state = purchases.state.copyWith(
        outcome: PurchaseOutcome.error,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.errorBanner), findsOneWidget);
      expect(icons, findsOneWidget);
      expectPlainAppBar(tester);
    });

    testWidgets('pendente troca a oferta por Pagamento pendente', (
      tester,
    ) async {
      await pump(tester, D2Paths.offer());
      purchases.state = purchases.state.copyWith(
        pending: true,
        outcome: PurchaseOutcome.pending,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.pendingScreen), findsOneWidget);
      await tester.tap(find.byKey(PurchaseKeys.pendingOk));
      await tester.pumpAndSettle();
      expect(find.text('inicio'), findsOneWidget);
    });
  });

  group('Restaurar (H-VEN-08)', () {
    testWidgets('achou: Compra restaurada', (tester) async {
      purchases
        ..restoreResult = RestoreResult.found
        ..state = purchases.state.copyWith(
          access: const PilaresAccess(kind: PilaresAccessKind.lifetime),
        );
      await pump(tester, D2Paths.pilaresRestore);
      expect(find.text('teste@example.com'), findsOneWidget);
      await tester.tap(find.byKey(PurchaseKeys.restoreSearch));
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.restoredScreen), findsOneWidget);
    });

    testWidgets('não achou: aviso e Entrar com outra conta', (tester) async {
      await pump(tester, D2Paths.pilaresRestore);
      await tester.tap(find.byKey(PurchaseKeys.restoreSearch));
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.restoreNotFound), findsOneWidget);
      expectPlainAppBar(tester);
      await tester.tap(find.byKey(PurchaseKeys.restoreOtherAccount));
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.siteScreen), findsOneWidget);
    });
  });

  group('Assinatura encerrada (H-VEN-10)', () {
    testWidgets('os botões abrem a oferta no plano certo', (tester) async {
      await pump(tester, D2Paths.pilaresSubscriptionEnded);
      expect(find.text('Sua assinatura terminou'), findsOneWidget);
      expect(find.text(r'Assinar de novo por R$ 19,90/mês'), findsOneWidget);
      expect(
        find.text(r'Acesso vitalício ao Pilares por R$ 99,90'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(PurchaseKeys.endedRenew));
      await tester.pumpAndSettle();
      expect(await show(tester, PurchaseKeys.subscriptionInfo), findsOneWidget);
    });

    testWidgets('vitalício abre a oferta no vitalício', (tester) async {
      await pump(tester, D2Paths.pilaresSubscriptionEnded);
      await tester.tap(find.byKey(PurchaseKeys.endedLifetime));
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.offerScreen), findsOneWidget);
      expect(
        find.byKey(PurchaseKeys.subscriptionInfo, skipOffstage: false),
        findsNothing,
      );
    });
  });

  testWidgets('a ponte abre a Concluída quando a compra é confirmada', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('inicio')),
        ),
        ...d2Routes,
      ],
    );
    addTearDown(router.dispose);
    final watch = PilaresPurchaseWatchCubit(
      purchases: purchases,
      analytics: analytics,
    );
    addTearDown(watch.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: watch,
        child: PilaresPurchaseBridge(
          router: router,
          child: TestApp(
            locale: const Locale('pt'),
            purchaseRepository: purchases,
            router: router,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    purchases.state = purchases.state.copyWith(outcome: PurchaseOutcome.done);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      D2Paths.pilaresPurchaseDone,
    );
  });
}
