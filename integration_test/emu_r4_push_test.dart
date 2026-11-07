import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/push_alert.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/keys/gift_opening_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/emulator_admin.dart';
import 'robots/emulator_robot.dart';

/// O aluno do cenário (`--dart-define=ALUNO=NN`, padrão 3).
const _student = int.fromEnvironment('ALUNO', defaultValue: 3);

// Roteiro do QA da R5, item 4 (lado app), no Emulator Suite: o push do
// presente (só `data`, H-R5-39) abre o presente e o "Curso liberado"; o push
// por curso (H-R5-44) conta o aluno no público e o toque segue o link. O FCM
// não é emulado: o cenário toca no push com o mesmo `data` que a Function
// monta (`functions/src/pessoas/push.ts`).
void main() {
  patrolTest('R5 roteiro 4: push do presente e push por curso', ($) async {
    final app = EmulatorRobot($);
    final admin = app.admin;
    final email = EmulatorAdmin.student(_student);
    final student = await admin.signIn(email, EmulatorAdmin.studentPassword);
    await admin.write('acessos/${student.uid}', {});

    await app.open();
    await app.openProfile();
    await app.signIn(email, EmulatorAdmin.studentPassword);
    final grants = app.dependencies.courseGrantsRepository;

    // Presente: o toque chega antes do acesso ("Abrindo o seu presente…"),
    // e o "Curso liberado" abre quando o darCurso grava.
    app.push.tap(
      PushOpening.fromData({
        'tipo': 'presente',
        'curso': pilaresCourseId,
        'uid': student.uid,
        'titulo': 'Presente',
        'texto': 'Um curso para você',
      }),
    );
    await $(GiftOpeningKeys.opening)
        .waitUntilVisible(timeout: const Duration(seconds: 20));
    final given = await admin.giveCourse(student.uid, sendPush: true);
    expect(given['push'], isNotNull, reason: 'o darCurso manda o push');
    await $(CourseUnlockedKeys.screen)
        .waitUntilVisible(timeout: const Duration(seconds: 30));
    // O pushReplacement deixa a abertura na árvore até a transição acabar.
    await $.pump(const Duration(seconds: 1));
    expect($(GiftOpeningKeys.opening), findsNothing);
    expect(
      grants.current.active(pilaresCourseId, DateTime.now())?.origin,
      GrantOrigin.gift,
    );
    await $(CourseUnlockedKeys.close).tap();

    // Push por curso: o aluno com o Pilares entra no público.
    final link = AppLinks.uri('/${AppLinks.dailySegment}').toString();
    final sent = await admin.call('enviarPush', {
      'destino': {'tipo': 'publico', 'curso': pilaresCourseId},
      'titulo': 'Final do dia',
      'texto': 'Um final novo para treinar',
      'tipo': 'livre',
      'link': link,
    });
    final id = sent['id']! as String;
    final counts = sent['contagens'] as Map?;
    expect(counts?['pessoas'], greaterThanOrEqualTo(1));
    expect(await admin.read('pushes/$id'), isNotNull);

    // O toque segue o link do push.
    app.push.tap(
      PushOpening.fromData({
        'tipo': 'livre',
        'pushId': id,
        'titulo': 'Final do dia',
        'texto': 'Um final novo para treinar',
        'link': link,
      }),
    );
    // O `/daily` troca a si mesmo pela partida do final de hoje (`/board`).
    await app.pumpUntil(() => app.location == Routes.freeBoard);

    await admin.revokeCourse(student.uid);
  });
}
