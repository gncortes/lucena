import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/push_alert.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/emulator_admin.dart';
import 'emulator_robot.dart';
import 'journey_marks_robot.dart';
import 'pilares_lesson_robot.dart';

/// Os passos que as jornadas gravadas da R5 repetem (`docs/tasks/E1.19-qa-r5.md`,
/// "Jornadas com vídeo"): cadastro, push que chega com o app em segundo plano,
/// a primeira lição do Pilares e o progresso no servidor.
class RecordedJourneyRobot {
  RecordedJourneyRobot(this.$)
    : app = EmulatorRobot($),
      marks = JourneyMarksRobot($);

  final PatrolIntegrationTester $;
  final EmulatorRobot app;
  final JourneyMarksRobot marks;

  EmulatorAdmin get admin => app.admin;

  static const password = 'cadastro-teste-123';

  /// A 1ª lição do Pilares (capítulo 1).
  static const firstLesson = 'pilares.c1.knightFork';

  /// Abre o app, cria uma conta nova pelo Perfil e devolve o uid dela.
  Future<({String email, String uid})> signUp(String prefix) async {
    final email =
        '$prefix-${Random().nextInt(1 << 30).toRadixString(36)}@teste.lucena';
    await app.open();
    await marks.step('O aluno abre o app e vai ao Perfil');
    await app.openProfile();
    await marks.step('Cria a conta com e-mail e senha');
    await app.createAccount(email, password);
    final account = await admin.signIn(email, password);
    await marks.step('Conta criada: $email');
    return (email: email, uid: account.uid);
  }

  /// Manda o app ao segundo plano (o push chega com ele fechado na tela).
  Future<void> toBackground() async {
    await $.platform.mobile.pressHome();
    await marks.hold(1200);
  }

  /// O push chega na gaveta (postado por adb com [title] e [text], os mesmos
  /// da Function), o aluno volta ao app e toca nele: o toque leva [data].
  Future<void> pushArrives(
    String title,
    String text,
    Map<String, String> data,
  ) async {
    await marks.step('O push chega: "$title"');
    await marks.notification(title, text);
    await $.platform.mobile.openApp();
    await marks.hold(800);
    await marks.step('O aluno toca no push');
    app.push.tap(PushOpening.fromData(data));
  }

  /// Espera o "Curso liberado" e confere que abriu UMA vez só (o toque no
  /// presente e o acesso ao vivo não podem empilhar duas telas).
  Future<void> courseUnlockedOnce() async {
    await $(CourseUnlockedKeys.screen)
        .waitUntilVisible(timeout: const Duration(seconds: 30));
    await marks.hold(2500);
    expect(
      find.byKey(CourseUnlockedKeys.screen, skipOffstage: false),
      findsOneWidget,
      reason: 'o "Curso liberado" abriu mais de uma vez: ${app.routes}',
    );
    await marks.step('Curso liberado');
    await marks.hold(1500);
    await $(CourseUnlockedKeys.close).tap();
  }

  /// O título e o texto do push de presente (`textoDoPresente` em
  /// `functions/src/pessoas/acessos.ts`).
  static const giftTitle = 'Você ganhou o Pilares do Xadrez';
  static const giftText = 'Os 20 capítulos já estão abertos.';

  /// Jornadas 1 e 2: o aluno se cadastra, o painel dá o Pilares com [origin]
  /// (presente ou pago por fora), o push chega com o app em segundo plano,
  /// o "Curso liberado" abre e o aluno faz a 1ª lição. O push é o que a
  /// Function manda hoje para as duas origens.
  Future<void> giftJourney({
    required String origin,
    required GrantOrigin expected,
    String caption = 'Painel: Dar curso, Pilares, como presente',
  }) async {
    final student = await signUp('jornada-$origin');
    await marks.panel('Painel: busca o aluno pelo e-mail');
    await marks.panel(caption);
    await toBackground();
    final given = await admin.giveCourse(
      student.uid,
      origin: origin,
      sendPush: true,
    );
    await pushArrives(giftTitle, giftText, {
      'tipo': 'presente',
      'curso': pilaresCourseId,
      'uid': student.uid,
      'titulo': giftTitle,
      'texto': giftText,
      'pushId': ?(given['push'] as Map?)?['pushId'] as String?,
    });
    await courseUnlockedOnce();
    expect(
      app.dependencies.courseGrantsRepository.current
          .active(pilaresCourseId, DateTime.now())
          ?.origin,
      expected,
    );
    await firstLessonAndProgress(student.uid);
    await admin.revokeCourse(student.uid);
  }

  /// O aluno faz a 1ª lição do Pilares inteira e o progresso chega ao
  /// servidor (`users/{uid}/progress/summary`, que o painel lê).
  Future<void> firstLessonAndProgress(String uid) async {
    await marks.step('O aluno abre a 1ª lição do Pilares');
    await app.go(Routes.lessonScript(firstLesson));
    await PilaresLessonRobot($).playLesson(
      firstLesson,
      onPractice: () => marks.step('Prática: o aluno joga os lances'),
    );
    await marks.step('Lição concluída');
    await marks.hold(2000);
    await marks.panel('Painel: o progresso do aluno aparece');
    final summary = await admin.waitFor(
      'users/$uid/progress/summary',
      (doc) => doc != null && doc.isNotEmpty,
      timeout: const Duration(seconds: 60),
    );
    expect(summary, isNotNull, reason: 'o progresso não subiu ao servidor');
  }
}
