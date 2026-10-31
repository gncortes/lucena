import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/training_date.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() {
  patrolTest('T85 banco real, fala aprovada e nova tentativa sem alterar nota', (
    $,
  ) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    final context = $.tester.element(find.byKey(CourseGuideKeys.screen));
    final teacher = (await context.read<CharacterRepository>().characters())
        .firstWhere((character) => character.id == Character.masterId);
    final repository = TrainingRepositoryLocal(
      PreferencesService(),
      createLessonContentAssets(
        releaseBuild: false,
        firebase: false,
        localUrl: const String.fromEnvironment('CONTENT_URL'),
      ),
      installSeed: 'native-real-feedback',
    );
    addTearDown(repository.dispose);
    final resources = await repository.resources(TrainingCourse.pilares);
    expect(
      resources.banks.values.expand((bank) => bank).where((e) => e.mock),
      isEmpty,
    );
    const lesson = 'pilares.c1.knightFork';
    final texts = resources.errorFeedback[lesson]!;
    final key = texts.keys.firstWhere((key) => key.split('.')[1] == '1');
    final parts = key.split('.');
    final exercise = resources.banks[lesson]!.firstWhere(
      (e) => e.id == parts[0],
    );
    final goal = TrainingGoal(
      kind: GoalKind.exercise,
      ref: lesson,
      itemId: exercise.id,
      stars: exercise.stars,
    );
    await repository.transact(
      TrainingCourse.pilares,
      (old) => TrainingState(
        course: TrainingCourse.pilares,
        installSeed: old.installSeed,
        onboardingDone: true,
        day: DayGoals(
          date: trainingDate(e2eNow()),
          studyDay: true,
          goals: [goal],
        ),
        cycles: {
          lesson: ThemeCycle(
            lessonId: lesson,
            startedOn: trainingDate(e2eNow()),
          ),
        },
      ),
    );
    if (!context.mounted) throw StateError('Guide was unmounted');
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TrainingExerciseScreen(
            repository: repository,
            config: TrainingCourseConfig.pilares,
            now: e2eNow,
            goalKey: goal.key,
            title: resources.lessons.firstWhere((l) => l.id == lesson).title,
            teacher: teacher,
            onNextGoal: () {},
            onRedoLesson: (_) {},
          ),
        ),
      ),
    );
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await capture.shot(
      'real-exercise-before',
      ready: TrainingKeys.exerciseBoard,
    );
    await capture.begin('real-feedback-retry');
    await capture.move(parts[2]);
    final cubit = $.tester
        .element(find.byKey(TrainingKeys.exerciseBoard))
        .read<TrainingExerciseCubit>();
    expect(cubit.state.correct, false);
    final before = await repository.load(TrainingCourse.pilares);
    expect(before.day!.allDone, true);
    expect(before.day!.goals.single.exerciseError!.feedbackShown, true);
    await capture.shot(
      'real-exercise-feedback',
      ready: TrainingKeys.exerciseBoard,
    );
    final scroll = find
        .descendant(
          of: find.byKey(TrainingKeys.exerciseFeedbackScroll),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = $.tester.state<ScrollableState>(scroll).position;
    expect(position.pixels, 0);
    await $.tester.drag(
      find.byKey(TrainingKeys.exerciseFeedbackScroll),
      const Offset(0, -80),
    );
    await $.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    await capture.shot(
      'real-feedback-scrolled',
      ready: TrainingKeys.exerciseBoard,
    );
    await $(TrainingKeys.exerciseFeedbackExpand).tap();
    await capture.shot(
      'real-feedback-expanded',
      ready: TrainingKeys.exerciseFeedbackSheet,
    );
    await $(SheetKeys.close).tap();
    // Retry behavior and the persisted score are asserted after the UI action.
    await $(TrainingKeys.exercisePracticeRetry).tap();
    expect(cubit.state.phase, TrainingExercisePhase.playing);
    expect(cubit.state.fen, exercise.fen);
    await capture.shot(
      'real-exercise-retry',
      ready: TrainingKeys.exerciseBoard,
    );
    expect(
      (await repository.load(TrainingCourse.pilares)).toJson(),
      before.toJson(),
    );
    await capture.end('real-feedback-retry');
  }, tags: const ['training-real-feedback']);
}
