import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';

const _queenMate = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';

void main() {
  patrolTest('jogar um lance: a máquina responde e o relógio dela desconta', (
    $,
  ) async {
    final catalog = CatalogRobot($);
    final setup = GameSetupRobot($);
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition('basic.queen.0001');
    // De fábrica: contra o Stockfish, 5 min para cada lado.
    await setup.start();
    await board.expectVisible();

    await board.move('c1', 'g5');

    // A máquina pensou 2 s (o teto) e respondeu com um lance legal.
    await board.expectClock(Side.black, '4:58');
    await board.expectClock(Side.white, '5:00');
    board.expectFen('8/8/2k5/6Q1/8/8/2K5/8 w - - 2 2');
  });

  patrolTest('mate em um para a máquina: o Stockfish dá o mate', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    app.useRealStockfish();

    // As pretas (a máquina) jogam e têm Ta1#.
    await board.openAt(
      'r5k1/8/8/8/8/8/5PPP/6K1 b - - 0 1',
      opponent: 'stockfish',
      user: Side.white,
    );

    await board.expectEnd(reason: 'Checkmate', result: 'Black wins');
    await board.expectMoves(['Ra1#']);
  });

  patrolTest('máquina com pouco tempo: responde rápido e não perde por tempo', (
    $,
  ) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      _queenMate,
      opponent: 'stockfish',
      user: Side.white,
      white: '300+0',
      black: '1+0',
    );

    await board.move('c1', 'g5');

    // De 1 s, ela gastou só 50 ms e jogou.
    await board.expectClock(Side.black, '0:00.9');
    board.expectFen('8/8/2k5/6Q1/8/8/2K5/8 w - - 2 2');
  });

  patrolTest('desistir na vez da máquina: fim de partida na hora', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      _queenMate,
      opponent: 'stockfish',
      user: Side.white,
      goal: 'win',
    );
    app.holdMachine();
    await board.move('c1', 'g5');

    await board.resign();

    await board.expectEnd(reason: 'Resignation', result: 'Black wins');
    await board.expectGoalResult('Goal not achieved');
    // A resposta atrasada da máquina não entra.
    await app.releaseMachine();
    await board.expectMoves(['Qg5']);
  });
}
