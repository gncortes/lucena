import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/script_lesson_robot.dart';
import 'robots/training_capture_robot.dart';

void main() => registerTrainingTransitionTests();

void registerTrainingTransitionTests() {
  for (final scenario in [
    E2ETrainingScenario.large,
    E2ETrainingScenario.schoolDayOne,
  ]) {
    patrolTest('T85 Hero Home aula ${scenario.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: scenario,
      );
      final capture = TrainingCaptureRobot($);
      await $(HomeKeys.courseCard).waitUntilVisible();
      final name = 'home-lesson-${scenario.name}';
      await capture.record(name, () async {
        await $(HomeKeys.goalAction).tap();
      }, ready: LessonScriptKeys.board);
      final lesson = ScriptLessonRobot($);
      final loading = Stopwatch()..start();
      while (!lesson.state.ready &&
          loading.elapsed < const Duration(seconds: 10)) {
        await $.pump(const Duration(milliseconds: 100));
      }
      expect(
        lesson.state.ready,
        isTrue,
        reason: 'The lesson must load its real source beyond the Home preview',
      );
      await capture.shot(name, ready: LessonScriptKeys.board);
      await $(LessonScriptKeys.close).tap();
      await $(CourseGuideKeys.screen).waitUntilVisible();
      await capture.shot('$name-back');
    }, tags: ['training-transition-lesson']);
  }

  patrolTest('T85 Hero Home meta e Próxima meta', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.meta,
    );
    final capture = TrainingCaptureRobot($);
    await $(HomeKeys.courseCard).waitUntilVisible();
    await capture.record('home-meta', () async {
      await $(HomeKeys.goalAction).tap();
    }, ready: TrainingKeys.exerciseBoard);
    await capture.shot(
      'home-meta-destination',
      ready: TrainingKeys.exerciseBoard,
    );
    await capture.move('a8a1');
    await capture.record('next-goal', () async {
      await $(TrainingKeys.nextGoal).tap();
    }, ready: CourseGuideKeys.screen);
    await capture.shot('next-goal-destination');
    final completed = e2eAnalytics
        .eventsNamed('treino_meta_fim')
        .where(
          (event) =>
              event.params['curso'] == 'pilares' &&
              event.params['origem'] == 'home',
        );
    expect(completed, hasLength(1));
    expect(completed.single.params['mock'], 'sim');
  }, tags: ['training-transition-meta']);

  patrolTest('T85 Hero Home parte, revisão e próxima meta explícita', (
    $,
  ) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.opening,
    );
    final capture = TrainingCaptureRobot($);
    await $(HomeKeys.courseCard).waitUntilVisible();
    await capture.record('home-opening', () async {
      await $(HomeKeys.goalAction).tap();
    }, ready: TrainingKeys.openingBoard);
    await capture.shot('opening-before', ready: TrainingKeys.openingBoard);
    await capture.openingMove('a2a3');
    await capture.shot('opening-wrong', ready: TrainingKeys.openingBoard);
    await capture.openingMove('d2d4');
    await $(TrainingKeys.prevMove).tap();
    await capture.shot('opening-review', ready: TrainingKeys.openingBoard);
    await $(TrainingKeys.nextMove).tap();
    await $.pumpAndSettle();
    final cubit = $.tester
        .element(find.byKey(TrainingKeys.openingScreen))
        .read<TrainingOpeningCubit>();
    final next = cubit.state.pending.firstWhere(
      (id) => id != cubit.state.lessonId,
    );
    await capture.record('opening-part-complete', () async {
      await capture.openingMove('c1f4');
    }, ready: TrainingKeys.nextGoal);
    expect(cubit.state.phase, TrainingOpeningPhase.complete);
    await capture.shot('opening-part-end', ready: TrainingKeys.nextGoal);
    await capture.record('opening-next-goal', () async {
      await $(TrainingKeys.nextGoal).tap();
    }, ready: CourseGuideKeys.screen);
    await capture.record('opening-open-next', () async {
      final target = find.byKey(TrainingKeys.trainTrecho(next));
      await $.tester.scrollUntilVisible(target, 150);
      await $.tester.ensureVisible(target);
      await $.pumpAndSettle();
      await $(TrainingKeys.trainTrecho(next)).tap();
    }, ready: TrainingKeys.openingTitle(next));
    await capture.shot(
      'opening-after-next-goal',
      ready: TrainingKeys.openingBoard,
    );
    await $(TrainingKeys.openingBack).tap();
    await capture.shot('opening-back-list', ready: CourseGuideKeys.screen);
  }, tags: ['training-transition-opening']);
}
