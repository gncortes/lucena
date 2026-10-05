import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/home_robot.dart';
import '../robots/journey_robot.dart';
import '../robots/settings_robot.dart';
import '../robots/speedrun_robot.dart';

/// Fumaça da Jornada e do speedrun: tema escuro, árabe, pseudo-idioma longo e
/// segundo plano.
void main() {
  Future<void> walkThrough(PatrolIntegrationTester $, AppRobot app) async {
    final journey = JourneyRobot($);
    final speedrun = SpeedrunRobot($);
    await journey.open();
    app.expectNoClippedText();
    await journey.openRung('1000');
    app.expectNoClippedText();
    await journey.openChallenge('basic.queen.0001');
    app.expectNoClippedText();

    await app.restart();
    await speedrun.open();
    app.expectNoClippedText();
    await speedrun.openSpeedrun('ending.queen');
    app.expectNoClippedText();
    await speedrun.start();
    app.expectNoClippedText();
  }

  patrolTest('Jornada e speedrun em tema escuro', ($) async {
    final app = AppRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await JourneyRobot($).open();
    app.expectBrightness(Brightness.dark);
    await app.restart();
    await SpeedrunRobot($).open();
    app.expectBrightness(Brightness.dark);
  });

  patrolTest('Jornada e speedrun em árabe, sem texto cortado', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await walkThrough($, app);
    app.expectDirection(TextDirection.rtl);
  });

  patrolTest('Jornada e speedrun no pseudo-idioma longo', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.back();
    await settings.back();

    await walkThrough($, app);
  });

  patrolTest('Jornada e tentativa de speedrun voltam do segundo plano', (
    $,
  ) async {
    final app = AppRobot($);
    final journey = JourneyRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await journey.open();
    await journey.openRung('1000');

    await app.sendToBackgroundAndReturn();
    await journey.expectChallengeDone('basic.queen.0001', done: false);

    await app.restart();
    await speedrun.open();
    await speedrun.openSpeedrun('e2e.rung');
    await speedrun.start();
    await app.sendToBackgroundAndReturn();
    speedrun.expectTotal('0:00.0');
    speedrun.expectPlayButton('Play stage 1');
  });
}
