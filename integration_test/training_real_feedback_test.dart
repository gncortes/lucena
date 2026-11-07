import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/training_date.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/script_speech_sheet.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';
import '../testing/training/training_fixture_scope.dart';
import '../testing/training/training_fixture_preferences.dart';
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
      TrainingFixturePreferences('real-feedback'),
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
          builder: (_) => TrainingFixtureScope(
            repository: repository,
            now: e2eNow,
            child: TrainingExerciseScreen(
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
      ),
    );
    try {
      await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    } catch (_) {
      final saved = await repository.load(TrainingCourse.pilares);
      final state = $.tester
          .element(find.byType(Scaffold).last)
          .read<TrainingExerciseCubit>()
          .state;
      throw TestFailure(
        'Real feedback load: phase=${state.phase}; failure=${state.failure}; '
        'date=${saved.day?.date}; '
        'goals=${saved.day?.goals.map((g) => '${g.kind}/${g.itemId}/${g.done}').toList()}; '
        'cycle=${saved.cycles[lesson]?.phase}/${saved.cycles[lesson]?.level}',
      );
    }
    await capture.shot(
      'real-exercise-before',
      ready: TrainingKeys.exerciseBoard,
    );
    await capture.begin('real-feedback-retry');
    final cubit = $.tester
        .element(find.byKey(TrainingKeys.exerciseBoard))
        .read<TrainingExerciseCubit>();
    expect(cubit.state.exercise!.id, exercise.id);
    expect(cubit.state.fen, exercise.fen);
    expect(
      GameRules.play(GameRules.fromFen(exercise.fen)!, Move.parse(parts[2])!),
      isNotNull,
      reason:
          'Approved feedback key must be legal in its source position: $key',
    );
    try {
      await capture.move(parts[2]);
    } catch (_) {
      final saved = await repository.load(TrainingCourse.pilares);
      throw TestFailure(
        'Real feedback move=$key; phase=${cubit.state.phase}; '
        'error=${cubit.state.error}; date=${saved.day?.date}; '
        'goals=${saved.day?.goals.map((g) => '${g.kind}/${g.itemId}/${g.done}').toList()}; '
        'days=${saved.cycles[lesson]?.days.map((d) => d.exerciseId).toList()}',
      );
    }
    expect(cubit.state.correct, false);
    expect(cubit.state.errorFeedback, texts[key]);
    final before = await repository.load(TrainingCourse.pilares);
    expect(before.day!.allDone, true);
    expect(before.day!.goals.single.exerciseError!.feedbackShown, true);
    await capture.shot(
      'real-exercise-feedback',
      ready: TrainingKeys.exerciseBoard,
    );
    await $(LessonScriptKeys.speech).tap();
    await $(TrainingKeys.exerciseFeedbackSheet).waitUntilVisible();
    expect(
      $.tester.widget<ScriptSpeechSheet>(find.byType(ScriptSpeechSheet)).texts,
      [texts[key]],
    );
    final scroll = find
        .descendant(
          of: find.byKey(TrainingKeys.exerciseFeedbackSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = $.tester.state<ScrollableState>(scroll).position;
    expect(position.pixels, 0);
    await $.tester.drag(scroll, const Offset(0, -80));
    await $.pumpAndSettle();
    expect(position.pixels > 0, position.maxScrollExtent > 0);
    await capture.shot(
      'real-feedback-scrolled',
      ready: TrainingKeys.exerciseFeedbackSheet,
    );
    expect(
      $.tester.getRect(find.byKey(LessonScriptKeys.speechSheetClose)).bottom,
      lessThan(
        $.tester.getRect(find.byKey(TrainingKeys.exerciseFeedbackSheet)).top,
      ),
    );
    await capture.shot(
      'real-feedback-expanded',
      ready: TrainingKeys.exerciseFeedbackSheet,
    );
    await $(LessonScriptKeys.speechSheetClose).tap();
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
