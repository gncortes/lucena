import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
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

  Future<GoRouter> pump(
    WidgetTester tester,
    String location, {
    bool settle = true,
  }) async {
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
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
        await tester.pump();
      }
    }
    return router;
  }

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

  Future<void> montaOferta(WidgetTester tester) async {
    await pump(tester, D2Paths.offer());
  }

  Material contorno(WidgetTester tester, Key plano) => tester.widget<Material>(
    find.descendant(
      of: find.byKey(plano),
      matching: find.byKey(MotionKeys.contornoDoPlano),
    ),
  );

  Color? borda(WidgetTester tester, Key plano) =>
      (contorno(tester, plano).shape! as RoundedRectangleBorder).side.color;

  testWidgets('H-ANI-26: a seleção do plano passa em 250 ms', (tester) async {
    await montaOferta(tester);
    await show(tester, PurchaseKeys.planMonthly);
    final inicial = borda(tester, PurchaseKeys.planMonthly);
    await tester.tap(find.byKey(PurchaseKeys.planMonthly));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    expect(borda(tester, PurchaseKeys.planMonthly), isNot(inicial));
    final meio = borda(tester, PurchaseKeys.planMonthly);
    await tester.pump(const Duration(milliseconds: 125));
    expect(borda(tester, PurchaseKeys.planMonthly), isNot(meio));
    expect(
      borda(tester, PurchaseKeys.planMonthly),
      Theme.of(tester.element(find.byKey(PurchaseKeys.planMonthly)))
          .colorScheme
          .primary,
    );
    expect(find.text(r'Assinar por R$ 19,90/mês'), findsOneWidget);
  });

  testWidgets('H-ANI-26: movimento reduzido troca sem transição', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await montaOferta(tester);
    await show(tester, PurchaseKeys.planMonthly);
    await tester.tap(find.byKey(PurchaseKeys.planMonthly));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      borda(tester, PurchaseKeys.planMonthly),
      Theme.of(tester.element(find.byKey(PurchaseKeys.planMonthly)))
          .colorScheme
          .primary,
    );
  });

  testWidgets(
    'H-ANI-27: a compra concluída tem o círculo, o anel e os botões',
    (tester) async {
      await pump(tester, D2Paths.pilaresPurchaseDone, settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(PurchaseKeys.doneScreen), findsOneWidget);
      expect(find.byKey(MotionKeys.circuloDaCompra), findsOneWidget);
      expect(find.byKey(MotionKeys.anelDaCompra), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(MotionKeys.anelDaCompra), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(PurchaseKeys.doneGoal), findsOneWidget);
      expect(find.byKey(PurchaseKeys.doneTitle), findsOneWidget);
    },
  );

  // Bug 3 da D2 (PropV2CompraConcluida): círculo verde-claro com ✓ verde e
  // "Escolher meu objetivo" preso embaixo.
  testWidgets('a compra concluída segue o quadro', (tester) async {
    await pump(tester, D2Paths.pilaresPurchaseDone);
    final circulo = find.descendant(
      of: find.byKey(MotionKeys.circuloDaCompra),
      matching: find.byType(Container),
    );
    final fundo =
        (tester.widget<Container>(circulo.first).decoration! as BoxDecoration)
            .color;
    expect(fundo, AppColors.successSurface);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.check_rounded)).color,
      AppColors.successOnSurface,
    );
    expect(find.text('Escolher meu objetivo'), findsOneWidget);
    final texto = tester.getRect(
      find.text(
        'Os 20 capítulos estão liberados. Com o seu objetivo, a gente planeja '
        'junto a sua rotina de estudos.',
      ),
    );
    final botao = tester.getRect(find.byKey(PurchaseKeys.doneGoal));
    // Embaixo da tela, longe do texto (no quadro: 758 de 900).
    expect(botao.top, greaterThan(915 * .75));
    expect(botao.top - texto.bottom, greaterThan(100));
  });

  testWidgets('H-ANI-27: o aviso de erro abre empurrando e o ícone pulsa', (
    tester,
  ) async {
    await montaOferta(tester);
    purchases.state = purchases.state.copyWith(outcome: PurchaseOutcome.error);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(PurchaseKeys.errorBanner), findsOneWidget);
    final aviso = find.byKey(MotionKeys.avisoQueAbre);
    expect(aviso, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 160));
    final parcial = tester.getSize(aviso).height;
    await tester.pump(const Duration(milliseconds: 160));
    final cheia = tester.getSize(aviso).height;
    expect(parcial, lessThan(cheia));
    expect(cheia, greaterThan(0));
    expect(find.byKey(MotionKeys.iconeDoAviso), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
