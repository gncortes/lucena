import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/emulator_admin.dart';
import 'robots/emulator_robot.dart';

/// O aluno do cenário (`--dart-define=ALUNO=NN`, padrão 2).
const _student = int.fromEnvironment('ALUNO', defaultValue: 2);

// Roteiro do QA da R5, item 3 (lado app), no Emulator Suite: o admin
// suspende a conta e o app perde o acesso e mostra o aviso no Perfil;
// desfeita a suspensão, tudo volta (H-R5-43). O painel lê o mesmo
// `bloqueios/{uid}` que o cenário confere.
void main() {
  patrolTest('R5 roteiro 3: bloquear a conta e desfazer', ($) async {
    final app = EmulatorRobot($);
    final admin = app.admin;
    final email = EmulatorAdmin.student(_student);
    final student = await admin.signIn(email, EmulatorAdmin.studentPassword);
    await admin.write('acessos/${student.uid}', {});
    // Com o curso dado, o bloqueio tem o que tirar.
    await admin.giveCourse(student.uid);

    await app.open();
    await app.openProfile();
    await app.signIn(email, EmulatorAdmin.studentPassword);
    try {
      await $(CourseUnlockedKeys.screen)
          .waitUntilVisible(timeout: const Duration(seconds: 30));
    } on Object {
      final doc = await admin.read('acessos/${student.uid}');
      fail(
        'Curso liberado não abriu depois de entrar; tela ${app.location}, '
        'vistos no servidor ${doc?['vistos']}, no app '
        '${app.dependencies.courseGrantsRepository.current.seen}',
      );
    }
    await $(CourseUnlockedKeys.close).tap();
    final grants = app.dependencies.courseGrantsRepository;
    final access = app.dependencies.courseAccessRepository;
    expect(access.access, CourseAccess.owned);
    expect($(ProfileKeys.accountBlocked), findsNothing);

    // Suspender: o app perde o curso e o Perfil mostra o aviso.
    await admin.block(student.uid);
    await app.pumpUntil(() => grants.current.blockedAt(DateTime.now()));
    expect(grants.current.active(pilaresCourseId, DateTime.now()), isNull);
    expect(access.access, CourseAccess.demo);
    await $(ProfileKeys.accountBlocked)
        .waitUntilVisible(timeout: const Duration(seconds: 30));
    final block = await admin.read('bloqueios/${student.uid}');
    expect(block, isNotNull, reason: 'o painel lê bloqueios/{uid}');

    // Desfazer a suspensão: o curso e o Perfil voltam ao normal.
    await admin.unblock(student.uid);
    await app.pumpUntil(() => !grants.current.blockedAt(DateTime.now()));
    expect(access.access, CourseAccess.owned);
    await app.pumpUntil(
      () => find.byKey(ProfileKeys.accountBlocked).evaluate().isEmpty,
    );

    await admin.revokeCourse(student.uid);
    await app.signOut();
  });
}
