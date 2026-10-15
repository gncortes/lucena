import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_sound.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/settings_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('sons desligados nas configurações continuam desligados depois '
      'de fechar à força', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: _english);
    await HomeRobot($).openSettings();
    await settings.expectSound(enabled: true);
    await settings.toggleSound();
    await settings.expectSound(enabled: false);

    await app.restart();
    await HomeRobot($).openSettings();
    await settings.expectSound(enabled: false);
  });

  patrolTest('partida: cada lance faz o seu som', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: _english);
    await board.open();
    await board.drag('e2', 'e4');
    await board.opponentPlays('d7d5');
    await board.drag('e4', 'd5');
    expect(e2eSound.played, [
      GameSound.move,
      GameSound.move,
      GameSound.capture,
    ]);
  });

  patrolTest('com os sons desligados, o tabuleiro fica mudo', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: _english);
    await HomeRobot($).openSettings();
    await SettingsRobot($).toggleSound();
    await SettingsRobot($).backToHome();

    await board.open();
    await board.drag('e2', 'e4');
    await board.opponentPlays('d7d5');
    expect(e2eSound.played, isEmpty);
  });
}
