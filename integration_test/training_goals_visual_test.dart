import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() {
  for (final entry in e2eGoalsScenarios.entries) {
    patrolTest('T85 Metas artboard ${entry.value}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: entry.key,
      );
      final capture = TrainingCaptureRobot($);
      await capture.openGuide();
      await capture.tab('goals');
      final state = $.tester
          .element(find.byKey(CourseGuideKeys.screen))
          .read<CourseGuideCubit>()
          .state
          .training!;
      if (entry.value == 'scrolled') {
        final opening = state.day!.goals.singleWhere(
          (g) => g.kind == GoalKind.openings,
        );
        await $(TrainingKeys.goalTile('openings', opening.ref)).scrollTo();
      }
      expect(state.course, TrainingCourse.pilares);
      await capture.shot('goals-artboard-${entry.value}');
    }, tags: ['training-goals-${entry.value}']);
  }
}
