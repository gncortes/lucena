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

/// Prints do treino por meta (H-TRE-01..08) para pôr ao lado dos quadros
/// PropV2GuiaSemObjetivo, PropV2MetaInicio/Data, PropV2MetaDiagnostico,
/// PropV2MetaTeste, PropV2MetaQuestionario e PropV2GuiaB3. Só captura: o
/// comportamento fica no training_goal_flow e nos testes de widget.
void main() {
  const course = TrainingCourse.pilares;

  Future<TrainingRepository> open(
    PatrolIntegrationTester $,
    AppRobot app,
  ) async {
    await app.open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    await TrainingCaptureRobot($).openGuide();
    return $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<TrainingRepository>();
  }

  Future<void> guideTab(PatrolIntegrationTester $) async {
    await $(CourseGuideKeys.tab('guide')).tap();
    await $(TrainingGoalKeys.guideTab).waitUntilVisible();
    await $.pumpAndSettle();
  }

  patrolTest('T85 prints do objetivo e do diagnóstico', ($) async {
    final app = AppRobot($);
    final capture = TrainingCaptureRobot($);
    final repository = await open($, app);
    await guideTab($);
    await capture.shot('goal-guide-empty');

    await $(TrainingGoalKeys.guideDefine).tap();
    await $(TrainingGoalKeys.goalScreen).waitUntilVisible();
    await capture.shot('goal-objective', ready: TrainingGoalKeys.goalScreen);
    await $(TrainingGoalKeys.goalTournament).$(Text).first.tap();
    await $.pumpAndSettle();
    await capture.shot('goal-tournament', ready: TrainingGoalKeys.goalScreen);

    await repository.update(
      course,
      (s) => applyObjective(
        s,
        const TrainingObjective(
          kind: ObjectiveKind.improve,
          setOn: '2026-01-01',
        ),
      ),
    );
    await app.restart();
    await capture.openGuide();
    await guideTab($);
    await $(TrainingGoalKeys.guideDefine).tap();
    await $(TrainingGoalKeys.diagnosticScreen).waitUntilVisible();
    await capture.shot(
      'goal-diagnostic',
      ready: TrainingGoalKeys.diagnosticScreen,
    );
    await $(TrainingGoalKeys.diagnosticTest).$(Text).first.tap();
    // A opção só marca; o teste abre no Continuar do rodapé.
    await $(TrainingGoalKeys.diagnosticContinue).tap();
    await $.pumpAndSettle();
    if (find.byKey(TrainingGoalKeys.testResumeContinue).evaluate().isNotEmpty) {
      await $(TrainingGoalKeys.testResumeContinue).tap();
    }
    await $(TrainingGoalKeys.testBoard).waitUntilVisible();
    await capture.shot('goal-test', ready: TrainingGoalKeys.testScreen);
  });

  patrolTest('T85 prints do questionário', ($) async {
    final app = AppRobot($);
    final capture = TrainingCaptureRobot($);
    final repository = await open($, app);
    await repository.update(
      course,
      (s) => applyObjective(
        s,
        const TrainingObjective(
          kind: ObjectiveKind.improve,
          setOn: '2026-01-01',
        ),
      ),
    );
    await app.restart();
    await capture.openGuide();
    await guideTab($);
    await $(TrainingGoalKeys.guideDefine).tap();
    await $(TrainingGoalKeys.diagnosticQuestionnaire).tap();
    await $(TrainingGoalKeys.diagnosticContinue).tap();
    await $(TrainingGoalKeys.questScreen).waitUntilVisible();
    await capture.shot('goal-quest', ready: TrainingGoalKeys.questScreen);
  });

  patrolTest('T85 prints do guia com plano', ($) async {
    final app = AppRobot($);
    final capture = TrainingCaptureRobot($);
    final repository = await open($, app);
    final resources = await repository.resources(course);
    await repository.update(course, (s) {
      var next = applyObjective(
        s,
        const TrainingObjective(
          kind: ObjectiveKind.tournament,
          setOn: '2026-01-01',
          tournamentDate: '2026-02-15',
          tournamentName: 'Aberto de Verão',
        ),
      );
      next = startDiagnosticTest(next, planChapters(resources), 5);
      for (var i = 0; i < 5; i++) {
        next = answerDiagnosticTest(next, i.isEven);
      }
      return finishDiagnostic(next, resources, '2026-01-01');
    });
    await app.restart();
    await capture.openGuide();
    await guideTab($);
    await capture.shot('goal-guide-plan');
    await capture.tab('goals');
    await capture.shot('goal-metas-plan');
  });
}
