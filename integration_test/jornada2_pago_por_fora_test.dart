import 'package:lucena/domain/models/course_grant.dart';
import 'package:patrol/patrol.dart';

import 'robots/recorded_journey_robot.dart';

// Jornada gravada 2 da R5: igual à 1, com o curso dado como pago por fora.
// O roteiro pede o push no texto de compra; a Function manda hoje o mesmo
// texto do presente para as duas origens (lacuna avisada ao SRV), e o vídeo
// mostra o que ela manda.
void main() {
  patrolTest('Jornada 2: pago por fora pelo painel', ($) async {
    await RecordedJourneyRobot($).giftJourney(
      origin: 'pagoPorFora',
      expected: GrantOrigin.paidOutside,
      caption: 'Painel: Dar curso, Pilares, pago por fora',
    );
  });
}
