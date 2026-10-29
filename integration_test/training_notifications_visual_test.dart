import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/services/notification_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/reminder_text.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/reminders/widgets/l10n_reminder_texts.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

// A real Android notification plugin smoke test. Business scheduling, consent
// and deduplication are covered separately with injected time/services. These
// fixtures display the production localized reminder body immediately.
void main() {
  for (final course in TrainingCourse.values) {
    for (final lessonDone in [false, true]) {
      patrolTest(
        'T85 notificação Android ${course.name} aula feita=$lessonDone',
        ($) async {
          final school = course == TrainingCourse.escola;
          await AppRobot($).open(
            systemLocale: const Locale('pt', 'BR'),
            lightDevice: true,
            trainingScenario: school
                ? E2ETrainingScenario.schoolPieces
                : E2ETrainingScenario.large,
          );
          final capture = TrainingCaptureRobot($);
          await capture.openGuide(escola: school);
          final context = $.tester.element(find.byKey(CourseGuideKeys.screen));
          final repository = context.read<TrainingRepository>();
          final texts = L10nReminderTexts(context.l10n);
          var state = await repository.load(course);
          if (lessonDone) {
            state = await repository.update(
              course,
              (current) => current.copyWith(
                day: current.day!.copyWith(
                  goals: [
                    for (final goal in current.day!.goals)
                      if (goal.kind == GoalKind.lesson)
                        goal.complete()
                      else
                        goal,
                  ],
                ),
              ),
            );
          }
          final request = reminderText(state.day!);
          expect(request, isNotNull);
          expect(
            request!.key,
            lessonDone ? 'trainingNotifGoals' : 'trainingNotifLesson',
          );
          final resources = await repository.resources(course);
          final title = resources.lessons
              .where((lesson) => lesson.id == request.arguments['aula'])
              .firstOrNull
              ?.title;
          final body = texts.trainingBody(request, title);
          final service = DeviceNotificationService();
          await service.start([texts.trainingChannel]);
          if (!await service.permitted()) {
            final permission = service.requestPermission();
            expect(
              await $.platform.mobile.isPermissionDialogVisible(
                timeout: const Duration(seconds: 10),
              ),
              true,
            );
            await capture.shot('notification-system-permission-${course.name}');
            await $.platform.mobile.grantPermissionWhenInUse();
            expect(await permission, true);
          }
          expect(
            await service.permitted(),
            true,
            reason:
                'The actual Android notification permission must be granted',
          );
          if (!context.mounted) throw StateError('Guide was unmounted');
          final router = GoRouter.of(context);
          final taps = service.taps.listen((tap) => router.go(tap.payload));
          addTearDown(taps.cancel);
          await service.show(
            ShownNotification(
              id: 690,
              channel: texts.trainingChannel,
              title: texts.trainingTitle,
              body: body,
              payload: Routes.home,
            ),
          );
          await $.platform.mobile.openNotifications();
          final notifications = await $.platform.mobile.getNotifications();
          final index = notifications.indexWhere(
            (notification) =>
                notification.title == texts.trainingTitle &&
                notification.content.contains(body),
          );
          expect(
            index,
            greaterThanOrEqualTo(0),
            reason: 'The actual Android notification must contain the production reminder body',
          );
          await capture.shot(
            'notification-${course.name}-${lessonDone ? 'lesson-done' : 'lesson-pending'}',
          );
          await $.platform.mobile.tapOnNotificationByIndex(index);
          await $(HomeKeys.courseCard).waitUntilVisible();
          expect(router.routeInformationProvider.value.uri.path, Routes.home);
        },
        tags: const ['training-notifications-visual'],
      );
    }
  }
}
