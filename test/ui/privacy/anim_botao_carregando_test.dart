import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/core/widgets/busy_button.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:lucena/ui/privacy/widgets/privacy_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_data_export_repository.dart';
import '../../../testing/fakes/fake_device_settings_repository.dart';
import '../../../testing/test_app.dart';

/// H-ANI-08: o botão da exportação carrega dentro dele.
void main() {
  late FakeDataExportRepository exports;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    exports = FakeDataExportRepository();
  });

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final cubit = PrivacyCubit(
      accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      device: FakeDeviceSettingsRepository(),
    );
    addTearDown(cubit.close);
    await tester.runAsync(cubit.load);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        analytics: FakeAnalyticsRepository(),
        dataExportRepository: exports,
        child: BlocProvider.value(value: cubit, child: const PrivacyScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(PrivacyKeys.download), 200);
    await tester.ensureVisible(find.byKey(PrivacyKeys.download));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PrivacyKeys.download));
    await tester.pumpAndSettle();
  }

  testWidgets('H-ANI-08: Baixando mostra o círculo no botão, sem toque', (
    tester,
  ) async {
    await openSheet(tester);
    exports.gate = Completer<void>();
    await tester.tap(find.byKey(PrivacyKeys.downloadStart));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(BusyButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BusyButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(PrivacyKeys.downloading))
          .onPressed,
      isNull,
    );
    exports.gate!.complete();
    await tester.pumpAndSettle();
  });
}
