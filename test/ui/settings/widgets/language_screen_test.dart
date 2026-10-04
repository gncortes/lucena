import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/settings/widgets/language_screen.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeSettingsRepository repository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    List<AppLanguage>? languages,
  }) async {
    repository = FakeSettingsRepository(settings);
    final cubit = SettingsCubit(
      repository,
      languages: languages ?? AppLanguage.selectable,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(settingsCubit: cubit, child: const LanguageScreen()),
    );
  }

  bool isSelected(WidgetTester tester, Key key) {
    final tile = find.descendant(
      of: find.byKey(key),
      matching: find.byType(ListTile),
    );
    return tester.widget<ListTile>(tile).selected;
  }

  testWidgets('sem idioma escolhido, "padrão do sistema" vem marcado', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(isSelected(tester, SettingsKeys.languageSystem), isTrue);
    expect(isSelected(tester, SettingsKeys.languageOption('en')), isFalse);
  });

  testWidgets('tocar num idioma marca a opção e grava a escolha', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(SettingsKeys.languageOption('es')));
    await tester.pumpAndSettle();

    expect(isSelected(tester, SettingsKeys.languageOption('es')), isTrue);
    expect(isSelected(tester, SettingsKeys.languageSystem), isFalse);
    expect(repository.saved, [const AppSettings(languageCode: 'es')]);
  });

  testWidgets('tocar em "padrão do sistema" desfaz a escolha', (tester) async {
    await pumpScreen(tester, settings: const AppSettings(languageCode: 'es'));

    await tester.tap(find.byKey(SettingsKeys.languageSystem));
    await tester.pumpAndSettle();

    expect(isSelected(tester, SettingsKeys.languageSystem), isTrue);
    expect(repository.saved, [const AppSettings()]);
  });

  testWidgets('lista só os idiomas da composição', (tester) async {
    await pumpScreen(
      tester,
      languages: [AppLanguage.english, AppLanguage.arabic],
    );

    expect(find.byKey(SettingsKeys.languageOption('ar')), findsOneWidget);
    expect(find.byKey(SettingsKeys.languageOption('es')), findsNothing);
  });
}
