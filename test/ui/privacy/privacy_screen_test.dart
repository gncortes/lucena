import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/ads/ads_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:lucena/ui/privacy/widgets/privacy_screen.dart';
import 'package:lucena/ui/privacy/widgets/remove_ads_sheet.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_ads_service.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/fakes/fake_remote_flags_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeAdsService service;
  late FakePurchaseRepository purchases;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = FakeAdsService();
    purchases = FakePurchaseRepository(const PurchaseState(price: 'R\$ 9,90'));
  });

  group('Privacidade e anúncios', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      FakeAccountRepository? accounts,
    }) async {
      final cubit = PrivacyCubit(
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
      addTearDown(cubit.close);
      await tester.runAsync(cubit.load);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt', 'BR'),
          child: BlocProvider.value(value: cubit, child: const PrivacyScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('grátis: o cartão diz onde o anúncio aparece', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(PrivacyKeys.freeCard), findsOneWidget);
      expect(find.text('O Lucena é grátis'), findsOneWidget);
      expect(find.byKey(PrivacyKeys.policy), findsOneWidget);
      // Fora da região que exige e sem conta.
      expect(find.byKey(PrivacyKeys.adChoices), findsNothing);
      expect(find.byKey(PrivacyKeys.deleteAccount), findsNothing);
    });

    testWidgets('onde o Google exige, "Escolhas de anúncios" reabre a janela', (
      tester,
    ) async {
      service.optionsRequired = true;
      await pumpScreen(
        tester,
        accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      );
      expect(find.byKey(PrivacyKeys.deleteAccount), findsOneWidget);
      await tester.tap(find.byKey(PrivacyKeys.adChoices));
      await tester.pumpAndSettle();
      expect(service.privacyOptionsShown, 1);
    });

    testWidgets('sem anúncios: o cartão agradece', (tester) async {
      purchases.state = const PurchaseState(adFree: true);
      await pumpScreen(tester);
      expect(find.byKey(PrivacyKeys.adFreeCard), findsOneWidget);
      expect(find.text('Sem anúncios'), findsOneWidget);
      expect(find.byKey(PrivacyKeys.adChoices), findsNothing);
    });
  });

  group('Remover anúncios', () {
    Future<void> pumpSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt', 'BR'),
          purchaseRepository: purchases,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showRemoveAdsSheet(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra o preço e o botão abre o pagamento da Play', (
      tester,
    ) async {
      await pumpSheet(tester);
      expect(find.byKey(PrivacyKeys.removeSheet), findsOneWidget);
      expect(find.text('Remover por R\$ 9,90'), findsOneWidget);
      await tester.tap(find.byKey(PrivacyKeys.removeBuy));
      expect(purchases.buys, 1);
    });

    testWidgets('pagamento pendente: avisa e trava o botão', (tester) async {
      await pumpSheet(tester);
      purchases.state = const PurchaseState(price: 'R\$ 9,90', pending: true);
      await tester.pumpAndSettle();
      expect(find.byKey(PrivacyKeys.removePending), findsOneWidget);
      await tester.tap(find.byKey(PrivacyKeys.removeBuy));
      expect(purchases.buys, 0);
    });

    testWidgets('erro da Play: avisa', (tester) async {
      await pumpSheet(tester);
      purchases.state = const PurchaseState(price: 'R\$ 9,90', error: true);
      await tester.pumpAndSettle();
      expect(find.byKey(PrivacyKeys.removeError), findsOneWidget);
    });

    testWidgets('compra confirmada fecha a folha', (tester) async {
      await pumpSheet(tester);
      purchases.state = const PurchaseState(adFree: true);
      await tester.pumpAndSettle();
      expect(find.byKey(PrivacyKeys.removeSheet), findsNothing);
    });

    testWidgets('"Agora não" fecha sem comprar', (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.byKey(PrivacyKeys.removeNo));
      await tester.pumpAndSettle();
      expect(find.byKey(PrivacyKeys.removeSheet), findsNothing);
      expect(purchases.buys, 0);
    });
  });
}
