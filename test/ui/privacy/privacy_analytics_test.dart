import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/analytics_keys.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:lucena/ui/privacy/widgets/privacy_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_device_settings_repository.dart';
import '../../../testing/test_app.dart';

/// A chave "Ajudar a melhorar o Lucena" (E1.03).
void main() {
  late FakeAnalyticsRepository analytics;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    analytics = FakeAnalyticsRepository();
  });

  testWidgets('a Privacidade traz a chave do Analytics', (tester) async {
    final cubit = PrivacyCubit(
      accounts: FakeAccountRepository(),
      device: FakeDeviceSettingsRepository(),
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
}
