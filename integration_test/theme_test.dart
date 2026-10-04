import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/settings_robot.dart';

void main() {
  patrolTest('escolher escuro e reiniciar: continua escuro', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await settings.openThemes();
    await settings.chooseTheme(AppThemeMode.dark);
    app.expectBrightness(Brightness.dark);
    await settings.back();
    settings.expectThemeValue('Dark');

    await app.restart();

    await home.expectVisible();
    app.expectBrightness(Brightness.dark);
    home.expectMascot(dark: true);
  });

  patrolTest('tema do sistema: o app acompanha o tema do celular', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await settings.openThemes();
    await settings.chooseTheme(AppThemeMode.dark);
    await settings.chooseTheme(AppThemeMode.system);
    app.expectBrightness(Brightness.light);

    await app.enableSystemDarkMode();
    app.expectBrightness(Brightness.dark);

    await app.disableSystemDarkMode();
    app.expectBrightness(Brightness.light);
  });

  patrolTest('escuro e árabe ao mesmo tempo: telas corretas', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await settings.openThemes();
    await settings.chooseTheme(AppThemeMode.dark);
    await settings.back();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.arabic);
    await settings.back();

    settings.expectTitle('الإعدادات');
    settings.expectThemeValue('داكن');
    app.expectBrightness(Brightness.dark);
    app.expectDirection(TextDirection.rtl);
    app.expectNoClippedText();

    await settings.back();
    await home.expectVisible();
    home.expectMascot(dark: true);
    home.expectSettingsButtonOnLeft();
    app.expectBrightness(Brightness.dark);
  });
}
