import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';

const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

void main() {
  patrolTest('e4 e5 Cf3: a lista mostra os três lances', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.open();
    board.expectFen(_initialFen);

    await board.move('e2', 'e4');
    await board.move('e7', 'e5');
    await board.move('g1', 'f3');

    await board.expectMoves(['e4', 'e5', 'Nf3']);
    board.expectTurn('Black to move');
    board.expectFen(
      'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
    );
  });

  patrolTest('rever a partida: tocar num lance mostra aquele momento, sem '
      'mexer nas peças; avançar volta para a partida', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open();
    await board.open();
    await board.move('e2', 'e4');
    await board.move('e7', 'e5');
    await board.move('g1', 'f3');

    // O primeiro lance: só o peão do rei saiu.
    await board.viewMove(0);
    board.expectPieceAt('e4', Piece.whitePawn);
    board.expectPieceAt('e5', null);
    board.expectPieceAt('g1', Piece.whiteKnight);
    // Revendo, o tabuleiro não aceita lances.
    await board.move('d7', 'd5');
    board.expectPieceAt('d7', Piece.blackPawn);
    await board.expectMoves(['e4', 'e5', 'Nf3']);

    await board.viewPrevious();
    board.expectPieceAt('e2', Piece.whitePawn);
    await board.viewNext();
    await board.viewNext();
    await board.viewNext();
    board.expectPieceAt('f3', Piece.whiteKnight);
    // De volta à partida: o lance entra.
    await board.move('b8', 'c6');
    await board.expectMoves(['e4', 'e5', 'Nf3', 'Nc6']);
  });

  patrolTest('lance ilegal: a peça volta e nada muda', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.open();

    await board.drag('e2', 'e5');
    await board.move('g1', 'g3');
    await board.move('e7', 'e5');

    board.expectFen(_initialFen);
    await board.expectMoves([]);
    board.expectTurn('White to move');
  });

  patrolTest('roque pequeno numa posição preparada', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
    );

    await board.move('e1', 'g1');

    await board.expectMoves(['O-O']);
    board.expectFen(
      'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 b kq - 5 4',
    );
  });

  patrolTest('en passant numa posição preparada', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.openAt(
      'rnbqkbnr/1pp1pppp/p7/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
    );

    await board.move('e5', 'd6');

    await board.expectMoves(['exd6']);
    board.expectFen(
      'rnbqkbnr/1pp1pppp/p2P4/8/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 3',
    );
  });

  patrolTest('promover a cavalo (subpromoção)', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.openAt('8/P6k/8/8/8/8/8/K7 w - - 0 1');

    await board.move('a7', 'a8');
    await board.promoteTo('a8', Role.knight);

    await board.expectMoves(['a8=N']);
    board.expectFen('N7/7k/8/8/8/8/8/K7 b - - 0 1');
  });

  patrolTest('mate do pastor: fim de partida', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.open();

    await board.move('e2', 'e4');
    await board.move('e7', 'e5');
    await board.move('f1', 'c4');
    await board.move('b8', 'c6');
    await board.move('d1', 'h5');
    await board.move('g8', 'f6');
    await board.move('h5', 'f7');

    await board.expectEnd(reason: 'Checkmate', result: 'White wins');
    await board.expectMoves(['e4', 'e5', 'Bc4', 'Nc6', 'Qh5', 'Nf6', 'Qxf7#']);

    // Com a partida terminada, o tabuleiro não aceita mais lances.
    await board.move('e8', 'f7');
    await board.expectMoves(['e4', 'e5', 'Bc4', 'Nc6', 'Qh5', 'Nf6', 'Qxf7#']);

    await board.newGame();
    board.expectFen(_initialFen);
    await board.expectMoves([]);
  });
}
