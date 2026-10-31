import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/lesson_finished_keys.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/routing/routes.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() {
  patrolTest('T85 Progresso e domínio do tema', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.progress,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    final guide = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<CourseGuideCubit>();
    final data = await guide.repository.resources(TrainingCourse.pilares);
    final source = guide.testLessons;
    expect(source, isNotNull);
    final lessons = source!;
    final trail = await lessons.trail();
    final tests = data.lessons
        .where((l) => l.kind == TrainingLessonKind.test)
        .map((l) => trail.lesson(l.id))
        .whereType<EndgameLesson>()
        .where((l) => l.exercises.isNotEmpty)
        .toList();
    expect(tests, isNotEmpty);
    final completedTest = tests.first;
    await seedEndgameProgress(
      EndgameProgress(
        lessons: {
          completedTest.id: EndgameLessonProgress(
            lessonDone: true,
            approved: true,
            stars: {
              for (final exercise in completedTest.exercises)
                exercise.id: exercise.stars,
            },
          ),
        },
      ),
    );
    await guide.load();
    await capture.tab('progress');
    await capture.shot('progress-pilares');
    final guideTexts = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .l10n;
    await $(find.text(guideTexts.trainingTestsTitle)).scrollTo();
    await capture.shot('progress-tests');
    final lastTest = data.lessons.lastWhere(
      (l) => l.kind == TrainingLessonKind.test,
    );
    // Locked course rows intentionally ignore hit tests. They still need to
    // be visible in the screenshot, so scroll their render object directly.
    await $.tester.ensureVisible(
      find.byKey(CourseGuideKeys.chapterLesson(lastTest.id)),
    );
    await $.pumpAndSettle();
    await capture.shot('progress-tests-bottom');
    final cubit = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<CourseGuideCubit>();
    final theme = cubit.state.training!.cycles.keys.first;
    await $.tester.scrollUntilVisible(
      find.byKey(TrainingKeys.masteryRow(theme)),
      -500,
      maxScrolls: 50,
    );
    await $.pumpAndSettle();
    await $(TrainingKeys.masteryRow(theme)).tap();
    await capture.shot('progress-theme', ready: TrainingKeys.themeScreen);
    await $(TrainingKeys.themeChart).scrollTo();
    await capture.shot('progress-theme-chart', ready: TrainingKeys.themeScreen);
    await $(BackButton).tap();
    await capture.shot('progress-theme-back');
    // The visual fixture seeds chapter completion above. Verify that its
    // actual completion route retains the private source and final test.
    final chapterTitle = (await lessons.texts('pt'))
        .lessonTitle(completedTest.id);
    expect(chapterTitle, isNot(completedTest.id));
    final router = GoRouter.of(
      $.tester.element(find.byKey(CourseGuideKeys.screen)),
    );
    unawaited(
      router.push<void>(
        Routes.lessonFinished(SurveyKind.endgames, completedTest.id),
      ),
    );
    await $(LessonFinishedKeys.screen).waitUntilVisible();
    await $(NextStepsKeys.option('exercises')).scrollTo();
    expect(find.text(chapterTitle), findsOneWidget);
    expect(find.byKey(NextStepsKeys.option('train')), findsNothing);
    await capture.shot(
      'pilares-after-chapter',
      ready: LessonFinishedKeys.screen,
    );
    await $(NextStepsKeys.option('exercises')).tap();
    await $(ExercisesIntroKeys.screen).waitUntilVisible();
    final intro = $.tester
        .element(find.byKey(ExercisesIntroKeys.screen))
        .read<EndgameLessonCubit>();
    final loading = Stopwatch()..start();
    while (intro.state.lesson == null &&
        loading.elapsed < const Duration(seconds: 10)) {
      await $.pump(const Duration(milliseconds: 100));
    }
    expect(intro.state.lesson?.id, completedTest.id);
    expect(intro.state.lesson!.practice, isNull);
    expect(
      intro.state.lesson!.exercises,
      hasLength(completedTest.exercises.length),
    );
    await capture.shot('pilares-test-intro', ready: ExercisesIntroKeys.screen);
  }, tags: ['training-progress-visual']);

  patrolTest('T85 Ajuda e seis respostas', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await $(CourseGuideKeys.helpAction).tap();
    await capture.shot('help-initial', ready: TrainingKeys.helpScreen);
    final texts = $.tester.element(find.byKey(TrainingKeys.helpScreen)).l10n;
    final answers = [
      texts.courseGuideFaq1Answer,
      texts.courseGuideFaq2Answer,
      texts.courseGuideFaq3Answer,
      texts.courseGuideFaq4Answer,
      texts.courseGuideFaq5Answer,
      texts.courseGuideFaq6Answer,
    ];
    for (var i = 0; i < answers.length; i++) {
      if (i > 0) {
        await $(TrainingKeys.faq(i)).scrollTo().tap();
        await $(TrainingKeys.faq(i + 1)).scrollTo().tap();
      }
      await $(find.text(answers[i])).scrollTo();
      await capture.shot('help-faq-${i + 1}', ready: TrainingKeys.helpScreen);
    }
    await $(TrainingKeys.helpBack).tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
  }, tags: ['training-help-visual']);

  patrolTest('T85 quatro passos do tour persistem sem reabrir', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await $(CourseGuideKeys.helpAction).tap();
    await $(TrainingKeys.helpTour).tap();
    await $(TrainingKeys.tourOverlay).waitUntilVisible();
    for (var step = 1; step <= 4; step++) {
      await capture.shot('tour-$step', ready: TrainingKeys.tourOverlay);
      await $(TrainingKeys.tourNext).tap();
    }
    await $(CourseGuideKeys.screen).waitUntilVisible();
    final repository = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<TrainingRepository>();
    expect((await repository.load(TrainingCourse.pilares)).tourSeen, isTrue);
    expect(find.byKey(TrainingKeys.tourOverlay), findsNothing);
    await capture.shot('tour-completed-back');
  }, tags: ['training-tour-visual']);
}
