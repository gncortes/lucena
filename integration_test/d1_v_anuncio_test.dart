import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/frentes/d1_routes.dart';
import 'package:lucena/ui/core/keys/ads_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/lesson_ad/widgets/lesson_entry.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// T85-D1, vídeo curto: o anúncio antes da lição (H-31) entrando.
void main() {
  patrolTest('D1: anúncio da lição', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    await $(HomeKeys.screen).waitUntilVisible();
    final capture = TrainingCaptureRobot($);
    await capture.begin('d1-v-anuncio');
    GoRouter.of($.tester.element(find.byKey(HomeKeys.screen))).push(
      D1Paths.lessonAd,
      extra: const LessonAdArgs(lessonTitle: 'Oposição'),
    );
    await $(AdsKeys.screen).waitUntilVisible();
    await $.tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 4)),
    );
    await capture.end('d1-v-anuncio', ready: AdsKeys.screen);
    await capture.shot('d1-v-anuncio', ready: AdsKeys.screen);
  }, tags: ['d1-videos']);
}
