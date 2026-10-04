import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/settings_robot.dart';

void main() {
  patrolTest('sistema em português: o app abre em português', ($) async {
    await AppRobot($).open(systemLocale: const Locale('pt', 'BR'));

    await HomeRobot($).expectVisible();
    HomeRobot($).expectTagline('Treino de finais de xadrez');
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
    settings.expectTitle('Ajustes');

    await app.restart();

    await home.expectVisible();
    home.expectTagline('Entrenamiento de finales de ajedrez');
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

    settings.expectTitle('الإعدادات');
    settings.expectLanguageValue('العربية');
    app.expectDirection(TextDirection.rtl);

    await settings.back();
    await home.expectVisible();
    home.expectTagline('تدريب نهايات الشطرنج');
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
    await settings.back();
    settings.expectTitle('Ajustes');

    await settings.openLanguages();
    await settings.chooseSystemLanguage();
    await settings.back();

    settings.expectTitle('Configurações');
    settings.expectLanguageValue('Padrão do sistema');
  });

  patrolTest('pseudo-idioma longo: nenhum texto cortado nas telas', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    app.expectNoClippedText();

    await settings.back();
    settings.expectTitle('[Šéttîñĝš one]');
    app.expectNoClippedText();

    await settings.back();
    await home.expectVisible();
    app.expectNoClippedText();
  });
}
