import 'package:flutter/widgets.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// Host selects each of the six portrait viewports before launching this file.
/// Every shot checks full width and a useful-area center within one raster pixel.
void main() {
  patrolTest('T85 matriz exercício pretas, dica e resultado', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.meta,
    );
    final capture = TrainingCaptureRobot($);
    await $(HomeKeys.courseCard).waitUntilVisible();
    await $(HomeKeys.goalAction).tap();
    await capture.shot(
      'matrix-exercise-black',
      ready: TrainingKeys.exerciseBoard,
    );
    await capture.hint();
    await capture.shot(
      'matrix-exercise-hint',
      ready: TrainingKeys.exerciseBoard,
    );
    await capture.move('a8a1');
    await capture.shot(
      'matrix-exercise-result',
      ready: TrainingKeys.exerciseBoard,
    );
  }, tags: ['training-geometry']);
  patrolTest('T85 matriz abertura e revisão', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.opening,
    );
    final capture = TrainingCaptureRobot($);
    await $(HomeKeys.courseCard).waitUntilVisible();
    await $(HomeKeys.goalAction).tap();
    await capture.shot('matrix-opening', ready: TrainingKeys.openingBoard);
    await capture.openingMove('d2d4');
    await $(TrainingKeys.prevMove).tap();
    await capture.shot(
      'matrix-opening-review',
      ready: TrainingKeys.openingBoard,
    );
  }, tags: ['training-geometry']);
  patrolTest('T85 solução usa folha existente e X externo', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.meta,
    );
    final capture = TrainingCaptureRobot($);
    await $(HomeKeys.courseCard).waitUntilVisible();
    await $(HomeKeys.goalAction).tap();
    await capture.move('a8a7');
    await $(TrainingKeys.secondary).tap();
    await capture.shot('exercise-solution-sheet', ready: SheetKeys.surface);
    await $(SheetKeys.close).tap();
    expect(find.byKey(SheetKeys.surface), findsNothing);
    await capture.shot(
      'exercise-solution-closed',
      ready: TrainingKeys.exerciseBoard,
    );
  }, tags: ['training-solution']);
}
