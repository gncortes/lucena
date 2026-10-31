import 'package:flutter/widgets.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// Initial T85 visual infrastructure, not the T85.13 acceptance suite.
/// Host chooses 412×917 or 360×740 before running; PT-BR, light, font 1.0.
/// Requires --dart-define=E2E=true and CONTENT_URL for the real Pilares index.
void main() {
  patrolTest('T85 boas-vindas e plano nativos', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.welcome,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await capture.shot('welcome');
    await $(CourseGuideKeys.continueButton).scrollTo().tap();
    await capture.shot('plan', ready: TrainingKeys.planScreen);
  });

  for (final scenario in [
    E2ETrainingScenario.large,
    E2ETrainingScenario.done,
    E2ETrainingScenario.dayOff,
    E2ETrainingScenario.doubled,
  ]) {
    patrolTest('T85 metas nativas ${scenario.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: scenario,
      );
      final capture = TrainingCaptureRobot($);
      await capture.shot('home-${scenario.name}', ready: HomeKeys.courseCard);
      await capture.openGuide();
      await capture.tab('goals');
      await capture.shot('goals-${scenario.name}');
      if (scenario == E2ETrainingScenario.large) {
        await $(TrainingKeys.goalTile('exercise', 'pilares.c1.knightFork'))
            .scrollTo();
        await capture.shot('goals-large-scrolled');
        await capture.tab('catalog');
        await capture.shot('catalog');
      }
    }, tags: ['training-visual-${scenario.name}']);
  }

  for (final scenario in [
    E2ETrainingScenario.meta,
    E2ETrainingScenario.opening,
  ]) {
    patrolTest('T85 cartão nativo ${scenario.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: scenario,
      );
      await TrainingCaptureRobot($)
          .shot('home-${scenario.name}', ready: HomeKeys.courseCard);
    });
  }

  for (final result in ['correct', 'wrong', 'hint']) {
    patrolTest('T85 exercício nativo $result', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: E2ETrainingScenario.large,
      );
      final capture = TrainingCaptureRobot($);
      await capture.openGuide();
      await capture.exercise('pilares.c1.knightFork');
      await capture.shot(
        'exercise-$result-before',
        ready: TrainingKeys.exerciseBoard,
      );
      if (result == 'hint') await capture.hint();
      await capture.move(result == 'wrong' ? 'a1a2' : 'a1a8');
      await capture.shot('exercise-$result', ready: TrainingKeys.nextGoal);
    });
  }

  for (final scenario in [
    E2ETrainingScenario.medium,
    E2ETrainingScenario.hard,
  ]) {
    patrolTest('T85 dificuldade nativa ${scenario.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: scenario,
      );
      final capture = TrainingCaptureRobot($);
      await capture.openGuide();
      await capture.tab('goals');
      await $(TrainingKeys.goalTile('exercise', 'pilares.c1.knightFork'))
          .scrollTo();
      await capture.shot('goals-${scenario.name}');
      await $(TrainingKeys.goalTile('exercise', 'pilares.c1.knightFork')).tap();
      await capture.shot(
        'exercise-${scenario.name}',
        ready: TrainingKeys.exerciseBoard,
      );
    });
  }

  patrolTest('T85 Escola boas-vindas e plano nativos', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.schoolWelcome,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide(escola: true);
    await capture.shot('school-welcome');
    await $(CourseGuideKeys.continueButton).scrollTo().tap();
    await capture.shot('school-plan', ready: TrainingKeys.planScreen);
  }, tags: const ['training-school-visual']);

  for (final scenario in [
    E2ETrainingScenario.schoolDayOne,
    E2ETrainingScenario.schoolPieces,
    E2ETrainingScenario.schoolMates,
    E2ETrainingScenario.schoolDone,
    E2ETrainingScenario.schoolDayOff,
    E2ETrainingScenario.schoolTwoHours,
  ]) {
    patrolTest('T85 Escola nativa ${scenario.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: scenario,
      );
      final capture = TrainingCaptureRobot($);
      await capture.shot('home-${scenario.name}', ready: HomeKeys.courseCard);
      await capture.openGuide(escola: true);
      await capture.shot('lesson-${scenario.name}');
      await capture.tab('goals');
      await capture.shot('goals-${scenario.name}');
      if (scenario == E2ETrainingScenario.schoolPieces) {
        await $(TrainingKeys.goalTile('stars', 'pieces.queen')).scrollTo();
        await capture.shot('school-stars-levels');
        await capture.tab('progress');
        await capture.shot('school-progress');
        await capture.tab('catalog');
        await capture.shot('school-catalog');
      }
    }, tags: const ['training-school-visual']);
  }
}
