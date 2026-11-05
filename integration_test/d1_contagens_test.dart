import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// T85-D1 (H-ANI-18), vídeo curto: nas Estatísticas do curso, as notas e o
/// "N de M" contam com as barras.
void main() {
  Future<void> espera(PatrolIntegrationTester $, int ms) =>
      $.tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

  patrolTest('D1: Estatísticas contam com as barras', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.progress,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await capture.begin('d1-h18-estatisticas');
    await $(CourseGuideKeys.tab('stats')).tap();
    await $.pumpAndSettle();
    await espera($, 1200);
    await capture.end('d1-h18-estatisticas');
    await capture.shot('d1-h18-estatisticas');
  }, tags: ['d1-contagens']);
}
