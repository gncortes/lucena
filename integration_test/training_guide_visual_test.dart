import 'package:flutter/widgets.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() {
  patrolTest('T85 catálogo abre o teste de nível existente', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await capture.tab('catalog');
    await $(CourseGuideKeys.levelTest).tap();
    await $(PlacementKeys.start).waitUntilVisible();
    await capture.shot('catalog-level-test', ready: PlacementKeys.screen);
  });

  patrolTest('T85 guia primeira aula e capítulo', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.welcome,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await $(CourseGuideKeys.continueButton).scrollTo().tap();
    await $(TrainingKeys.planSave).scrollTo().tap();
    await capture.shot('lesson-first');
    await capture.tab('catalog');
    await capture.shot('catalog-first');
    await $(CourseGuideKeys.chapter('pilares.c1')).scrollTo().tap();
    await capture.shot('chapter-first', ready: CourseGuideKeys.chapterScreen);
  });

  patrolTest('T85 guia com aulas já concluídas', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await capture.shot('lesson-returning');
    await capture.tab('catalog');
    await $(CourseGuideKeys.chapter('pilares.c1')).scrollTo().tap();
    await capture.shot(
      'chapter-returning',
      ready: CourseGuideKeys.chapterScreen,
    );
  });
}
