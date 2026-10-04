import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

/// Fumaça de Configurações e das telas de idioma e de tema: tema escuro, árabe,
/// segundo plano.
void main() {
  patrolTest('configurações e idioma em tema escuro', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await HomeRobot($).openSettings();
    await settings.expectVisible();
    settings.expectTitle('Settings');

    await settings.openLanguages();
    await settings.expectLanguagesVisible();
    await settings.back();

    await settings.openThemes();
    await settings.expectThemesVisible();
    app.expectBrightness(Brightness.dark);
  });

  patrolTest('configurações e idioma em árabe', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await HomeRobot($).openSettings();
    await settings.expectVisible();
    settings.expectTitle('الإعدادات');
    app.expectDirection(TextDirection.rtl);

    await settings.openLanguages();
    await settings.expectLanguagesVisible();
    app.expectNoClippedText();
    await settings.back();

    await settings.openThemes();
    await settings.expectThemesVisible();
    app.expectNoClippedText();
  });

  patrolTest('tela de idioma volta do segundo plano no mesmo lugar', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();

    await app.sendToBackgroundAndReturn();

    await settings.expectLanguagesVisible();
  });

  patrolTest('tela de tema volta do segundo plano no mesmo lugar', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openThemes();

    await app.sendToBackgroundAndReturn();

    await settings.expectThemesVisible();
  });
}
