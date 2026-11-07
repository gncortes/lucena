import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:patrol/patrol.dart';

import 'robots/recorded_journey_robot.dart';

// Jornada gravada 3 da R5 (`docs/tasks/E1.19-qa-r5.md`): a compra na Play só
// quando a A14 sair (H-R5-3A). Até lá, simulada pelo acesso com origem
// compra gravado direto em `acessos/{uid}` (o darCurso não dá compra), sem
// push: a compra de verdade abre o curso na própria tela da loja.
void main() {
  patrolTest('Jornada 3: compra simulada pelo acesso', ($) async {
    final journey = RecordedJourneyRobot($);
    final app = journey.app;
    final marks = journey.marks;
    final student = await journey.signUp('jornada-compra');

    await marks.panel('Simulação: a Play confirma a compra do Pilares');
    await journey.admin.write('acessos/${student.uid}', {
      'cursos': {
        pilaresCourseId: {
          'origem': GrantOrigin.purchase.wire,
          'plano': 'vitalicio',
          'dadoEm': DateTime.now(),
        },
      },
    });
    final access = app.dependencies.courseAccessRepository;
    await app.pumpUntil(() => access.access == CourseAccess.owned);
    await journey.courseUnlockedOnce();
    expect(
      app.dependencies.courseGrantsRepository.current
          .active(pilaresCourseId, DateTime.now())
          ?.origin,
      GrantOrigin.purchase,
    );
    await marks.panel('Painel: o aluno aparece como compra');

    await journey.firstLessonAndProgress(student.uid);
    await journey.admin.write('acessos/${student.uid}', {});
  });
}
