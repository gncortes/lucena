import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:lucena/ui/privacy/widgets/privacy_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_data_export_repository.dart';
import '../../../testing/fakes/fake_device_settings_repository.dart';
import '../../../testing/test_app.dart';

/// H-CON-21 (casos 62 a 64 do roteiro): a folha "Baixar seus dados?".
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

  testWidgets('1: a linha abre "Baixar seus dados?"', (tester) async {
    await openSheet(tester);
    expect(find.byKey(PrivacyKeys.downloadSheet), findsOneWidget);
    expect(find.text('Baixar seus dados?'), findsOneWidget);
    expect(
      find.text('Você recebe um arquivo com os dados da sua conta.'),
      findsOneWidget,
    );
    expect(find.byKey(PrivacyKeys.downloadStart), findsOneWidget);
    expect(find.text('Baixar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('2 e 3: Baixando só com Cancelar; pronto abre o arquivo', (
    tester,
  ) async {
    await openSheet(tester);
    exports.gate = Completer<void>();
    await tester.tap(find.byKey(PrivacyKeys.downloadStart));
    await tester.pump();

    expect(find.byKey(PrivacyKeys.downloading), findsOneWidget);
    // H-ANI-08: o rótulo sai do botão e o círculo entra; o leitor continua lendo.
    expect(find.bySemanticsLabel('Baixando'), findsOneWidget);
    expect(find.text('Baixar seus dados?'), findsOneWidget);
    expect(find.byKey(PrivacyKeys.downloadStart), findsNothing);
    expect(find.text('Cancelar'), findsOneWidget);

    exports.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(PrivacyKeys.downloadReady), findsOneWidget);
    expect(find.text('Seus dados estão prontos'), findsOneWidget);
    expect(find.text('O arquivo tem os dados da sua conta.'), findsOneWidget);
    expect(find.text('Fechar'), findsOneWidget);

    await tester.tap(find.byKey(PrivacyKeys.downloadOpen));
    await tester.pumpAndSettle();
    expect(exports.opened, [FakeDataExportRepository.path]);
    // Volta à Privacidade.
    expect(find.byKey(PrivacyKeys.downloadSheet), findsNothing);
  });

  testWidgets('4: a falha mostra o erro e Tentar de novo refaz', (
    tester,
  ) async {
    await openSheet(tester);
    exports.fails = true;
    await tester.tap(find.byKey(PrivacyKeys.downloadStart));
    await tester.pumpAndSettle();

    expect(find.byKey(PrivacyKeys.downloadError), findsOneWidget);
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(
      find.text('Seus dados continuam salvos. Tente baixar novamente.'),
      findsOneWidget,
    );
    expect(find.text('Tentar de novo'), findsOneWidget);

    exports.fails = false;
    await tester.tap(find.byKey(PrivacyKeys.downloadRetry));
    await tester.pumpAndSettle();
    expect(find.byKey(PrivacyKeys.downloadReady), findsOneWidget);
    expect(exports.downloads, hasLength(2));
  });

  testWidgets('5: Cancelar durante Baixando fecha e nada fica salvo', (
    tester,
  ) async {
    await openSheet(tester);
    exports.gate = Completer<void>();
    await tester.tap(find.byKey(PrivacyKeys.downloadStart));
    await tester.pump();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byKey(PrivacyKeys.downloadSheet), findsNothing);

    exports.gate!.complete();
    await tester.pumpAndSettle();
    expect(exports.saved, isEmpty);
    expect(exports.discarded, [FakeDataExportRepository.path]);
  });

  testWidgets('X fecha a folha na pergunta', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byKey(PrivacyKeys.downloadClose));
    await tester.pumpAndSettle();
    expect(find.byKey(PrivacyKeys.downloadSheet), findsNothing);
    expect(exports.downloads, isEmpty);
  });
}
