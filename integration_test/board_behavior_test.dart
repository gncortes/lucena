import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/board_behavior_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/settings_robot.dart';

const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

void main() {
  patrolTest('só tocar: arrastar não move a peça, tocar move', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    final behavior = BoardBehaviorRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await home.openSettings();
    await behavior.open();

    await behavior.chooseMoveMethod(MoveMethod.tap);
    behavior.expectMoveMethodValue('Tap only');
    await settings.back();
    await settings.back();
    await board.open();

    await board.drag('e2', 'e4');
    await board.expectMoves([]);
    board.expectFen(_initialFen);

    await board.move('g1', 'f3');
    await board.expectMoves(['Nf3']);
  });

  patrolTest('desligar os lances legais: continua desligado ao reabrir', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    final behavior = BoardBehaviorRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await home.openSettings();
    await behavior.open();
    behavior.expectLegalMoves(enabled: true);

    await behavior.toggleLegalMoves();
    behavior.expectLegalMoves(enabled: false);

    await app.restart();
    await home.openSettings();
    await behavior.open();
    behavior.expectLegalMoves(enabled: false);

    await settings.back();
    await settings.back();
    await board.open();
    board.expectShowsLegalMoves(enabled: false);
  });

  patrolTest('virar o tabuleiro: orientação invertida e lista inalterada', (
    $,
  ) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.open();
    await board.move('e2', 'e4');
    await board.move('e7', 'e5');
    board.expectOrientation(Side.white);

    await board.flip();

    board.expectOrientation(Side.black);
    await board.expectMoves(['e4', 'e5']);
    board.expectFen(
      'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
    );

    // Com o tabuleiro virado, as casas trocam de lugar na tela.
    await board.move('g1', 'f3');
    await board.expectMoves(['e4', 'e5', 'Nf3']);
  });

  patrolTest('notação por letras em português: a lista mostra C, B, T, D e R', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final behavior = BoardBehaviorRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'));
    await home.openSettings();
    await behavior.open();

    await behavior.chooseNotation(MoveNotation.letters);
    behavior.expectNotationValue('Letras');

    await app.restart();
    await board.openAt('4k3/8/8/8/8/8/8/R1BQKBN1 w - - 0 1');
    await board.move('g1', 'f3');
    await board.move('e8', 'e7');
    await board.move('f1', 'c4');
    await board.move('e7', 'f6');
    await board.move('d1', 'd4');
    await board.move('f6', 'e7');
    await board.move('a1', 'a7');

    await board.expectMoveTexts([
      'Cf3',
      'Re7',
      'Bc4',
      'Rf6',
      'Dd4+',
      'Re7',
      'Ta7+',
    ]);
  });

  patrolTest('pré-lance feito na vez do adversário é jogado em seguida', (
    $,
  ) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await board.openAt(_initialFen, side: Side.white);
    await board.move('e2', 'e4');

    // Vez das pretas: o lance das brancas fica só marcado.
    await board.move('d2', 'd4');
    await board.expectMoves(['e4']);
    board.expectPremove('d2d4');

    await board.opponentPlays('e7e5');

    await board.expectMoves(['e4', 'e5', 'd4']);
    board.expectPremove(null);
    board.expectFen(
      'rnbqkbnr/pppp1ppp/8/4p3/3PP3/8/PPP2PPP/RNBQKBNR b KQkq - 0 2',
    );
  });
}
