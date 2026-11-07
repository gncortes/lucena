import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/feedback_entry.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/feedback_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/emulator_admin.dart';
import 'robots/recorded_journey_robot.dart';

/// Os alunos de QA que entram no público junto com o da jornada (os
/// roteiros usam os de 1 a 9).
const _others = [21, 22, 23];

// Jornada gravada 5 da R5 (`docs/tasks/E1.19-qa-r5.md`): o painel manda um
// push para quem tem o Pilares (vários alunos), o aluno toca e cai no final
// do dia; depois manda uma opinião, que chega em /usuarios/opinioes.
void main() {
  patrolTest('Jornada 5: push por curso e opinião', ($) async {
    final journey = RecordedJourneyRobot($);
    final app = journey.app;
    final admin = journey.admin;
    final marks = journey.marks;
    final student = await journey.signUp('jornada-push');
    final uids = [student.uid];
    for (final n in _others) {
      final other = await admin.signIn(
        EmulatorAdmin.student(n),
        EmulatorAdmin.studentPassword,
      );
      await admin.write('acessos/${other.uid}', {});
      await admin.giveCourse(other.uid);
      uids.add(other.uid);
    }
    await admin.giveCourse(student.uid);
    await journey.courseUnlockedOnce();

    const title = 'Final do dia';
    const text = 'Um final novo para treinar';
    final link = AppLinks.uri('/${AppLinks.dailySegment}').toString();
    await marks.panel('Painel: Push para quem tem o Pilares');
    await journey.toBackground();
    final sent = await admin.call('enviarPush', {
      'destino': {'tipo': 'publico', 'curso': pilaresCourseId},
      'titulo': title,
      'texto': text,
      'tipo': 'livre',
      'link': link,
    });
    final counts = sent['contagens'] as Map?;
    expect(counts?['pessoas'], greaterThanOrEqualTo(uids.length));
    await marks.panel('Painel: o push sai para ${counts?['pessoas']} alunos');
    await journey.pushArrives(title, text, {
      'tipo': 'livre',
      'pushId': sent['id']! as String,
      'titulo': title,
      'texto': text,
      'link': link,
    });
    // O `/daily` troca a si mesmo pela partida do final de hoje.
    await app.pumpUntil(() => app.location == Routes.freeBoard);
    await marks.step('O push abre o final do dia');
    await marks.hold(2500);

    final opinion = 'Gostei do final do dia ${Random().nextInt(1 << 20)}';
    await marks.step('O aluno manda uma opinião');
    await app.go(Routes.feedback);
    await $(FeedbackKeys.screen).waitUntilVisible();
    await $(FeedbackKeys.kindChip(FeedbackType.idea)).tap();
    await $(FeedbackKeys.text).enterText(opinion);
    await marks.hold(1000);
    await $(FeedbackKeys.send).tap();
    await $(FeedbackKeys.thanks)
        .waitUntilVisible(timeout: const Duration(seconds: 30));
    await marks.step('Opinião enviada');
    final entries = await admin.where('feedback', 'uid', student.uid);
    expect(entries.where((e) => e['text'] == opinion), hasLength(1));
    await marks.panel('Painel: a opinião chega em /usuarios/opinioes');
    await marks.hold(2000);

    for (final uid in uids) {
      await admin.revokeCourse(uid);
    }
  });
}
