import 'package:flutter/widgets.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// V8 da frente T85-D1: vídeo do retorno do lance (RetornoDoLance) no
/// exercício do treino, com erro e depois acerto. O hero até o tabuleiro da
/// lição sai de training_transitions_test ("T85 Hero Home aula").
void main() {
  patrolTest('V8: retorno do lance com erro e com acerto', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.meta,
    );
    final capture = TrainingCaptureRobot($);
    await $(HomeKeys.goalAction).tap();
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await $.pumpAndSettle();

    await capture.begin('v8-retorno-erro');
    await capture.move('a8a2');
    await capture.end('v8-retorno-erro');
    await capture.shot('v8-retorno-erro', ready: TrainingKeys.exerciseBoard);

    await $(TrainingKeys.exercisePracticeRetry).tap();
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await $.pumpAndSettle();

    await capture.begin('v8-retorno-acerto');
    await capture.move('a8a1');
    await capture.end('v8-retorno-acerto');
    await capture.shot('v8-retorno-acerto', ready: TrainingKeys.exerciseBoard);
  }, tags: ['d1-v8']);
}
