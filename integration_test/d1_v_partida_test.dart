import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'game_review_test.dart' show reviewGame;
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// T85-D1, vídeo curto: a conclusão de uma partida que acabou agora. O balão
/// do Viktor entra (H-ANI-09) e a precisão conta quando a análise rápida
/// chega (H-ANI-18).
void main() {
  patrolTest('D1: conclusão da partida (balão e precisão)', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    final id = await seedAttempt(reviewGame);
    await $(HomeKeys.screen).waitUntilVisible();
    final capture = TrainingCaptureRobot($);
    await capture.begin('d1-v-partida');
    GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
        .push(Routes.conclusion(id, fresh: true));
    await $(ConclusionKeys.screen).waitUntilVisible();
    await $.tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 6)),
    );
    await capture.end('d1-v-partida', ready: ConclusionKeys.screen);
    await capture.shot('d1-v-partida', ready: ConclusionKeys.screen);
  }, tags: ['d1-videos']);
}
