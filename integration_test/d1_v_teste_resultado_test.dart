import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/goal/goal_actions.dart';
import 'package:lucena/domain/use_cases/training/goal/plan_chapters.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// T85-D1 (H-ANI-18), vídeo curto: no resultado do teste da meta, as
/// posições respondidas contam no tempo do placar.
void main() {
  const course = TrainingCourse.pilares;

  Future<void> espera(PatrolIntegrationTester $, int ms) =>
      $.tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

  patrolTest('D1: resultado do teste da meta conta as posições', ($) async {
    final app = AppRobot($);
    await app.open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    final repository = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<TrainingRepository>();
    final resources = await repository.resources(course);
    await repository.update(course, (s) {
      var next = applyObjective(
        s,
        const TrainingObjective(
          kind: ObjectiveKind.improve,
          setOn: '2026-10-26',
        ),
      );
      next = startDiagnosticTest(next, planChapters(resources), 5);
      for (var i = 0; i < 4; i++) {
        next = answerDiagnosticTest(next, true);
      }
      return next;
    });
    await app.restart();
    await capture.openGuide();
    await $(CourseGuideKeys.tab('guide')).tap();
    await $(TrainingGoalKeys.guideTab).waitUntilVisible();
    await $(TrainingGoalKeys.guideDefine).tap();
    await $(TrainingGoalKeys.diagnosticScreen).waitUntilVisible();
    await $(TrainingGoalKeys.diagnosticContinue).tap();
    await $(TrainingGoalKeys.testResume).waitUntilVisible();
    await $(TrainingGoalKeys.testResumeContinue).tap();
    await $(TrainingGoalKeys.testBoard).waitUntilVisible();
    await capture.begin('d1-h18-teste-resultado');
    await $(TrainingGoalKeys.testDontKnow).tap();
    await $(TrainingGoalKeys.testResult).waitUntilVisible();
    await $.pumpAndSettle();
    await espera($, 1500);
    await capture.end(
      'd1-h18-teste-resultado',
      ready: TrainingGoalKeys.testResult,
    );
    await capture.shot(
      'd1-h18-teste-resultado',
      ready: TrainingGoalKeys.testResult,
    );
    expect($(TrainingGoalKeys.testSeePlan), findsOneWidget);
  }, tags: ['d1-contagens']);
}
