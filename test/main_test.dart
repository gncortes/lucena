import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/main.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';

import '../testing/fakes/fake_now.dart';
import '../testing/fakes/fake_settings_repository.dart';
import '../testing/test_dependencies.dart';

void main() {
  void useSystemLocale(WidgetTester tester, Locale locale) {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    FakeSettingsRepository? settings,
    FakeNow? now,
  }) async {
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(now: now, settingsRepository: settings),
      ),
    );
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('abre na tela inicial', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(HomeKeys.screen), findsOneWidget);
  });

  testWidgets('entrega às telas o relógio da composição', (tester) async {
    final now = FakeNow(DateTime.utc(2026, 5, 17));
    await pumpApp(tester, now: now);

    final context = tester.element(find.byKey(HomeKeys.screen));

    expect(context.read<Now>(), same(now));
  });

  testWidgets('sem idioma escolhido, segue o idioma do sistema', (
    tester,
  ) async {
    useSystemLocale(tester, const Locale('pt', 'BR'));
    await pumpApp(tester);

    expect(textOf(tester, HomeKeys.tagline), 'Treino de finais de xadrez');
  });

  testWidgets('idioma do sistema sem tradução cai no inglês', (tester) async {
    useSystemLocale(tester, const Locale('sw'));
    await pumpApp(tester);

    expect(textOf(tester, HomeKeys.tagline), 'Chess endgame training');
  });

  testWidgets('português de Portugal usa a variante de Portugal', (
    tester,
  ) async {
    useSystemLocale(tester, const Locale('pt', 'PT'));
    await pumpApp(tester);

    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();

    expect(textOf(tester, SettingsKeys.title), 'Definições');
  });

  testWidgets('o idioma escolhido vence o idioma do sistema', (tester) async {
    useSystemLocale(tester, const Locale('pt', 'BR'));
    await pumpApp(
      tester,
      settings: FakeSettingsRepository(const AppSettings(languageCode: 'es')),
    );

    expect(
      textOf(tester, HomeKeys.tagline),
      'Entrenamiento de finales de ajedrez',
    );
  });

  testWidgets('em árabe a tela espelha: o botão de configurações vai para a '
      'esquerda', (tester) async {
    await pumpApp(
      tester,
      settings: FakeSettingsRepository(const AppSettings(languageCode: 'ar')),
    );

    final context = tester.element(find.byKey(HomeKeys.screen));
    final button = tester.getCenter(find.byKey(HomeKeys.settingsButton));
    final width = tester.getSize(find.byKey(HomeKeys.screen)).width;

    expect(Directionality.of(context), TextDirection.rtl);
    expect(button.dx, lessThan(width / 2));
    expect(textOf(tester, HomeKeys.tagline), 'تدريب نهايات الشطرنج');
  });

  testWidgets('trocar o idioma em Configurações muda os textos na hora e '
      'grava a escolha', (tester) async {
    useSystemLocale(tester, const Locale('en', 'US'));
    final settings = FakeSettingsRepository();
    await pumpApp(tester, settings: settings);

    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();
    expect(textOf(tester, SettingsKeys.title), 'Settings');

    await tester.tap(find.byKey(SettingsKeys.languageTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.languageOption('es')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(textOf(tester, SettingsKeys.title), 'Ajustes');
    expect(textOf(tester, SettingsKeys.languageValue), 'Español');
    expect(settings.saved, [const AppSettings(languageCode: 'es')]);
  });

  void useSystemBrightness(WidgetTester tester, Brightness brightness) {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  Brightness appBrightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byKey(HomeKeys.screen))).brightness;

  testWidgets('sem tema escolhido, o app acompanha o tema do aparelho', (
    tester,
  ) async {
    useSystemBrightness(tester, Brightness.dark);
    await pumpApp(tester);
    expect(appBrightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();

    expect(appBrightness(tester), Brightness.light);
  });

  testWidgets('o tema escolhido vence o tema do aparelho', (tester) async {
    useSystemBrightness(tester, Brightness.light);
    await pumpApp(
      tester,
      settings: FakeSettingsRepository(
        const AppSettings(themeMode: AppThemeMode.dark),
      ),
    );

    expect(appBrightness(tester), Brightness.dark);
  });

  testWidgets('trocar o tema em Configurações muda o app na hora e grava', (
    tester,
  ) async {
    useSystemBrightness(tester, Brightness.light);
    final settings = FakeSettingsRepository();
    await pumpApp(tester, settings: settings);

    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.themeTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.themeOption(AppThemeMode.dark)));
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(SettingsKeys.themeScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(settings.saved, [const AppSettings(themeMode: AppThemeMode.dark)]);
  });
}
