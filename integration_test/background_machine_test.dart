import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';

const _queenMate = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';

void main() {
  Future<void> startAgainstMachine(PatrolIntegrationTester $) async {
    await FreeBoardRobot($).openAt(
      _queenMate,
      opponent: 'stockfish',
      user: Side.white,
      white: '300+0',
      black: '300+0',
    );
  }

  patrolTest('sair durante a vez da máquina e voltar: a partida continua', (
    $,
  ) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await startAgainstMachine($);
    app.holdMachine();
    await board.move('c1', 'g5');

    await app.sendToBackgroundFor(const Duration(seconds: 5));
    // O relógio da máquina correu enquanto o app estava fora.
    await board.expectClock(Side.black, '4:55');
    await app.releaseMachine();

    // Ela pensou mais 2 s e jogou; o jogador volta a ter a vez.
    await board.expectClock(Side.black, '4:53');
    board.expectFen('8/8/2k5/6Q1/8/8/2K5/8 w - - 2 2');
  });

  patrolTest('fechar à força durante a vez da máquina: reabre e a máquina '
      'joga', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await startAgainstMachine($);
    app.holdMachine();
    await board.move('c1', 'g5');

    await app.restart();
    await board.expectVisible();
    await board.expectMoves(['Qg5']);

    await app.releaseMachine();
    await board.expectMoves(['Qg5', 'Kc6']);
    board.expectFen('8/8/2k5/6Q1/8/8/2K5/8 w - - 2 2');
  });

  patrolTest('bloquear a tela durante a vez da máquina: tudo consistente', (
    $,
  ) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await startAgainstMachine($);
    app.holdMachine();
    await board.move('c1', 'g5');

    await app.lockScreenFor(const Duration(seconds: 20));
    await board.expectClock(Side.black, '4:40');
    await app.releaseMachine();

    await board.expectClock(Side.black, '4:38');
    await board.expectClock(Side.white, '5:00');
    await board.expectMoves(['Qg5', 'Kc6']);
  });
}
