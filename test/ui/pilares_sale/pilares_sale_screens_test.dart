import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/campaign.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/offer_discount.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/pilares_sale/view_models/pilares_purchase_watch_cubit.dart';
import 'package:lucena/ui/pilares_sale/widgets/pilares_purchase_bridge.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_grants.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakePurchaseRepository purchases;
  late FakeAccountRepository accounts;
  late FakeAnalyticsRepository analytics;
  late MemoryCampaignRepository campaigns;

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
    campaigns = MemoryCampaignRepository();
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
          path: Routes.training(TrainingCourse.pilares.name),
          builder: (_, state) => Scaffold(body: Text('treino ${state.uri}')),
        ),
        GoRoute(
          path: D2Paths.pilaresPlan,
          builder: (_, _) => const Scaffold(body: Text('venda do plano')),
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
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AccountRepository>.value(value: accounts),
          RepositoryProvider<CampaignRepository>.value(value: campaigns),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<ProfileRepository>.value(
            value: FakeProfileRepository(),
          ),
          RepositoryProvider<TrainingRepository>.value(
            value: FakeTrainingRepository(),
          ),
        ],
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

  group('Oferta com desconto (H-R5-66)', () {
    testWidgets('promoção: −30%, preço cheio riscado, prazo e o botão', (
      tester,
    ) async {
      purchases.state = purchases.state.copyWith(
        discount: OfferDiscount(
          kind: DiscountKind.everyone,
          offerId: 'black-friday-2026',
          percent: 30,
          price: r'R$ 69,90',
          fullPrice: r'R$ 99,90',
          endsAt: DateTime(2026, 11, 30, 23, 59, 59),
          name: 'Black Friday',
        ),
      );
      await pump(tester, D2Paths.offer());
      expect(await show(tester, PurchaseKeys.discountBadge), findsOneWidget);
      expect(find.text('−30%'), findsOneWidget);
      expect(find.byKey(PurchaseKeys.fullPrice), findsOneWidget);
      expect(find.text('Black Friday · até 30/11'), findsOneWidget);
      expect(find.text(r'Comprar por R$ 69,90'), findsOneWidget);
    });

    testWidgets('link sem fim: só "Desconto do seu link"', (tester) async {
      purchases.state = purchases.state.copyWith(
        discount: const OfferDiscount(
          kind: DiscountKind.link,
          offerId: 'link-30',
          percent: 30,
          price: r'R$ 69,90',
          fullPrice: r'R$ 99,90',
        ),
      );
      await pump(tester, D2Paths.offer());
      expect(await show(tester, PurchaseKeys.discountDeadline), findsOneWidget);
      expect(find.text('Desconto do seu link'), findsOneWidget);
    });

    testWidgets('o código do link vai ao repositório', (tester) async {
      await pump(tester, D2Paths.offer(origin: 'link', code: 'CXC20'));
      expect(purchases.offerCodes, ['CXC20']);
    });

    testWidgets('link que não vale: o aviso, sem o selo do desconto', (
      tester,
    ) async {
      purchases.state = purchases.state.copyWith(linkGone: true);
      await pump(tester, D2Paths.offer());
      expect(await show(tester, PurchaseKeys.linkGone), findsOneWidget);
      expect(find.text('Este link de desconto não vale mais.'), findsOneWidget);
      expect(
        find.byKey(PurchaseKeys.discountBadge, skipOffstage: false),
        findsNothing,
      );
    });
  });

  group('Restaurar (H-VEN-08)', () {
    // Bug 2 da D2 (PropV2CompraRestaurar): o título também no corpo e o
    // e-mail da conta no texto.
    testWidgets('título no corpo e o e-mail no texto', (tester) async {
      await pump(tester, D2Paths.pilaresRestore);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('Restaurar compra'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Já comprou? Entre na sua conta para liberar. Procuramos a compra na '
          'conta teste@example.com.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem conta, vai primeiro à conta', (tester) async {
      accounts = FakeAccountRepository();
      await pump(tester, D2Paths.pilaresRestore);
      expect(find.byKey(PurchaseKeys.restoreScreen), findsNothing);
      expect(
        find.textContaining('conta ${Routes.accountEnter}'),
        findsOneWidget,
      );
    });

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
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<ProfileRepository>.value(
            value: FakeProfileRepository(),
          ),
          RepositoryProvider<TrainingRepository>.value(
            value: FakeTrainingRepository(),
          ),
        ],
        child: BlocProvider.value(
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

  // Bug r3: o curso dado antes do login chegava durante a entrada; a ponte
  // empilhava o Curso liberado e marcava visto, e o `go` do fim da conta
  // (continueAfterSignIn) limpava a pilha: a tela nunca aparecia.
  testWidgets('curso dado durante a entrada: Curso liberado depois do go', (
    tester,
  ) async {
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
          builder: (_, _) => const Scaffold(body: Text('conta')),
        ),
        ...d2Routes,
      ],
    );
    addTearDown(router.dispose);
    final grants = FakeCourseGrantsRepository();
    final watch = PilaresPurchaseWatchCubit(
      purchases: purchases,
      analytics: analytics,
      grants: grants,
      now: FakeNow(DateTime(2026, 11, 7)),
    );
    addTearDown(watch.close);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<ProfileRepository>.value(
            value: FakeProfileRepository(),
          ),
          RepositoryProvider<TrainingRepository>.value(
            value: FakeTrainingRepository(),
          ),
        ],
        child: BlocProvider.value(
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
      ),
    );
    await tester.pumpAndSettle();
    // A entrada na conta vem por cima do Início.
    unawaited(router.push(Routes.accountEnter));
    await tester.pumpAndSettle();
    grants.current = CourseGrants(
      courses: {
        pilaresCourseId: CourseGrant(
          origin: GrantOrigin.gift,
          givenAt: DateTime(2025, 12),
        ),
      },
    );
    await tester.pumpAndSettle();
    // Ainda na entrada: nada é marcado como visto.
    expect(grants.seen, isEmpty);
    router.go(Routes.home);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      D2Paths.pilaresGiftDone,
    );
    expect(grants.seen, [pilaresCourseId]);
  });

  group('Fim da demonstração (H-VEN-04)', () {
    testWidgets('o cartão de preço traz os dois planos e os 5 meses', (
      tester,
    ) async {
      await pump(tester, D2Paths.pilaresDemoEnd);
      expect(find.byKey(PurchaseKeys.demoEndScreen), findsOneWidget);
      expect(find.text('Capítulo 1 concluído'), findsOneWidget);
      final price = await show(tester, PurchaseKeys.demoEndPrice);
      final texts = tester
          .widgetList<Text>(
            find.descendant(of: price, matching: find.byType(Text)),
          )
          .map((text) => text.data)
          .join(' ');
      expect(texts, contains(r'R$ 19,90/mês'));
      expect(texts, contains(r'R$ 99,90'));
      expect(texts, contains('cerca de 5 meses de assinatura'));
      expect(analytics.names, contains('demo_fim'));
      expectPlainAppBar(tester);
    });

    testWidgets('"Agora não" volta ao Catálogo do Pilares', (tester) async {
      final router = await pump(tester, D2Paths.pilaresDemoEnd);
      await tester.tap(find.byKey(PurchaseKeys.demoEndLater));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        Routes.trainingCatalog(TrainingCourse.pilares.name),
      );
    });

    testWidgets('"Ver opções de compra" abre a oferta com origem fim_demo', (
      tester,
    ) async {
      campaigns.saved = const Campaign(utm: {'utm_campaign': 'x'});
      await pump(tester, D2Paths.pilaresDemoEnd);
      expect(
        analytics.eventsNamed('campanha_oferta_vista').single.params,
        containsPair('destaque', 'fim_demo'),
      );
      await tester.tap(find.byKey(PurchaseKeys.demoEndSeeOptions));
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.offerScreen), findsOneWidget);
      final offer = tester.element(find.byKey(PurchaseKeys.offerScreen));
      expect(GoRouterState.of(offer).uri.queryParameters['origem'], 'fim_demo');
      expect(analytics.names, contains('campanha_oferta_tocada'));
    });
  });

  group('Oferta antes do Início (H-VEN-15)', () {
    // Bug 5 da D2: tela cheia com o X à esquerda (decisão do Gabriel, 03/11;
    // quadro PropV2OfertaAntesInicio), não mais folha sobre o Início.
    testWidgets('tela cheia com o X à esquerda e os três itens', (
      tester,
    ) async {
      await pump(tester, D2Paths.pilaresBeforeHome);
      expect(find.byKey(PurchaseKeys.beforeHomeSheet), findsOneWidget);
      expect(find.text('inicio'), findsNothing);
      expect(
        tester.getRect(find.byKey(PurchaseKeys.beforeHomeClose)).left,
        lessThan(60),
      );
      expect(
        tester.getRect(find.byKey(PurchaseKeys.beforeHomeLearn)).bottom,
        greaterThan(915 * .85),
      );
      expect(find.text('Mais que um curso'), findsOneWidget);
      expect(find.text('Plano até o seu torneio'), findsOneWidget);
      expect(
        find.text('Capítulo 1 grátis, com 3 lições e o teste'),
        findsOneWidget,
      );
      expect(
        analytics.eventsNamed('pilares_oferta_vista').single.params,
        allOf(
          containsPair('origem', 'abertura_app'),
          containsPair('destaque', 'tela'),
        ),
      );
    });

    testWidgets('o X fecha e fica o Início, com a oferta fechada uma vez', (
      tester,
    ) async {
      await pump(tester, D2Paths.pilaresBeforeHome);
      await tester.tap(find.byKey(PurchaseKeys.beforeHomeClose));
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.beforeHomeSheet), findsNothing);
      expect(find.text('inicio'), findsOneWidget);
      expect(analytics.eventsNamed('pilares_oferta_fechada'), hasLength(1));
    });

    testWidgets('o voltar do sistema fecha como o X', (tester) async {
      await pump(tester, D2Paths.pilaresBeforeHome);
      final popped = await tester.binding.handlePopRoute();
      expect(popped, isTrue);
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.beforeHomeSheet), findsNothing);
      expect(find.text('inicio'), findsOneWidget);
      expect(analytics.eventsNamed('pilares_oferta_fechada'), hasLength(1));
    });

    testWidgets('"Conhecer o plano" abre a venda do plano sem contar fechada', (
      tester,
    ) async {
      await pump(tester, D2Paths.pilaresBeforeHome);
      await tester.tap(find.byKey(PurchaseKeys.beforeHomeLearn));
      await tester.pumpAndSettle();
      expect(find.text('venda do plano'), findsOneWidget);
      expect(analytics.eventsNamed('pilares_oferta_fechada'), isEmpty);
    });
  });
}
