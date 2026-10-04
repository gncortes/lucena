import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';
import 'robots/home_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/settings_robot.dart';

const _queenMate = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';

void main() {
  Future<void> openQueenMateSetup(PatrolIntegrationTester $) async {
    final catalog = CatalogRobot($);
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition('basic.queen.0001');
    await GameSetupRobot($).expectVisible();
  }

  patrolTest('Maia 1400: responde lances legais', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    app.useRealMaia();
    await board.openAt(
      _queenMate,
      opponent: 'maia',
      level: 1400,
      user: Side.white,
      goal: 'win',
      white: '300+0',
      black: '300+0',
    );
    await board.expectPlayerName('Maia 1400');

    // Três lances que valem contra qualquer resposta do rei preto; a lista
    // só aceita lance legal, então seis lances são três respostas legais.
    await board.move('c1', 'g5');
    await board.waitForMoves(2);
    await board.move('c2', 'b2');
    await board.waitForMoves(4);
    await board.move('b2', 'a2');
    final moves = await board.waitForMoves(6);

    expect(moves, hasLength(6));
    expect(moves.first, 'Qg5');
    for (final reply in [moves[1], moves[3], moves[5]]) {
      expect(reply, startsWith('K'));
    }
    board.expectStillPlaying();
    // Quem jogou foi o modelo, não a máquina falsa dos cenários.
    expect(app.fakeMachineRequests, isEmpty);
    expect(app.maiaThinkTimes, hasLength(3));
  });

  patrolTest('perfil com rating perto de 1800: nível sugerido 1800', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    final settings = SettingsRobot($);
    final setup = GameSetupRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await home.openSettings();
    await profile.open();
    // Faixa de 1600 a 1899.
    await profile.chooseLevel(RatingLevel.advanced);
    await profile.save();
    await settings.back();
    await home.expectVisible();

    await openQueenMateSetup($);

    await setup.expectOpponent(OpponentKind.maia);
    await setup.expectLevel(
      1800,
      suggestion: 'Suggested for your rating: 1800',
    );
  });

  patrolTest('trocar para Stockfish e reiniciar: a escolha fica', ($) async {
    final app = AppRobot($);
    final setup = GameSetupRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await openQueenMateSetup($);
    await setup.expectOpponent(OpponentKind.maia);
    await setup.chooseLevel(2000);

    await setup.chooseOpponent(OpponentKind.stockfish);
    setup.expectNoLevels();
    await app.restart();
    await openQueenMateSetup($);

    await setup.expectOpponent(OpponentKind.stockfish);
    setup.expectNoLevels();
    // O nível escolhido antes também ficou.
    await setup.chooseOpponent(OpponentKind.maia);
    await setup.expectLevel(2000);
  });

  patrolTest('posição de empate contra Maia 1000: a partida termina', (
    $,
  ) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    app.useRealMaia();

    // O Maia (brancas) só tem lances de rei; depois o jogador toma o peão e
    // sobram os dois reis.
    await board.openAt(
      '8/7k/7P/8/8/8/8/K7 w - - 0 1',
      opponent: 'maia',
      level: 1000,
      user: Side.black,
      goal: 'draw',
    );
    await board.waitForMoves(1);
    await board.move('h7', 'h6');

    await board.expectEnd(reason: 'Insufficient material', result: 'Draw');
    await board.expectGoalResult('Goal achieved!');
    expect(app.fakeMachineRequests, isEmpty);
  });
}
