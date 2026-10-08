import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/catalog_robot.dart';
import '../robots/game_setup_robot.dart';
import '../robots/home_robot.dart';
import '../robots/maia_debug_robot.dart';
import '../robots/settings_robot.dart';

/// Fumaça das telas do Maia (depuração e escolha de nível): tema escuro,
/// árabe, textos longos e segundo plano.
void main() {
  Future<void> openSetup(PatrolIntegrationTester $) async {
    final catalog = CatalogRobot($);
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition('basic.queen.0001');
    await GameSetupRobot($).expectVisible();
  }

  Future<void> choosePseudoLanguage(PatrolIntegrationTester $) async {
    final settings = SettingsRobot($);
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.backToHome();
    await HomeRobot($).expectVisible();
  }

  patrolTest('depuração do Maia em tema escuro', ($) async {
    final app = AppRobot($);
    final maia = MaiaDebugRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));
    await maia.open();

    await maia.evaluate();

    app.expectBrightness(Brightness.dark);
    await maia.expectResult();
  });

  patrolTest('depuração do Maia em árabe: nada cortado', ($) async {
    final app = AppRobot($);
    final maia = MaiaDebugRobot($);
    await app.open(systemLocale: const Locale('ar'));
    await maia.open();

    await maia.evaluate();

    app.expectDirection(TextDirection.rtl);
    await maia.expectResult();
    // O lance (UCI) não muda com o idioma.
    await maia.expectBest('a1a4');
    app.expectNoClippedText();
  });

  patrolTest('depuração do Maia: o resultado continua depois do segundo '
      'plano', ($) async {
    final app = AppRobot($);
    final maia = MaiaDebugRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await maia.open();
    await maia.chooseLevel(1800);
    await maia.evaluate();
    await maia.expectBest('a1a4', probability: '37.6%');

    await app.sendToBackgroundAndReturn();

    await maia.expectBest('a1a4', probability: '37.6%');
    // E o modelo continua respondendo.
    await maia.chooseLevel(1000);
    await maia.evaluate();
    await maia.expectBest('a1a5');
  });

  patrolTest('pseudo-idioma longo: nada cortado nas telas do Maia', ($) async {
    final app = AppRobot($);
    final maia = MaiaDebugRobot($);
    final setup = GameSetupRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await choosePseudoLanguage($);

    await maia.open();
    await maia.evaluate();
    await maia.expectResult();
    app.expectNoClippedText();
    await SettingsRobot($).back();
    await SettingsRobot($).back();
    await HomeRobot($).expectVisible();

    await openSetup($);
    await setup.expectLevel(1200);
    app.expectNoClippedText();
  });

  patrolTest('níveis do Maia em tema escuro e em árabe', ($) async {
    final app = AppRobot($);
    final setup = GameSetupRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('ar'));
    await openSetup($);

    await setup.chooseLevel(1600);

    app.expectBrightness(Brightness.dark);
    app.expectDirection(TextDirection.rtl);
    await setup.expectLevel(1600, suggestion: 'المقترح لتصنيفك: 1200');
    app.expectNoClippedText();
  });

  patrolTest('níveis do Maia: a escolha continua depois do segundo plano', (
    $,
  ) async {
    final app = AppRobot($);
    final setup = GameSetupRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await openSetup($);
    await setup.chooseLevel(2200);

    await app.sendToBackgroundAndReturn();

    await setup.expectOpponent(OpponentKind.maia);
    await setup.expectLevel(2200);
  });
}
