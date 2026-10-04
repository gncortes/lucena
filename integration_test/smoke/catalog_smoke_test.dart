import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/catalog_robot.dart';
import '../robots/custom_position_robot.dart';
import '../robots/game_setup_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

/// Fumaça do catálogo, da configuração da partida e da posição personalizada:
/// tema escuro, árabe, segundo plano e textos longos.
void main() {
  Future<void> openSetup(PatrolIntegrationTester $) async {
    final catalog = CatalogRobot($);
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition('basic.queen.0001');
    await GameSetupRobot($).expectVisible();
  }

  patrolTest('catálogo, configuração e posição personalizada em tema escuro', (
    $,
  ) async {
    final app = AppRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await openSetup($);
    app.expectBrightness(Brightness.dark);

    await app.open(systemLocale: const Locale('en', 'US'));
    await CustomPositionRobot($).open();
    app.expectBrightness(Brightness.dark);
  });

  patrolTest('catálogo, configuração e posição personalizada em árabe', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await openSetup($);
    app.expectDirection(TextDirection.rtl);
    app.expectNoClippedText();

    await app.open(systemLocale: const Locale('ar'));
    await CustomPositionRobot($).open();
    app.expectNoClippedText();
  });

  patrolTest('configuração e posição personalizada voltam do segundo plano', (
    $,
  ) async {
    final app = AppRobot($);
    final setup = GameSetupRobot($);
    final custom = CustomPositionRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await openSetup($);
    await setup.setTime('user', minutes: 3, increment: 2);

    await app.sendToBackgroundAndReturn();
    await setup.expectVisible();
    setup.expectTime('user', minutes: 3, increment: 2);

    await app.open(systemLocale: const Locale('en', 'US'));
    await custom.open();
    await custom.typeFen('4k3/8/8/8/8/8/4P3/4K3 w - - 0 1');
    await app.sendToBackgroundAndReturn();
    await custom.expectVisible();
    custom.expectFen('4k3/8/8/8/8/8/4P3/4K3 w - - 0 1');
  });

  patrolTest('a posição personalizada volta depois de fechar o app', ($) async {
    final app = AppRobot($);
    final custom = CustomPositionRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await custom.open();
    await custom.typeFen('4k3/8/8/8/8/8/4P3/4K3 w - - 0 1');

    await app.restart();
    await HomeRobot($).expectVisible();
    await custom.open();

    custom.expectFen('4k3/8/8/8/8/8/4P3/4K3 w - - 0 1');
  });

  patrolTest('pseudo-idioma longo: nada cortado nas telas novas', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.back();
    await settings.back();
    app.expectNoClippedText();

    final catalog = CatalogRobot($);
    await catalog.open();
    app.expectNoClippedText();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    app.expectNoClippedText();
    await catalog.openPosition('basic.queen.0001');
    await GameSetupRobot($).expectVisible();
    app.expectNoClippedText();

    await app.restart();
    await CustomPositionRobot($).open();
    app.expectNoClippedText();
  });
}
