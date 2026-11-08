import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/settings/widgets/settings_save_failure_listener.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  testWidgets('H-AJU-02 Gap 1: troca não gravada avisa e a tela volta', (
    tester,
  ) async {
    final repository = FakeSettingsRepository();
    final cubit = SettingsCubit(repository, languages: AppLanguage.selectable);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        settingsCubit: cubit,
        child: const Scaffold(
          body: SettingsSaveFailureListener(child: SizedBox()),
        ),
      ),
    );

    repository.saveError = Exception('disco cheio');
    await cubit.setThemeMode(AppThemeMode.dark);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(SettingsKeys.saveFailure), findsOneWidget);
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(cubit.state, const AppSettings());
  });
}
