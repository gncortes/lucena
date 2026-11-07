import 'package:lucena/domain/models/course_grant.dart';
import 'package:patrol/patrol.dart';

import 'robots/recorded_journey_robot.dart';

// Jornada gravada 2 da R5: igual à 1, com o curso dado como pago por fora e o
// push no texto de pagamento (`textoDoPush` da Function), não no de presente.
void main() {
  patrolTest('Jornada 2: pago por fora pelo painel', ($) async {
    await RecordedJourneyRobot($).giftJourney(
      origin: 'pagoPorFora',
      expected: GrantOrigin.paidOutside,
      caption: 'Painel: Dar curso, Pilares, pago por fora',
    );
  });
}
