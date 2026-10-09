import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';
import 'robots/home_robot.dart';

// Uma posição do catálogo, jogada a partir de lances que o cenário controla.
const _positionId = 'basic.queen.0001';

// Mate em um: Dh8#.
const _mateInOne = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';

// Db6 afoga o rei preto.
const _stalemateTrap = 'k7/8/8/2Q5/8/8/8/K7 w - - 0 1';

// O rei preto só tem a8 e b8: a máquina dos cenários vai e volta, e o
// jogador faz o mesmo com o rei dele.
const _fortress = 'k7/p7/P7/8/8/8/8/7K w - - 0 1';

void main() {
  Future<void> openQueenPositions(PatrolIntegrationTester $) async {
    final catalog = CatalogRobot($);
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
  }

  patrolTest('ganhar posição de ganhar: cumprido, marca no catálogo e a marca '
      'continua ao reabrir', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    final catalog = CatalogRobot($);
    final conclusion = ConclusionRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      _mateInOne,
      opponent: 'stockfish',
      user: Side.white,
      goal: 'win',
      position: _positionId,
    );

    await board.move('h1', 'h8');

    await conclusion.expectEnd(title: 'You won!', reason: 'Checkmate');
    await conclusion.expectGoal('Goal achieved!');
    await conclusion.close();
    await openQueenPositions($);
    await catalog.expectFulfilled(_positionId);

    await app.restart();
    await openQueenPositions($);
    await catalog.expectFulfilled(_positionId);
  });

  patrolTest('empatar posição de ganhar: não cumprido', ($) async {
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      _stalemateTrap,
      opponent: 'stockfish',
      user: Side.white,
      goal: 'win',
      position: _positionId,
    );

    await board.move('c5', 'b6');

    await conclusion.expectEnd(title: 'Draw', reason: 'Stalemate');
    await conclusion.expectGoal('Goal not achieved');
  });

  patrolTest('empatar posição de defender: cumprido', ($) async {
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    // As brancas tomam o último peão: só os reis sobram.
    await board.openAt(
      'k7/8/8/8/8/8/3p4/4K3 w - - 0 1',
      opponent: 'stockfish',
      user: Side.white,
      goal: 'draw',
      position: 'pawn.pawnVsKing.0039',
    );

    await board.move('e1', 'd2');

    await conclusion.expectEnd(title: 'Draw', reason: 'Insufficient material');
    await conclusion.expectGoal('Goal achieved!');
  });

  patrolTest('o histórico mostra as tentativas em ordem', ($) async {
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    final catalog = CatalogRobot($);
    final setup = GameSetupRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      _stalemateTrap,
      opponent: 'stockfish',
      user: Side.white,
      goal: 'win',
      position: _positionId,
    );
    await board.move('c5', 'b6');
    await conclusion.expectGoal('Goal not achieved');
    await conclusion.close();
    await HomeRobot($).expectVisible();
    await board.openAt(
      _mateInOne,
      opponent: 'stockfish',
      user: Side.white,
      goal: 'win',
      position: _positionId,
    );
    await board.move('h1', 'h8');
    await conclusion.expectGoal('Goal achieved!');
    await conclusion.close();

    await openQueenPositions($);
    await catalog.openPosition(_positionId);
    await setup.expectVisible();

    // A mais recente primeiro.
    await setup.expectAttempts(['Win', 'Draw']);
  });

  patrolTest('jogar de novo a partir do resultado: mesma posição e '
      'configuração', ($) async {
    final catalog = CatalogRobot($);
    final setup = GameSetupRobot($);
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition(_positionId);
    await setup.setTime('user', minutes: 3, increment: 2);
    await setup.start();
    await board.move('c1', 'g5');
    await board.resign();
    await conclusion.expectEnd(title: 'You lost', reason: 'Resignation');
    await conclusion.expectGoal('Goal not achieved');

    await conclusion.playAgain();

    board.expectFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1');
    await board.expectMoves([]);
    await board.expectClock(Side.white, '3:00');
    await board.expectClock(Side.black, '5:00');
    board.expectOrientation(Side.white);
  });

  patrolTest('repetir a posição três vezes contra a máquina: empate, e o '
      'objetivo de empatar fica cumprido', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      _fortress,
      opponent: 'stockfish',
      user: Side.white,
      goal: 'draw',
      position: _positionId,
    );

    await board.move('h1', 'g1');
    await board.move('g1', 'h1');
    // A posição inicial apareceu duas vezes: a partida continua, inclusive
    // depois de fechar e abrir o app.
    board.expectStillPlaying();
    await app.restart();
    await board.expectVisible();
    await board.move('h1', 'g1');
    await board.move('g1', 'h1');

    await conclusion.expectEnd(title: 'Draw', reason: 'Threefold repetition');
    await conclusion.expectGoal('Goal achieved!');
  });
}
