import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/training_capture_robot.dart';

/// T85-D1 (H-ANI-16): vídeo das boas-vindas do curso de finais
/// (PropV1TreinoAulaBoasVindas). O cartão, o texto e o botão entram em
/// cascata, o botão por último.
void main() {
  patrolTest('D1: boas-vindas dos finais em cascata', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.welcome,
    );
    await HomeRobot($).openSettings();
    final capture = TrainingCaptureRobot($);
    await capture.begin('d1-boas-vindas');
    await $(SettingsKeys.pilaresTrainingTile).scrollTo().tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await $.tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await capture.end('d1-boas-vindas');
    await capture.shot('d1-boas-vindas');
    expect($(CourseGuideKeys.continueButton), findsOneWidget);
  }, tags: ['d1-boas-vindas']);
}
