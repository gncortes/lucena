import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/view_models/training_plan_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() {
  for (final course in TrainingCourse.values) {
    patrolTest('T85 plano editar cancelar horário ${course.name}', ($) async {
      final school = course == TrainingCourse.escola;
      final app = AppRobot($);
      await app.open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: school
            ? E2ETrainingScenario.schoolDayOne
            : E2ETrainingScenario.large,
      );
      final capture = TrainingCaptureRobot($);
      await capture.openGuide(escola: school);
      expect(
        $.tester
            .element(find.byKey(CourseGuideKeys.screen))
            .read<CourseGuideCubit>()
            .config
            .course,
        course,
      );
      final repository = $.tester
          .element(find.byKey(CourseGuideKeys.screen))
          .read<TrainingRepository>();
      final before = await repository.load(course);
      await $(CourseGuideKeys.planAction).tap();
      await $(TrainingKeys.planScreen).waitUntilVisible();
      expect(
        $.tester
            .element(find.byKey(TrainingKeys.planScreen))
            .read<TrainingPlanCubit>()
            .config
            .course,
        course,
      );
      expect(
        find.byKey(TrainingKeys.planChip(240)),
        school ? findsNothing : findsOneWidget,
      );
      await capture.shot(
        'plan-edit-${course.name}',
        ready: TrainingKeys.planScreen,
      );
      if (school) {
        await $(TrainingKeys.planChip(120)).scrollTo().tap();
        await capture.shot(
          'plan-edit-max-escola',
          ready: TrainingKeys.planScreen,
        );
      }
      await $(TrainingKeys.planSave).scrollTo();
      await capture.shot(
        'plan-edit-bottom-${course.name}',
        ready: TrainingKeys.planScreen,
      );
      await $(TrainingKeys.planChip(60))
          .scrollTo(scrollDirection: AxisDirection.up)
          .tap();
      await $(BackButton).tap();
      await $(CourseGuideKeys.screen).waitUntilVisible();
      expect(
        (await repository.load(course)).plan.toJson(),
        before.plan.toJson(),
      );
      await $(CourseGuideKeys.planAction).tap();
      await $(TrainingKeys.reminderTime).scrollTo().tap();
      await $(TimePickerDialog).waitUntilVisible();
      await capture.shot('plan-time-${course.name}', ready: SheetKeys.close);
      await $(find.byIcon(Icons.keyboard_outlined)).tap();
      final fields = find.byType(TextField);
      await $.tester.enterText(fields.at(0), '21');
      await $.tester.enterText(fields.at(1), '30');
      final dialog = $.tester.element(find.byType(TimePickerDialog));
      await $(find.text(MaterialLocalizations.of(dialog).okButtonLabel)).tap();
      await $(TrainingKeys.planSave).scrollTo().tap();
      await $(CourseGuideKeys.screen).waitUntilVisible();
      await app.sendToBackgroundAndReturn();
      await app.restart();
      await capture.openGuide(escola: school);
      final saved = await $.tester
          .element(find.byKey(CourseGuideKeys.screen))
          .read<TrainingRepository>()
          .load(course);
      expect(saved.plan.reminderHour, 21);
      expect(saved.plan.reminderMinute, 30);
      expect(saved.plan.minutes, before.plan.minutes);
      await $(CourseGuideKeys.planAction).tap();
      await $(TrainingKeys.planSave).scrollTo();
      await capture.shot(
        'plan-time-saved-${course.name}',
        ready: TrainingKeys.planScreen,
      );
    }, tags: const ['training-plan-visual']);
  }
  patrolTest('T85 permissão cancelada negativa e configurações', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.welcome,
    );
    e2ePush.allowed = false;
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await $(CourseGuideKeys.continueButton).scrollTo().tap();
    await $(TrainingKeys.reminderSwitch).scrollTo().tap();
    await $(TrainingKeys.reminderSwitch).tap();
    await $(TrainingKeys.permissionDialog).waitUntilVisible();
    expect(e2ePush.permissionRequests, 0);
    await capture.shot(
      'plan-permission-current',
      ready: TrainingKeys.permissionDialog,
    );
    await $(TrainingKeys.permissionLater).tap();
    expect(e2ePush.permissionRequests, 0);
    await $(TrainingKeys.reminderSwitch).tap();
    await $(TrainingKeys.permissionAllow).tap();
    await $(TrainingKeys.openNotificationSettings).scrollTo();
    expect(e2ePush.permissionRequests, 1);
    await capture.shot(
      'plan-denied-current',
      ready: TrainingKeys.openNotificationSettings,
    );
    await $(TrainingKeys.openNotificationSettings).tap();
    expect(e2ePush.settingsOpened, 1);
  }, tags: ['training-permission']);
}
