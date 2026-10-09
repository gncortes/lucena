import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
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
    // O anúncio do lance da máquina chega ao fim, e a vez volta na hora.
    e2eTts.finishes = true;
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
      // O campo fica desligado enquanto a máquina responde e anuncia o lance.
      for (
        var i = 0;
        i < 100 &&
            !$.tester
                .widget<TextField>(find.byKey(BlindKeys.typeField))
                .enabled!;
        i++
      ) {
        await $.pump(const Duration(milliseconds: 100));
      }
      await $(BlindKeys.typeField).enterText(move);
      await $(BlindKeys.typeSend).tap();
      await $.pumpAndSettle();
    }
    // A partida às cegas termina na conclusão (T51).
    await $(ConclusionKeys.screen).waitUntilExists();

    await $(ConclusionKeys.close).tap();
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
