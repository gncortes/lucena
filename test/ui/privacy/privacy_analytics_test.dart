import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/ads/ads_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/ui/core/keys/analytics_keys.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:lucena/ui/privacy/widgets/privacy_screen.dart';
import 'package:lucena/ui/privacy/widgets/remove_ads_sheet.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_ads_service.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/fakes/fake_remote_flags_repository.dart';
import '../../../testing/test_app.dart';

/// A chave "Ajudar a melhorar o Lucena" e o funil da remoção (E1.03).
void main() {
  late FakeAnalyticsRepository analytics;
  late FakePurchaseRepository purchases;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    analytics = FakeAnalyticsRepository();
    purchases = FakePurchaseRepository(const PurchaseState(price: 'R\$ 9,90'));
  });

  testWidgets('a Privacidade traz a chave do Analytics', (tester) async {
    final cubit = PrivacyCubit(
      ads: ServiceAdsRepository(
        service: FakeAdsService(),
        preferences: PreferencesService(),
        flags: FakeRemoteFlagsRepository(),
        purchases: purchases,
        now: FakeNow(DateTime.utc(2026, 10, 22)),
      ),
      purchases: purchases,
      accounts: FakeAccountRepository(),
    );
    addTearDown(cubit.close);
    await tester.runAsync(cubit.load);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        analytics: analytics,
        child: BlocProvider.value(value: cubit, child: const PrivacyScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(AnalyticsKeys.optInSwitch), 200);
    expect(find.text('Ajudar a melhorar o Lucena'), findsOneWidget);
    await tester.tap(find.byKey(AnalyticsKeys.optInSwitch));
    await tester.pumpAndSettle();
    expect(analytics.optIn, isFalse);
  });

  group('Remover anúncios', () {
    Future<void> pumpSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt', 'BR'),
          analytics: analytics,
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

    List<String?> steps() => [
      for (final event in analytics.eventsNamed('anuncio_remocao'))
        event.params['etapa'] as String?,
    ];

    testWidgets('aberto e comprado, com o purchase em reais', (tester) async {
      await pumpSheet(tester);
      purchases.state = const PurchaseState(price: 'R\$ 9,90', adFree: true);
      await tester.pumpAndSettle();
      expect(steps(), ['aberto', 'comprado']);
      expect(
        analytics.eventsNamed('anuncio_remocao').first.params['origem'],
        'perfil',
      );
      expect(analytics.eventsNamed('purchase').single.params['value'], 9.9);
      expect(find.byKey(PrivacyKeys.removeSheet), findsNothing);
    });

    testWidgets('pendente e erro', (tester) async {
      await pumpSheet(tester);
      purchases.state = const PurchaseState(price: 'R\$ 9,90', pending: true);
      await tester.pumpAndSettle();
      purchases.state = const PurchaseState(price: 'R\$ 9,90', error: true);
      await tester.pumpAndSettle();
      expect(steps(), ['aberto', 'pendente', 'cancelado']);
      expect(analytics.eventsNamed('purchase'), isEmpty);
    });
  });
}
