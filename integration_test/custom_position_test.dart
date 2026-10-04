import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/custom_position_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';

void main() {
  patrolTest('FEN inválido: erro', ($) async {
    final custom = CustomPositionRobot($);
    await AppRobot($).open(systemLocale: const Locale('pt', 'BR'));
    await custom.open();

    await custom.typeFen('isto não é um FEN');

    await custom.expectError('Isso não é um FEN válido.');
  });

  patrolTest('FEN sem rei: erro que diz qual rei falta', ($) async {
    final custom = CustomPositionRobot($);
    await AppRobot($).open(systemLocale: const Locale('pt', 'BR'));
    await custom.open();

    await custom.typeFen('4k3/8/8/8/8/8/4P3/8 w - - 0 1');

    await custom.expectError('Falta o rei das brancas.');
  });

  patrolTest('o lado que não joga em xeque: erro', ($) async {
    final custom = CustomPositionRobot($);
    await AppRobot($).open(systemLocale: const Locale('pt', 'BR'));
    await custom.open();

    await custom.typeFen('R3k3/8/8/8/8/8/8/4K3 w - - 0 1');

    await custom.expectError('O lado que não joga está em xeque.');
  });

  patrolTest('montar no editor e iniciar: a partida começa', ($) async {
    final custom = CustomPositionRobot($);
    final setup = GameSetupRobot($);
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await custom.open();

    // Os dois reis já estão lá: falta a dama.
    await custom.place(Piece.whiteQueen, ['d1']);
    custom.expectNoError();
    custom.expectFen('4k3/8/8/8/8/8/8/3QK3 w - - 0 1');

    await custom.continueToSetup();
    await setup.expectVisible();
    await setup.start();

    await board.expectVisible();
    board.expectFen('4k3/8/8/8/8/8/8/3QK3 w - - 0 1');
    // De fábrica, a máquina joga o outro lado e responde.
    await board.move('d1', 'd4');
    await board.expectMoves(['Qd4', 'Ke7']);
  });

  patrolTest('colar FEN válido: a partida começa no lado certo', ($) async {
    final custom = CustomPositionRobot($);
    final setup = GameSetupRobot($);
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await custom.open();

    await custom.typeFen('8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');
    custom.expectNoError();
    await custom.continueToSetup();
    await setup.start();

    await board.expectVisible();
    board.expectFen('8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');
    board.expectOrientation(Side.black);
    // Com relógio (a configuração de fábrica): o das pretas aparece.
    await board.expectClock(Side.black, '5:00');
  });
}
