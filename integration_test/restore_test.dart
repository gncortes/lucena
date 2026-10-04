import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';

const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

// Falta só Dxf7 para o mate do pastor.
const _beforeMate =
    'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4';

void main() {
  patrolTest('relógio rodando: 5 s na tela inicial do celular descontam 5 s', (
    $,
  ) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, white: '300+0', black: '300+0');
    await board.move('e2', 'e4');
    await board.expectClock(Side.black, '5:00');

    await app.sendToBackgroundFor(const Duration(seconds: 5));

    await board.expectVisible();
    await board.expectClock(Side.black, '4:55');
    await board.expectClock(Side.white, '5:00');
    await board.expectMoves(['e4']);
  });

  patrolTest('bloquear a tela e desbloquear: o tempo fica correto', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, white: '180+2', black: '180+2');
    await board.move('e2', 'e4');
    await board.expectClock(Side.white, '3:02');

    await app.lockScreenFor(const Duration(seconds: 42));

    await board.expectClock(Side.black, '2:18');
    await board.expectClock(Side.white, '3:02');

    // A partida continua normalmente depois de desbloquear.
    await board.move('e7', 'e5');
    await board.expectClock(Side.black, '2:20');
  });

  patrolTest('fechar à força e reabrir: mesma posição, lista e tempo', (
    $,
  ) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, white: '180+2', black: '180+2');
    await board.move('e2', 'e4');
    await board.move('e7', 'e5');
    await board.flip();
    await app.advanceTime(const Duration(seconds: 10));
    await board.expectClock(Side.white, '2:52');

    await app.restart();

    // O app reabre direto na partida.
    await board.expectVisible();
    await board.expectMoves(['e4', 'e5']);
    board.expectFen(
      'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
    );
    board.expectOrientation(Side.black);
    await board.expectClock(Side.white, '2:52');
    await board.expectClock(Side.black, '3:02');

    // O relógio continua correndo para quem estava na vez.
    await app.advanceTime(const Duration(seconds: 5));
    await board.expectClock(Side.white, '2:47');
    await board.move('g1', 'f3');
    await board.expectMoves(['e4', 'e5', 'Nf3']);
  });

  patrolTest('o tempo acaba com o app em segundo plano: ao voltar, fim por '
      'tempo', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, white: '5+0', black: '5+0');

    await app.sendToBackgroundFor(const Duration(seconds: 30));

    await board.expectEnd(reason: 'Time out', result: 'Black wins');
    await board.expectClock(Side.white, '0:00.0');
  });

  patrolTest('partida terminada: reabrir não restaura a partida encerrada', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_beforeMate);
    await board.move('h5', 'f7');
    await board.expectEnd(reason: 'Checkmate', result: 'White wins');

    await app.restart();

    await home.expectVisible();
    board.expectNotOpen();

    await board.open();
    board.expectFen(_initialFen);
    await board.expectMoves([]);
  });

  patrolTest('sair da partida: o relógio para, o app reabre na tela inicial e '
      'o botão continua a partida', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.open();
    await board.startClock(minutes: 3, increment: 2);
    await board.move('e2', 'e4');
    await app.advanceTime(const Duration(seconds: 10));
    await board.expectClock(Side.black, '2:50');

    await board.leave();
    await home.expectVisible();
    await app.advanceTime(const Duration(hours: 1));
    await app.restart();

    await home.expectVisible();
    board.expectNotOpen();

    await board.open();
    await board.expectMoves(['e4']);
    await board.expectClock(Side.black, '2:50');
    await board.expectClock(Side.white, '3:02');
  });
}
