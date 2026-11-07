import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/recorded_journey_robot.dart';

// Jornada gravada 4 da R5 (`docs/tasks/E1.19-qa-r5.md`): o painel revoga e
// desfaz, bloqueia e desbloqueia; o aluno sai da conta e entra de novo, o
// acesso volta e o aparelho grava um token de push novo.
void main() {
  patrolTest('Jornada 4: revogar, desfazer, bloquear, sair e entrar', (
    $,
  ) async {
    final journey = RecordedJourneyRobot($);
    final app = journey.app;
    final admin = journey.admin;
    final marks = journey.marks;
    final student = await journey.signUp('jornada-acesso');
    final access = app.dependencies.courseAccessRepository;

    Future<void> closeUnlocked() async {
      await marks.hold(1500);
      if (find.byKey(CourseUnlockedKeys.screen).evaluate().isNotEmpty) {
        await $(CourseUnlockedKeys.close).tap();
      }
    }

    await marks.panel('Painel: Dar curso, Pilares, como presente');
    await admin.giveCourse(student.uid);
    await app.pumpUntil(() => access.access == CourseAccess.owned);
    await journey.courseUnlockedOnce();
    await marks.step('O aluno tem o Pilares');

    await marks.panel('Painel: Revogar o Pilares');
    final revoked = await admin.revokeCourse(student.uid);
    await app.pumpUntil(() => access.access == CourseAccess.demo);
    await marks.step('O app volta à demonstração');

    await marks.panel('Painel: Desfazer a revogação');
    await admin.undo(student.uid, revoked['registroId']! as String);
    await app.pumpUntil(() => access.access == CourseAccess.owned);
    await closeUnlocked();
    await marks.step('O acesso volta');

    await marks.panel('Painel: Bloquear a conta');
    await admin.block(student.uid);
    await $(ProfileKeys.accountBlocked)
        .waitUntilVisible(timeout: const Duration(seconds: 30));
    expect(access.access, CourseAccess.demo);
    await marks.step('O Perfil avisa que a conta está suspensa');

    await marks.panel('Painel: Desbloquear a conta');
    await admin.unblock(student.uid);
    await app.pumpUntil(
      () =>
          access.access == CourseAccess.owned &&
          find.byKey(ProfileKeys.accountBlocked).evaluate().isEmpty,
    );
    await marks.step('Conta liberada, curso de volta');

    final before = await admin.waitFor(
      'users/${student.uid}/push/device',
      (doc) => doc?['token'] != null,
    );
    await marks.step('O aluno sai da conta');
    await app.signOut();
    await marks.step('E entra de novo');
    await app.signIn(student.email, RecordedJourneyRobot.password);
    await closeUnlocked();
    await app.pumpUntil(() => access.access == CourseAccess.owned);
    final after = await admin.waitFor(
      'users/${student.uid}/push/device',
      (doc) => doc?['token'] != null && doc?['token'] != before?['token'],
    );
    await marks.panel('Painel: o acesso volta e o token do push é novo');
    expect(after?['token'], isNot(before?['token']));
    await marks.hold(2000);

    await admin.revokeCourse(student.uid);
  });
}
