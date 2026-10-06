import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/game_details_robot.dart';

const _english = Locale('en', 'US');

/// Mate de dama contra o Maia, com dois lances fracos das brancas.
final reviewGame = Attempt(
  positionId: 'basic.queen.0001',
  playedAt: DateTime.utc(2026, 1, 1, 11),
  outcome: AttemptOutcome.win,
  fulfilled: true,
  opponent: OpponentKind.maia,
  opponentLevel: 1200,
  startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
  moves: const [
    'c1e3', 'd7d6', 'c2b2', 'd6d7', 'b2c3', 'd7c6', 'c3c4', 'c6c7', //
    'e3e5', 'c7b6', 'e5f6', 'b6a7', 'c4c5', 'a7b8', 'c5b6', 'b8c8', //
    'f6g7', 'c8d8', 'g7f7', 'd8c8', 'f7c7',
  ],
  userSide: Side.white,
  endReason: GameEndReason.checkmate,
);

void main() {
  patrolTest('histórico: revisar a partida, andar lance a lance, ligar a '
      'engine e a revisão continua ao reabrir', ($) async {
    final app = AppRobot($);
    final details = GameDetailsRobot($);
    await app.open(systemLocale: _english);
    final id = await seedAttempt(reviewGame);

    await details.open(id);
    expect(find.byKey(GameDetailsKeys.reviewSummary), findsNothing);
    await details.review();
    await details.expectReviewed();
    await $(GameDetailsKeys.moveQuality(0)).scrollTo();
    // Uma posição por lance e a de início.
    expect(e2eAnalysis.requests.length, reviewGame.moves.length);

    await details.first();
    details.expectShown(-1);
    await details.next();
    await details.next();
    details.expectShown(1);
    await details.last();
    details.expectShown(reviewGame.moves.length - 1);
    await details.previous();
    await details.toggleEngine();
    expect(find.byKey(GameDetailsKeys.engineLines), findsOneWidget);

    await app.restart();
    final requests = e2eAnalysis.requests.length;
    await details.open(id);
    await details.expectReviewed();
    expect(e2eAnalysis.requests.length, requests);
  });
}
