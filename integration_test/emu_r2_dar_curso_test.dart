import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/emulator_admin.dart';
import 'robots/emulator_robot.dart';

/// O aluno do cenário (`--dart-define=ALUNO=NN`, padrão 1): cada emulador
/// usa um aluno diferente para os cenários não se cruzarem.
const _student = int.fromEnvironment('ALUNO', defaultValue: 1);

// Roteiro do QA da R5, item 2 (lado app), no Emulator Suite: o admin dá o
// Pilares e o app libera com o "Curso liberado" (H-R5-61/62); o admin
// revoga e desfaz, e o acesso some e volta (H-R5-42).
void main() {
  patrolTest('R5 roteiro 2: dar curso, revogar e desfazer', ($) async {
    final app = EmulatorRobot($);
    final admin = app.admin;
    final email = EmulatorAdmin.student(_student);
    final student = await admin.signIn(email, EmulatorAdmin.studentPassword);
    // Começa sem o curso: o que outra rodada deu sai antes.
    await admin.write('acessos/${student.uid}', {});

    await app.open();
    await app.openProfile();
    await app.signIn(email, EmulatorAdmin.studentPassword);
    final grants = app.dependencies.courseGrantsRepository;
    expect(grants.current.active(pilaresCourseId, DateTime.now()), isNull);

    // Dar o curso: o acesso chega pelo Firestore e o "Curso liberado" abre.
    final given = await admin.giveCourse(student.uid);
    await $(CourseUnlockedKeys.screen)
        .waitUntilVisible(timeout: const Duration(seconds: 30));
    expect(
      grants.current.active(pilaresCourseId, DateTime.now())?.origin,
      GrantOrigin.gift,
    );
    // Fechar grava o "visto": a tela não volta para o mesmo acesso.
    await $(CourseUnlockedKeys.close).tap();
    await $.pump(const Duration(seconds: 1));
    if (find.byKey(CourseUnlockedKeys.screen).evaluate().isNotEmpty) {
      final top = app.routes;
      await $(CourseUnlockedKeys.close).tap();
      await $.pump(const Duration(seconds: 1));
      final twice = find.byKey(CourseUnlockedKeys.screen).evaluate().isEmpty;
      fail(
        'o X não fechou o Curso liberado ($top); o segundo X '
        '${twice ? 'fechou: eram duas telas' : 'também não fechou'}',
      );
    }
    await admin.waitFor(
      'acessos/${student.uid}',
      (doc) => (doc?['vistos'] as Map?)?[pilaresCourseId] != null,
    );
    expect(given['registroId'], isA<String>());

    // Revogar: o acesso fecha no app.
    final revoked = await admin.revokeCourse(student.uid);
    await app.pumpUntil(
      () => grants.current.active(pilaresCourseId, DateTime.now()) == null,
    );
    expect(
      $(CourseUnlockedKeys.screen),
      findsNothing,
      reason: 'revogar não abre o Curso liberado',
    );
    final seen = await admin.read('acessos/${student.uid}');

    // Desfazer a revogação: o acesso volta, sem o "Curso liberado" de novo
    // (o curso não foi dado outra vez).
    await admin.undo(student.uid, revoked['registroId']! as String);
    await app.pumpUntil(
      () => grants.current.active(pilaresCourseId, DateTime.now()) != null,
    );
    expect(
      $(CourseUnlockedKeys.screen),
      findsNothing,
      reason:
          'desfazer não abre o Curso liberado; antes: $seen, '
          'depois: ${await admin.read('acessos/${student.uid}')}, '
          'no app: ${grants.current.seen}',
    );

    // Limpa para a próxima rodada.
    await admin.revokeCourse(student.uid);
    await app.signOut();
  });
}
