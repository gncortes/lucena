import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/clock_settings_robot.dart';
import '../robots/free_board_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

/// Fumaça do relógio (tela de preferências e relógio na partida): tema escuro,
/// árabe, segundo plano e textos longos.
void main() {
  patrolTest('relógio em tema escuro: preferências e partida', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    final clock = ClockSettingsRobot($);
    final board = FreeBoardRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await HomeRobot($).openSettings();
    await clock.open();
    app.expectBrightness(Brightness.dark);
    await clock.toggleVibration();
    clock.expectVibration(enabled: false);
    await settings.backToHome();

    await board.openAt(_initialFen, white: '300+0', black: '300+0');
    app.expectBrightness(Brightness.dark);
    await board.expectClock(Side.white, '5:00');
  });

  patrolTest('relógio em árabe: a interface espelha, os números não', (
    $,
  ) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    final clock = ClockSettingsRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await HomeRobot($).openSettings();
    await clock.open();
    app.expectDirection(TextDirection.rtl);
    app.expectNoClippedText();
    await settings.backToHome();

    await board.openAt(_initialFen, white: '180+2', black: '180+2');
    await board.move('e2', 'e4');
    await board.expectClock(Side.white, '3:02');
    app.expectNoClippedText();
  });

  patrolTest('preferências do relógio voltam do segundo plano iguais', (
    $,
  ) async {
    final app = AppRobot($);
    final clock = ClockSettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await clock.open();
    await clock.toggleVibration();

    await app.sendToBackgroundAndReturn();

    await clock.expectVisible();
    clock.expectVibration(enabled: false);
  });

  patrolTest('pseudo-idioma longo: nada cortado no relógio', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    final clock = ClockSettingsRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.back();

    await clock.open();
    app.expectNoClippedText();
    await clock.openPositions();
    app.expectNoClippedText();
    await app.restart();

    await board.openAt(_initialFen, white: '300+0', black: '300+0');
    await board.expectClock(Side.black, '5:00');
    app.expectNoClippedText();

    await board.openClockSheet();
    app.expectNoClippedText();
  });
}
