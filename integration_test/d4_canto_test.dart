import 'package:flutter/widgets.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// O selo do retorno do lance no canto de cima à esquerda, logo embaixo do
/// Viktor (Gabriel, 04/11): exercício do treino com as brancas, erro em a7 e
/// acerto em a8 (Ta1-a8#). Coletor: `tools/capture/t85_capture_server.py`.
void main() {
  patrolTest('D4 vídeo: selo no canto de cima à esquerda (Treino)', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.metaWhite,
    );
    final capture = TrainingCaptureRobot($);
    await $(HomeKeys.goalAction).tap();
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await $.pumpAndSettle();

    await capture.begin('D4CantoErro');
    await capture.move('a1a7');
    await capture.end('D4CantoErro');
    await capture.shot('D4CantoErro', ready: TrainingKeys.exerciseBoard);

    await $(TrainingKeys.exercisePracticeRetry).tap();
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await $.pumpAndSettle();

    await capture.begin('D4CantoAcerto');
    await capture.move('a1a8');
    await capture.end('D4CantoAcerto');
    await capture.shot('D4CantoAcerto', ready: TrainingKeys.exerciseBoard);
  });
}
