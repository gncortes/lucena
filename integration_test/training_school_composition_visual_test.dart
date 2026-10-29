import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() {
  patrolTest('T85 Escola composição de metas feitas e pendentes', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.schoolDayOne,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide(escola: true);
    final guide = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<CourseGuideCubit>();
    final before = guide.state.training!;
    final data = guide.state.resources!;
    final lessonId = before.day!.goals
        .firstWhere((goal) => goal.kind == GoalKind.lesson)
        .ref;
    final lesson = data.lessons.firstWhere((lesson) => lesson.id == lessonId);
    // A presentation fixture composed with the actual completion rule. The
    // full lesson -> observed completion path is exercised by training_test.
    await guide.repository.update(
      TrainingCourse.escola,
      (state) =>
          CompleteTrainingLesson(e2eNow, guide.config)(state, data, lesson),
    );
    await guide.load();
    await capture.tab('goals');
    final goals = guide.state.training!.day!.goals;
    expect(goals.any((goal) => goal.done), true);
    expect(goals.any((goal) => !goal.done), true);
    await capture.shot('school-metas-mixed');
    final stars = goals.singleWhere((goal) => goal.kind == GoalKind.stars);
    await $.tester.scrollUntilVisible(
      find.byKey(TrainingKeys.goalTile('stars', stars.ref)),
      200,
      maxScrolls: 20,
    );
    await capture.shot('school-metas-mixed-bottom');
  }, tags: const ['training-school-composition']);

  for (final scenario in [
    E2ETrainingScenario.schoolPieces,
    E2ETrainingScenario.schoolMates,
  ]) {
    patrolTest('T85 Escola fundo da lista ${scenario.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: scenario,
      );
      final capture = TrainingCaptureRobot($);
      await capture.openGuide(escola: true);
      if (scenario == E2ETrainingScenario.schoolPieces) {
        await capture.tab('progress');
        await $.tester.scrollUntilVisible(
          find.byKey(TrainingKeys.pieceStars('pawn')),
          200,
          maxScrolls: 20,
        );
        await capture.shot('school-progress-bottom');
      } else {
        await capture.tab('goals');
        final guide = $.tester
            .element(find.byKey(CourseGuideKeys.screen))
            .read<CourseGuideCubit>();
        final goals = guide.state.training!.day!.goals;
        expect(goals.where((goal) => goal.kind == GoalKind.bot), hasLength(2));
        final speedrun = goals.singleWhere(
          (goal) => goal.kind == GoalKind.speedrun,
        );
        await $.tester.scrollUntilVisible(
          find.byKey(TrainingKeys.goalTile('speedrun', speedrun.ref)),
          200,
          maxScrolls: 20,
        );
        await capture.shot('school-mates-followups-bottom');
      }
    }, tags: const ['training-school-composition']);
  }
}
