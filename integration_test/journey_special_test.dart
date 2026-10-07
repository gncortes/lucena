import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/journey_robot.dart';

const _english = Locale('en', 'US');
const _special = '1000/blind.basic.twoRooks.0001';

/// O desafio especial às cegas do 1000: liberado depois de vencer o mesmo
/// final no modo normal; jogado digitando os lances; fica cumprido.
void main() {
  patrolTest('desafio às cegas da Jornada: digitar os lances até o mate e o '
      'especial fica cumprido', ($) async {
    final app = AppRobot($);
    final journey = JourneyRobot($);
    await app.open(systemLocale: _english);
    // O mesmo final já vencido no modo normal: o especial libera.
    await seedAttempt(
      Attempt(
        positionId: 'basic.twoRooks.0001',
        playedAt: DateTime.utc(2026, 10, 7),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        challengeId: '1000/basic.twoRooks.0001',
      ),
    );
    await app.restart();
    await journey.open();
    await journey.openRung('1000');
    await $(JourneyKeys.special(_special)).scrollTo().tap();

    await $(BlindKeys.start).waitUntilVisible();
    await $(BlindKeys.start).tap();
    await $.pumpAndSettle();
    // Os lances calculados contra a máquina dos cenários, até o mate.
    for (final move in ['Re2', 'Ra4', 'Rd4', 'Re3']) {
      await $(BlindKeys.typeField).waitUntilVisible();
      await $(BlindKeys.typeField).enterText(move);
      await $(BlindKeys.typeSend).tap();
      await $.pumpAndSettle();
    }
    await $(BlindKeys.result).waitUntilExists();

    await $.tester.pageBack();
    await $.pumpAndSettle();
    await $(JourneyKeys.special(_special)).scrollTo();
    expect(
      find.descendant(
        of: find.byKey(JourneyKeys.special(_special)),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });
}
