import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/board_behavior_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

/// Fumaça do comportamento do tabuleiro: tema escuro, árabe, segundo plano e
/// textos longos.
void main() {
  patrolTest('comportamento do tabuleiro em tema escuro', ($) async {
    final app = AppRobot($);
    final behavior = BoardBehaviorRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await HomeRobot($).openSettings();
    await behavior.open();

    app.expectBrightness(Brightness.dark);
    await behavior.chooseMoveMethod(MoveMethod.drag);
    behavior.expectMoveMethodValue('Drag only');
  });

  patrolTest('comportamento do tabuleiro em árabe', ($) async {
    final app = AppRobot($);
    final behavior = BoardBehaviorRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await HomeRobot($).openSettings();
    await behavior.open();

    app.expectDirection(TextDirection.rtl);
    behavior.expectMoveMethodValue('السحب أو اللمس');
    app.expectNoClippedText();

    await behavior.openMoveMethods();
    app.expectNoClippedText();
  });

  patrolTest('comportamento do tabuleiro volta do segundo plano igual', (
    $,
  ) async {
    final app = AppRobot($);
    final behavior = BoardBehaviorRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await behavior.open();
    await behavior.toggleLegalMoves();

    await app.sendToBackgroundAndReturn();

    await behavior.expectVisible();
    behavior.expectLegalMoves(enabled: false);
  });

  patrolTest('pseudo-idioma longo: nada cortado no comportamento', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    final behavior = BoardBehaviorRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.back();

    await behavior.open();
    app.expectNoClippedText();

    await behavior.openMoveMethods();
    app.expectNoClippedText();
  });
}
