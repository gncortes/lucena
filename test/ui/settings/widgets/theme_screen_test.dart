import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/settings/widgets/theme_screen.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeSettingsRepository repository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    repository = FakeSettingsRepository(settings);
    final cubit = SettingsCubit(repository, languages: AppLanguage.selectable);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: cubit,
        themeMode: themeMode,
        child: const ThemeScreen(),
      ),
    );
  }

  bool isSelected(WidgetTester tester, AppThemeMode mode) {
    final tile = find.descendant(
      of: find.byKey(SettingsKeys.themeOption(mode)),
      matching: find.byType(ListTile),
    );
    return tester.widget<ListTile>(tile).selected;
  }

  testWidgets('sem tema escolhido, "padrão do sistema" vem marcado', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(isSelected(tester, AppThemeMode.system), isTrue);
    expect(isSelected(tester, AppThemeMode.light), isFalse);
    expect(isSelected(tester, AppThemeMode.dark), isFalse);
  });

  testWidgets('tocar em escuro marca a opção e grava a escolha', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(SettingsKeys.themeOption(AppThemeMode.dark)));
    await tester.pumpAndSettle();

    expect(isSelected(tester, AppThemeMode.dark), isTrue);
    expect(isSelected(tester, AppThemeMode.system), isFalse);
    expect(repository.saved, [const AppSettings(themeMode: AppThemeMode.dark)]);
  });

  testWidgets('trocar o tema não mexe no idioma escolhido', (tester) async {
    await pumpScreen(tester, settings: const AppSettings(languageCode: 'es'));

    await tester.tap(find.byKey(SettingsKeys.themeOption(AppThemeMode.light)));
    await tester.pumpAndSettle();

    expect(repository.saved, [
      const AppSettings(languageCode: 'es', themeMode: AppThemeMode.light),
    ]);
  });

  String accentValue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SettingsKeys.accentValue)).data!;

  testWidgets('sem cor escolhida, vale a de fábrica do tema: azul no claro', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(accentValue(tester), 'Blue');
  });

  testWidgets('sem cor escolhida, vale a de fábrica do tema: verde no escuro', (
    tester,
  ) async {
    await pumpScreen(tester, themeMode: ThemeMode.dark);

    expect(accentValue(tester), 'Green');
  });

  testWidgets('tocar numa cor marca a opção e grava, sem mexer no tema', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      settings: const AppSettings(themeMode: AppThemeMode.dark),
    );

    await tester.tap(find.byKey(SettingsKeys.accentOption(AppAccent.pink)));
    await tester.pumpAndSettle();

    expect(accentValue(tester), 'Pink');
    expect(repository.saved, [
      const AppSettings(themeMode: AppThemeMode.dark, accent: AppAccent.pink),
    ]);
  });
}
