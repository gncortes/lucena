import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/push_alerts.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:patrol/patrol.dart';

import 'robots/recorded_journey_robot.dart';

// Jornada 7 da R5 (`docs/tasks/E1.19-qa-r5.md`, "Push sem Blaze"): as
// Functions do emulador mandam pelo FCM real do lucena-dev-gnc (login do
// Gabriel por ADC) e o aparelho (Lucena_Push, com Google Play) recebe de
// verdade: o presente, o pago por fora e o push por curso. Cada push sai numa
// linha `PUSH_REAL` no logcat: o que a Function gravou e se a notificação
// chegou.
void main() {
  patrolTest('Jornada 7: push real pelo FCM', ($) async {
    final journey = RecordedJourneyRobot($, realPush: true);
    final app = journey.app;
    final admin = journey.admin;
    final marks = journey.marks;
    listenPushInBackground();
    final student = await journey.signUp('jornada-fcm');

    await marks.step('O aluno permite as notificações');
    final asked = app.dependencies.pushRepository.requestPermission();
    if (await $.platform.mobile.isPermissionDialogVisible(
      timeout: const Duration(seconds: 10),
    )) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
    await asked;
    await app.dependencies.accountRepository.linkPushDevice();
    final device = await admin.waitFor(
      'users/${student.uid}/push/device',
      (doc) =>
          doc?['permissao'] == 'permitida' &&
          (doc?['token'] as String?)?.isNotEmpty == true,
      timeout: const Duration(seconds: 60),
    );
    expect(device, isNotNull, reason: 'o token do FCM não chegou ao servidor');
    await marks.step('Aparelho registrado no FCM real');

    final results = <String, String>{};

    // O push chega com o app em segundo plano; o aluno toca na notificação.
    Future<bool> arrives(String title) async {
      final start = DateTime.now();
      while (DateTime.now().difference(start) < const Duration(seconds: 45)) {
        // O Patrol lê a gaveta pela tela: só com ela aberta.
        await $.platform.mobile.openNotifications();
        await marks.hold(1500);
        final shown = await $.platform.mobile.getNotifications();
        debugPrint(
          'PUSH_REAL gaveta: ${shown.map((n) => '${n.appName}|${n.title}').join(' ; ')}',
        );
        if (shown.any((n) => n.title.contains(title))) {
          await marks.step('O push chega de verdade: "$title"');
          await marks.hold(1500);
          await $.platform.mobile.tapOnNotificationBySelector(
            Selector(textContains: title),
            timeout: const Duration(seconds: 10),
          );
          await marks.hold(1500);
          return true;
        }
        await $.platform.mobile.closeNotifications();
        await marks.hold(1000);
      }
      await $.platform.mobile.openApp();
      await marks.hold(800);
      return false;
    }

    void report(String push, String function, bool arrived) {
      final line =
          '$push: Function $function, '
          '${arrived ? 'notificação chegou e o toque abriu' : 'notificação não chegou'}';
      results[push] = line;
      debugPrint('PUSH_REAL $line');
    }

    Future<String> giftPush(String origin) async {
      // Como nas jornadas 1 e 2: o push chega com o app em segundo plano.
      await journey.toBackground();
      final given = await admin.giveCourse(
        student.uid,
        origin: origin,
        sendPush: true,
      );
      final record = await admin.waitFor(
        'acessos/${student.uid}/registro/${given['registroId']}',
        (doc) => doc?['push'] != null,
        timeout: const Duration(seconds: 30),
      );
      return '${record?['push']}';
    }

    // 1. Presente.
    await marks.panel('Painel: Dar curso, Pilares, como presente, com push');
    final gift = await giftPush('presente');
    final giftArrived =
        gift == 'enviado' &&
        await arrives(RecordedJourneyRobot.pushTexts['presente']!.title);
    report('presente', gift, giftArrived);
    if (giftArrived) await journey.courseUnlockedOnce();
    await admin.revokeCourse(student.uid);
    await marks.hold(1500);

    // 2. Pago por fora.
    await marks.panel('Painel: Dar curso, Pilares, pago por fora, com push');
    final paid = await giftPush('pagoPorFora');
    final paidArrived =
        paid == 'enviado' &&
        await arrives(RecordedJourneyRobot.pushTexts['pagoPorFora']!.title);
    report('pago por fora', paid, paidArrived);
    if (paidArrived) await journey.courseUnlockedOnce();
    expect(
      app.dependencies.courseGrantsRepository.current
          .active(pilaresCourseId, DateTime.now())
          ?.origin,
      GrantOrigin.paidOutside,
    );

    // 3. Push por curso (quem tem o Pilares).
    const title = 'Final do dia';
    const text = 'Um final novo para treinar';
    await marks.panel('Painel: Push para quem tem o Pilares');
    await journey.toBackground();
    final sent = await admin.call('enviarPush', {
      'destino': {'tipo': 'publico', 'curso': pilaresCourseId},
      'titulo': title,
      'texto': text,
      'tipo': 'livre',
      'link': AppLinks.uri('/${AppLinks.dailySegment}').toString(),
    });
    final counts = (sent['contagens'] as Map?) ?? const {};
    final course = 'enviados ${counts['enviados']}, falhas ${counts['falhas']}';
    final courseArrived =
        (counts['enviados'] as num? ?? 0) > 0 && await arrives(title);
    report('push por curso', course, courseArrived);
    await marks.step('Fim: ${results.length} pushes');
    await marks.hold(2000);
    await admin.revokeCourse(student.uid);

    expect(
      [giftArrived, paidArrived, courseArrived],
      everyElement(isTrue),
      reason: results.values.join(' | '),
    );
  });
}
