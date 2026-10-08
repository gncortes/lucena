import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/settings_robot.dart';

void main() {
  patrolTest('sistema em português: o app abre em português', ($) async {
    await AppRobot($).open(systemLocale: const Locale('pt', 'BR'));

    await HomeRobot($).expectVisible();
    HomeRobot($).expectJourneyLabel('Jornada');
  });

  patrolTest('trocar para espanhol e reiniciar: continua em espanhol', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.spanish);
    await settings.back();
    await settings.back();
    settings.expectTitle('Ajustes');

    await app.restart();

    await home.expectVisible();
    home.expectJourneyLabel('Recorrido');
  });

  patrolTest('trocar para árabe: layout espelhado e textos em árabe', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.arabic);
    await settings.back();

    settings.expectLanguageValue('العربية');
    app.expectDirection(TextDirection.rtl);
    await settings.backToMenu();
    settings.expectTitle('الإعدادات');

    await settings.back();
    await home.expectVisible();
    home.expectJourneyLabel('الرحلة');
    home.expectSettingsButtonOnLeft();
  });

  patrolTest('voltar para o idioma do sistema: segue o sistema de novo', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'));

    await home.openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.spanish);
    await settings.backToMenu();
    settings.expectTitle('Ajustes');

    await settings.openLanguages();
    await settings.chooseSystemLanguage();
    await settings.back();

    settings.expectLanguageValue('Padrão do sistema');
    await settings.backToMenu();
    settings.expectTitle('Configurações');
  });

  patrolTest('pseudo-idioma longo: nenhum texto cortado nas telas', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    app.expectNoClippedText();

    await settings.back();
    app.expectNoClippedText();

    await settings.openThemes();
    app.expectNoClippedText();
    await settings.backToMenu();
    settings.expectTitle('[Šéttîñĝš one]');
    app.expectNoClippedText();

    await profile.open();
    app.expectNoClippedText();
    await profile.openLevels();
    app.expectNoClippedText();
    await profile.dismissLevels();
    await settings.back();

    await settings.back();
    await home.expectVisible();
    app.expectNoClippedText();
  });
}
