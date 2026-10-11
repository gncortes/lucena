import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/haptic_event.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/settings_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('partida: o lance do jogador vibra, a captura vibra mais', (
    $,
  ) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: _english);
    await board.open();
    await board.drag('e2', 'e4');
    await board.opponentPlays('d7d5');
    await board.drag('e4', 'd5');
    expect(e2eHaptics.events, [
      HapticEvent.move,
      HapticEvent.move,
      HapticEvent.capture,
    ]);
  });

  patrolTest('vibração desligada: nenhum lance chama o aparelho', ($) async {
    final board = FreeBoardRobot($);
    final settings = SettingsRobot($);
    await AppRobot($).open(systemLocale: _english);
    await HomeRobot($).openSettings();
    await settings.expectVibration(enabled: true);
    await settings.toggleVibration();
    await settings.expectVibration(enabled: false);
    await SettingsRobot($).backToHome();

    await board.open();
    await board.drag('e2', 'e4');
    await board.opponentPlays('d7d5');
    expect(e2eHaptics.events, isEmpty);
  });

  patrolTest('vibração desligada continua desligada depois de fechar à força', (
    $,
  ) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: _english);
    await HomeRobot($).openSettings();
    await settings.toggleVibration();
    await app.restart();
    await HomeRobot($).openSettings();
    await settings.expectVibration(enabled: false);
  });
}
