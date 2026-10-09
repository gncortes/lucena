import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/journey_robot.dart';

// Os desafios do degrau 1000 (assets/progression/ladder.json).
const _rung1000 = [
  'basic.queen.0001',
  'basic.queen.0002',
  'basic.rook.0001',
  'basic.rook.0002',
  'basic.twoRooks.0001',
  'basic.twoRooks.0002',
  'pawn.pawnVsKing.0001',
  'pawn.pawnVsKing.0002',
  'pawn.pawnVsKing.0039',
];

// Mate em um: Dh8#. Os desafios são jogados aqui para o cenário não precisar
// dar cada mate de verdade; o que conta para o domínio é o id do desafio.
const _mateInOne = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';

const _english = Locale('en', 'US');

void main() {
  /// Joga o desafio [position] do degrau 1000 a partir da tela inicial e volta
  /// para ela. [won] dá o mate; sem ele, o jogador desiste.
  Future<void> playChallenge(
    PatrolIntegrationTester $,
    String position, {
    bool won = true,
  }) async {
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    await board.openAt(
      _mateInOne,
      opponent: 'maia',
      level: 1000,
      user: Side.white,
      goal: 'win',
      position: position,
      challenge: '1000/$position',
    );
    if (won) {
      await board.move('h1', 'h8');
      await conclusion.expectGoal('Goal achieved!');
    } else {
      await board.resign();
      await conclusion.expectGoal('Goal not achieved');
    }
    await conclusion.close();
    await HomeRobot($).expectVisible();
  }

  patrolTest('concluir todos os desafios do 1000 libera o 1200, e continua '
      'liberado ao reabrir', ($) async {
    final app = AppRobot($);
    final journey = JourneyRobot($);
    await app.open(systemLocale: _english);

    for (final position in _rung1000) {
      await playChallenge($, position);
    }
    await journey.open();
    await journey.expectCompleted('1000');
    await journey.expectUnlocked('1200');
    await journey.expectLocked('1400');
    await journey.expectCurrent('Tito');

    await app.restart();
    await journey.open();
    await journey.expectCompleted('1000');
    await journey.expectUnlocked('1200');
    await journey.expectCurrent('Tito');
  });

  patrolTest('perder um desafio: nada concluído e a partida no histórico', (
    $,
  ) async {
    final app = AppRobot($);
    final journey = JourneyRobot($);
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    await app.open(systemLocale: _english);

    await journey.open();
    await journey.openRung('1000');
    await journey.openChallenge('basic.queen.0001');
    await journey.play();
    await board.resign();
    await conclusion.expectGoal('Goal not achieved');
    // Fechar a conclusão volta ao desafio.
    await conclusion.close();

    journey.expectAttempts(1);
    await journey.back();
    await journey.expectChallengeDone('basic.queen.0001', done: false);
    await journey.back();
    await journey.expectCurrent('Coco');
    await journey.expectLocked('1200');
  });

  patrolTest(
    'fim de um desafio perdido: rating na conclusão e o mesmo desafio de novo',
    ($) async {
      final app = AppRobot($);
      final journey = JourneyRobot($);
      final board = FreeBoardRobot($);
      final conclusion = ConclusionRobot($);
      await app.open(systemLocale: _english);

      await journey.open();
      await journey.openRung('1000');
      await journey.openChallenge('basic.queen.0001');
      await journey.play();
      board.expectBoardFullWidth();
      await board.resign();
      await conclusion.expectGoal('Goal not achieved');
      await conclusion.expectRatingChanged();

      // Perdeu: a conclusão oferece o mesmo desafio de novo, não o próximo
      // (T51).
      conclusion.expectNoAction(ConclusionAction.nextChallenge);
      await conclusion.playAgain();
      expect(board.challengeId, '1000/basic.queen.0001');
      board.expectBoardFullWidth();
    },
  );

  patrolTest('degrau trancado: tocar mostra o que falta', ($) async {
    final app = AppRobot($);
    final journey = JourneyRobot($);
    await app.open(systemLocale: _english);
    await playChallenge($, 'basic.queen.0001');

    await journey.open();

    await journey.tapLockedAndExpectMessage(
      '1200',
      'Complete 8 more challenges against Coco to unlock',
    );
  });

  patrolTest(
    'histórico do desafio: partidas por mês, a mais recente primeiro',
    ($) async {
      final app = AppRobot($);
      final journey = JourneyRobot($);
      await app.open(systemLocale: _english);

      // Uma derrota em janeiro e o mate em fevereiro.
      await playChallenge($, 'basic.rook.0001', won: false);
      await app.advanceTime(const Duration(days: 40));
      await playChallenge($, 'basic.rook.0001');

      await journey.open();
      await journey.openRung('1000');
      await journey.expectChallengeDone('basic.rook.0001');
      await journey.openChallenge('basic.rook.0001');

      journey.expectMonths(['February 2026', 'January 2026']);
      journey.expectAttempts(2);
    },
  );

  patrolTest('atualizar de uma versão com partidas antigas: as marcas do '
      'catálogo continuam', ($) async {
    final app = AppRobot($);
    final catalog = CatalogRobot($);
    final journey = JourneyRobot($);
    await app.open(systemLocale: _english);

    await app.upgradeFromVersion3([
      ('basic.queen.0001', true, 'stockfish'),
      ('basic.queen.0002', false, 'maia'),
    ]);

    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.expectFulfilled('basic.queen.0001');
    await catalog.expectNotFulfilled('basic.queen.0002');

    // Partida antiga não era desafio: a Jornada começa do início.
    await app.restart();
    await journey.open();
    await journey.expectCurrent('Coco');
  });
}
