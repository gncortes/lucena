import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// Linhas 61 e 62 do roteiro da Lição (H-LIC-38 e H-LIC-39): a parte da
/// abertura (acerto, revisão, lance errado) e o fim da parte e do treino.
/// Escritas sem execução: a suíte local roda antes da PR.
void main() {
  Future<TrainingCaptureRobot> open(PatrolIntegrationTester $) async {
    final capture = TrainingCaptureRobot($);
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.opening,
    );
    await $(HomeKeys.goalAction).tap();
    await $(TrainingKeys.openingBoard).waitUntilVisible();
    return capture;
  }

  patrolTest(
    'H-LIC-38: trecho certo, revisão com chevron_left e lance errado',
    ($) async {
      final capture = await open($);
      await capture.openingMove('d2d4');
      expect($('Isso mesmo.'), findsOneWidget);

      await $(TrainingKeys.prevMove).tap();
      await $.pumpAndSettle();
      await $(TrainingKeys.nextMove).waitUntilVisible();

      await $(TrainingKeys.nextMove).tap();
      await $.pumpAndSettle();
      await capture.openingMove('a2a3');
      expect($('Procure outro lance.'), findsOneWidget);
    },
    tags: ['licao-telas'],
  );

  patrolTest('H-LIC-39: parte concluída oferece Próxima parte ou meta e o '
      'progresso', ($) async {
    final capture = await open($);
    await capture.openingMove('d2d4');
    await capture.openingMove('c1f4');
    expect($('Parte 1 concluída.'), findsOneWidget);
    await $(TrainingKeys.nextGoal).waitUntilVisible();

    await $(TrainingKeys.openingProgress).tap();
    await $(TrainingKeys.openingProgressScreen).waitUntilVisible();
  }, tags: ['licao-telas']);

  patrolTest('H-LIC-39: Próxima meta volta ao guia', ($) async {
    final capture = await open($);
    await capture.openingMove('d2d4');
    await capture.openingMove('c1f4');
    await $(TrainingKeys.nextGoal).tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
  }, tags: ['licao-telas']);
}
