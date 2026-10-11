import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/clock_settings_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/settings_robot.dart';

const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

void main() {
  patrolTest('partida de 5 s sem mexer: bandeira e tela de fim', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, white: '5+0', black: '5+0');
    await board.expectClock(Side.white, '0:05.0');

    await app.advanceTime(const Duration(seconds: 5));

    await board.expectEnd(reason: 'Time out', result: 'Black wins');
    await board.expectClock(Side.white, '0:00.0');

    // Com a bandeira caída, o tabuleiro não aceita mais lances.
    await board.move('e2', 'e4');
    await board.expectMoves([]);
  });

  patrolTest('incremento de 2 s: depois do lance o relógio soma 2 s', (
    $,
  ) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, white: '180+2', black: '180+2');
    await board.expectClock(Side.white, '3:00');

    await board.move('e2', 'e4');

    await board.expectClock(Side.white, '3:02');
    await board.expectClock(Side.black, '3:00');
  });

  patrolTest('tempos diferentes por lado: cada relógio mostra o seu', (
    $,
  ) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, white: '60+0', black: '180+2');

    await board.expectClock(Side.white, '1:00');
    await board.expectClock(Side.black, '3:00');

    await app.advanceTime(const Duration(seconds: 10));
    await board.move('e2', 'e4');
    await board.move('e7', 'e5');

    await board.expectClock(Side.white, '0:50');
    await board.expectClock(Side.black, '3:02');
  });

  patrolTest('abaixo de 10 s aparecem os décimos', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, white: '15+0', black: '15+0');
    await board.expectClock(Side.white, '0:15');

    await app.advanceTime(const Duration(seconds: 5, milliseconds: 500));

    await board.expectClock(Side.white, '0:09.5');
    await board.expectClock(Side.black, '0:15');
  });

  patrolTest('posição do relógio: em cima ou embaixo, muda de lugar', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    final clock = ClockSettingsRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    // De fábrica, um relógio de cada lado do tabuleiro.
    await board.open();
    board.expectNoClock();
    await board.startClock(minutes: 3, increment: 2);
    await board.expectClock(Side.white, '3:00');
    board.expectClockAbove(Side.black);
    board.expectClockBelow(Side.white);
    await settings.back();

    await home.openSettings();
    await clock.open();
    await clock.choosePosition(ClockPosition.top);
    clock.expectPositionValue('Both above the board');
    await settings.backToHome();
    await board.openAt(_initialFen, white: '300+0', black: '300+0');
    board.expectClockAbove(Side.white);
    board.expectClockAbove(Side.black);
    await settings.back();

    await home.openSettings();
    await clock.open();
    await clock.choosePosition(ClockPosition.bottom);
    await app.restart();
    await board.openAt(_initialFen, white: '300+0', black: '300+0');
    board.expectClockBelow(Side.white);
    board.expectClockBelow(Side.black);
  });

  patrolTest('bandeira contra rei sozinho: empate, não derrota', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      'k7/8/8/8/8/8/P7/K7 w - - 0 1',
      white: '5+0',
      black: '5+0',
    );

    await app.advanceTime(const Duration(seconds: 5));

    await board.expectEnd(
      reason: 'Time out vs. insufficient material',
      result: 'Draw',
    );
  });
}
