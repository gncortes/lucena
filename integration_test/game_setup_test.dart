import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';

void main() {
  /// Abre a configuração da primeira posição de mate com a dama.
  Future<void> openSetup(PatrolIntegrationTester $) async {
    final catalog = CatalogRobot($);
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition('basic.queen.0001');
    await GameSetupRobot($).expectVisible();
  }

  patrolTest('3+2 para o jogador e 1+0 para o adversário: relógios corretos', (
    $,
  ) async {
    final setup = GameSetupRobot($);
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await openSetup($);

    await setup.setTime('user', minutes: 3, increment: 2);
    await setup.setTime('opponent', minutes: 1, increment: 0);
    await setup.start();

    await board.expectVisible();
    // O jogador está com as brancas, que jogam na posição.
    await board.expectClock(Side.white, '3:00');
    await board.expectClock(Side.black, '1:00');
    await board.move('c1', 'h6');
    await board.expectClock(Side.white, '3:02');
  });

  patrolTest('reiniciar: a configuração continua a mesma', ($) async {
    final app = AppRobot($);
    final setup = GameSetupRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await openSetup($);
    await setup.setTime('user', minutes: 3, increment: 2);
    await setup.setTime('opponent', minutes: 1, increment: 0);

    await app.restart();
    await openSetup($);

    setup.expectTime('user', minutes: 3, increment: 2);
    setup.expectTime('opponent', minutes: 1, increment: 0);
  });

  patrolTest('tempo zero: bloqueado com erro', ($) async {
    final setup = GameSetupRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await openSetup($);

    await setup.setTime('opponent', minutes: 0, increment: 0);

    await setup.expectZeroTimeError();
  });

  patrolTest('trocar o lado: o tabuleiro vira para o jogador', ($) async {
    final setup = GameSetupRobot($);
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await openSetup($);
    setup.expectPreviewOrientation(Side.white);

    await setup.chooseSide(Side.black);
    setup.expectPreviewOrientation(Side.black);
    await setup.start();

    await board.expectVisible();
    board.expectOrientation(Side.black);
    // A máquina ficou com as brancas, que jogam na posição: ela começa.
    await board.expectMoves(['Qa1']);
  });
}
