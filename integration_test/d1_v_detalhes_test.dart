import 'package:flutter/widgets.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'game_review_test.dart' show reviewGame;
import 'robots/app_robot.dart';
import 'robots/game_details_robot.dart';
import 'robots/training_capture_robot.dart';

/// T85-D1, vídeo curto: nos detalhes de uma partida antiga, Analisar roda a
/// revisão rápida e a precisão de cada lado conta (H-ANI-18).
void main() {
  patrolTest('D1: detalhes da partida, a precisão conta', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    final id = await seedAttempt(reviewGame);
    await GameDetailsRobot($).open(id);
    final capture = TrainingCaptureRobot($);
    await capture.begin('d1-v-detalhes');
    await $(GameDetailsKeys.oldAnalysisButton).tap();
    await $.tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 7)),
    );
    await capture.end('d1-v-detalhes', ready: GameDetailsKeys.screen);
    await capture.shot('d1-v-detalhes', ready: GameDetailsKeys.screen);
  }, tags: ['d1-videos']);
}
