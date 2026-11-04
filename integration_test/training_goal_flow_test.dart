import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/services/notification_service.dart';
import 'package:lucena/domain/models/training/goal/training_diagnostic.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/goal/goal_actions.dart';
import 'package:lucena/domain/use_cases/training/goal/plan_chapters.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// Casos 13 e 16 do roteiro de Treino (H-TRE-05/06): o diagnóstico sobrevive
/// a fechar o app à força e volta de onde parou. Escritos para o aparelho; a
/// suíte local roda depois do "tudo ok" do Gabriel.
void main() {
  const course = TrainingCourse.pilares;

  Future<TrainingRepository> openGuideWithObjective(
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

  Future<void> reopenGuide(PatrolIntegrationTester $) async {
    await TrainingCaptureRobot($).openGuide();
    await $(CourseGuideKeys.tab('guide')).tap();
    await $(TrainingGoalKeys.guideTab).waitUntilVisible();
  }

  patrolTest('T85 teste do diagnóstico retomado depois de fechar à força', (
    $,
  ) async {
    final app = AppRobot($);
    final repository = await openGuideWithObjective($, app);
    final resources = await repository.resources(course);
    await repository.update(course, (s) {
      var next = applyObjective(
        s,
        TrainingObjective(kind: ObjectiveKind.improve, setOn: '2026-10-26'),
      );
      next = startDiagnosticTest(next, planChapters(resources), 5);
      for (var i = 0; i < 2; i++) {
        next = answerDiagnosticTest(next, true);
      }
      return next;
    });

    await app.restart();
    await reopenGuide($);
    await $(TrainingGoalKeys.guideDefine).tap();
    await $(TrainingGoalKeys.diagnosticScreen).waitUntilVisible();
    await $(TrainingGoalKeys.diagnosticTest).tap();
    await $(TrainingGoalKeys.testResume).waitUntilVisible();
    await $(TrainingGoalKeys.testResumeContinue).tap();
    await $(TrainingGoalKeys.testBoard).waitUntilVisible();
  });

  patrolTest('T85 questionário retomado depois de fechar à força', ($) async {
    final app = AppRobot($);
    final repository = await openGuideWithObjective($, app);
    final resources = await repository.resources(course);
    final parts = {
      for (final chapter in planChapters(resources)) chapter.partId,
    }.toList();
    await repository.update(course, (s) {
      var next = applyObjective(
        s,
        TrainingObjective(kind: ObjectiveKind.improve, setOn: '2026-10-26'),
      );
      next = startQuestionnaire(next);
      next = answerQuestionnaire(next, parts.first, TopicLevel.practicing);
      return next;
    });

    await app.restart();
    await reopenGuide($);
    await $(TrainingGoalKeys.guideDefine).tap();
    await $(TrainingGoalKeys.diagnosticScreen).waitUntilVisible();
    await $(TrainingGoalKeys.diagnosticQuestionnaire).tap();
    await $(TrainingGoalKeys.questResume).waitUntilVisible();
  });

  /// Caso 34: tocar a notificação do torneio com o app fechado abre o
  /// Registrar. O Patrol não mata o processo; o app é fechado à força pela
  /// árvore de widgets (como nos outros casos) e a notificação é tocada na
  /// barra do sistema, passando pela ligação de produção (RemindersBridge).
  patrolTest('T85 toque na notificação do torneio abre o Registrar', ($) async {
    final app = AppRobot($);
    await openGuideWithObjective($, app);
    final service = DeviceNotificationService();
    const channel = NotificationChannelSpec(id: 'training', name: 'Treino');
    await service.start(const [channel]);
    if (!await service.permitted()) {
      final permission = service.requestPermission();
      await $.platform.mobile.grantPermissionWhenInUse();
      expect(await permission, true);
    }
    const title = 'Como foi o torneio?';
    await service.show(
      ShownNotification(
        id: 691,
        channel: channel,
        title: title,
        body: 'Registre o seu desempenho.',
        payload: '${Routes.training(course.name)}/tournaments/register',
      ),
    );

    await app.restart();
    await $.platform.mobile.pressHome();
    await $.platform.mobile.openNotifications();
    final notifications = await $.platform.mobile.getNotifications();
    final index = notifications.indexWhere((n) => n.title == title);
    expect(index, greaterThanOrEqualTo(0));
    await $.platform.mobile.tapOnNotificationByIndex(index);
    await $(TrainingGoalKeys.registerScreen).waitUntilVisible();
  });
}
