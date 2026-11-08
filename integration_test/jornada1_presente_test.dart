import 'package:lucena/domain/models/course_grant.dart';
import 'package:patrol/patrol.dart';

import 'robots/recorded_journey_robot.dart';

// Jornada gravada 1 da R5 (`docs/tasks/E1.19-qa-r5.md`): o aluno se cadastra,
// o painel dá o Pilares como presente, o push chega, o aluno abre o curso,
// faz a 1ª lição e o painel mostra o progresso. Rodar por
// `tools/jornadas_r5.sh 1` (grava o vídeo com as legendas).
void main() {
  patrolTest('Jornada 1: presente pelo painel', ($) async {
    await RecordedJourneyRobot($)
        .giftJourney(origin: 'presente', expected: GrantOrigin.gift);
  });
}
