import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/services/notification_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/lesson_finished_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:lucena/domain/use_cases/training/reminder_text.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/reminders/widgets/l10n_reminder_texts.dart';
import 'package:lucena/ui/reminders/view_models/reminders_cubit.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';
import 'robots/star_challenge_robot.dart';
import 'robots/training_acceptance_robot.dart';
import 'robots/script_lesson_robot.dart';
import 'robots/home_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/speedrun_robot.dart';
import 'training_transitions_test.dart' as transitions;
import 'training_openings_completion_test.dart' as opening_completion;

/// T85 §10 acceptance flows. All actions use the app; clock and banks are E2E fixtures.
void main() {
  transitions.registerTrainingTransitionTests();
  opening_completion.registerTrainingOpeningCompletionTests();
  for (final course in TrainingCourse.values) {
    final school = course == TrainingCourse.escola;
    patrolTest('T85 plano agenda texto local ${course.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: school
            ? E2ETrainingScenario.schoolWelcome
            : E2ETrainingScenario.welcome,
      );
      final capture = TrainingCaptureRobot($);
      await capture.openGuide(escola: school);
      await $(CourseGuideKeys.continueButton).tap();
      await $(TrainingKeys.planScreen).waitUntilVisible();
      await $(TrainingKeys.planChip(30)).tap();
      await $(TrainingKeys.planSave).scrollTo().tap();
      await $(CourseGuideKeys.screen).waitUntilVisible();
      final context = $.tester.element(find.byKey(CourseGuideKeys.screen));
      final guide = context.read<CourseGuideCubit>();
      final saved = await context.read<TrainingRepository>().load(course);
      expect(saved.plan.minutes, 30);
      expect(saved.plan.reminderOn, isTrue);
      final texts = L10nReminderTexts(context.l10n);
      final text = reminderText(saved.day!)!;
      final lessonId = text.arguments['aula'];
      final title = guide.state.resources!.lessons
          .where((lesson) => lesson.id == lessonId)
          .firstOrNull
          ?.title;
      await $(CourseGuideKeys.planAction).waitUntilVisible();
      // The scheduling path is asynchronous and uses the production bridge.
      Iterable<ScheduledNotification> scheduled() => e2eNotifications.scheduled
          .where((n) => n.id == RemindersCubit.trainingFirstId + course.index);
      final watch = Stopwatch()..start();
      while (scheduled().isEmpty) {
        expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
        await $.pump();
      }
      expect(scheduled().single.body, texts.trainingBody(text, title));
      expect(scheduled().single.title, texts.trainingTitle);
      await capture.shot('plan-saved-${course.name}');
    });

    patrolTest('T85 retoma tentativa sem concluir ${course.name}', ($) async {
      final app = AppRobot($);
      await app.open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: school
            ? E2ETrainingScenario.schoolPieces
            : E2ETrainingScenario.cycle,
      );
      final capture = TrainingCaptureRobot($);
      await capture.openGuide(escola: school);
      await capture.tab('goals');
      final context = $.tester.element(find.byKey(CourseGuideKeys.screen));
      final before = context.read<CourseGuideCubit>().state.training!;
      final goal = before.day!.goals.firstWhere(
        (g) => g.kind == (school ? GoalKind.stars : GoalKind.exercise),
      );
      await $(TrainingKeys.goalTile(goal.kind.name, goal.ref)).scrollTo().tap();
      if (school) {
        await $(StarChallengeKeys.screen).waitUntilVisible();
        await StarChallengeRobot($).go();
        await StarChallengeRobot($).collect();
      } else {
        await $(TrainingKeys.exerciseBoard).waitUntilVisible();
        await capture.hint();
      }
      await app.restart();
      if (school) {
        // The existing stars flow restores its open challenge directly at
        // Ready after process loss, without awarding the unfinished run.
        await $(StarChallengeKeys.goButton).waitUntilVisible();
      } else {
        await capture.openGuide();
      }
      final repository = $.tester
          .element(
            find.byKey(
              school ? StarChallengeKeys.screen : CourseGuideKeys.screen,
            ),
          )
          .read<TrainingRepository>();
      final resumed = await repository.load(course);
      final again = resumed.day!.goals.singleWhere((g) => g.key == goal.key);
      expect(again.done, isFalse);
      expect(again.itemId, goal.itemId);
      if (!school) expect(again.hintUsed, isTrue);
      if (!school) {
        await capture.tab('goals');
        await $(TrainingKeys.goalTile(goal.kind.name, goal.ref))
            .scrollTo()
            .tap();
      }
      await $(school ? StarChallengeKeys.goButton : TrainingKeys.exerciseBoard)
          .waitUntilVisible();
      await capture.shot(
        'resume-${course.name}',
        ready: school ? StarChallengeKeys.screen : TrainingKeys.exerciseBoard,
      );
    }, tags: ['training-resume-${course.name}']);
  }
  patrolTest('T85 Escola boas-vindas quatro aulas torre e estrelas', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.schoolWelcome,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide(escola: true);
    await $(CourseGuideKeys.continueButton).scrollTo().tap();
    await $(TrainingKeys.planChip(30)).tap();
    await $(TrainingKeys.planSave).scrollTo().tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await capture.tab('goals');
    final repository = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<TrainingRepository>();
    final planned = await repository.load(TrainingCourse.escola);
    expect(
      planned.day!.goals.where((g) => g.kind == GoalKind.lesson),
      hasLength(4),
    );
    await $(TrainingKeys.goalTile('lesson', 'pieces.rook')).scrollTo().tap();
    await $(LessonScriptKeys.board).waitUntilVisible();
    final lesson = ScriptLessonRobot($, manualClock: true);
    // These moves are the authored answers/practice sequence in the real rook
    // lesson. No exercise dataset or lesson-completion repository is replaced.
    await lesson.advanceToExample('ideia', 0, ScriptPhase.pergunta);
    await lesson.move('d4', 'd8');
    await lesson.settle(4);
    await lesson.advanceToExample('ideia', 1, ScriptPhase.pergunta);
    await lesson.move('c1', 'd1');
    await lesson.settle(4);
    await lesson.advanceToExample('pratica', 0, ScriptPhase.praticaVez);
    for (final move in ['a1a6', 'a6f6', 'f6f2']) {
      await lesson.move(move.substring(0, 2), move.substring(2));
      await lesson.settle(4);
      expect(lesson.state.lastMove, move);
    }
    expect(lesson.state.phase, ScriptPhase.praticaFim);
    await lesson.advanceToExample('pratica', 1, ScriptPhase.praticaVez);
    for (final move in ['f1f5', 'f5e5', 'e5e8', 'e8f8', 'f8b8']) {
      await lesson.move(move.substring(0, 2), move.substring(2));
      await lesson.settle(4);
      expect(lesson.state.lastMove, move);
    }
    expect(lesson.state.phase, ScriptPhase.praticaFim);
    await lesson.advanceUntil(
      () => find.byKey(LessonFinishedKeys.screen).evaluate().isNotEmpty,
    );
    await $(LessonFinishedKeys.back).tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await capture.tab('goals');
    final completed = await repository.load(TrainingCourse.escola);
    final stars = completed.day!.goals.singleWhere(
      (g) => g.kind == GoalKind.stars && g.ref == 'pieces.rook',
    );
    expect(stars.stars, 1);
    expect(stars.done, isFalse);
    await $(TrainingKeys.goalTile('stars', stars.ref)).scrollTo().tap();
    await $(StarChallengeKeys.screen).waitUntilVisible();
    await TrainingAcceptanceRobot($).finishStars();
    await $(TrainingKeys.nextGoal).waitUntilVisible();
    await capture.shot('school-stars-next-goal', ready: TrainingKeys.nextGoal);
    await capture.record('school-stars-next-goal', () async {
      await $(TrainingKeys.nextGoal).tap();
    }, ready: CourseGuideKeys.screen);
    final saved = await repository.load(TrainingCourse.escola);
    expect(
      saved.day!.goals.singleWhere((g) => g.key == stars.key).done,
      isTrue,
    );
    await capture.shot('school-rook-followup-complete');
  }, tags: ['training-school', 'training-school-learning']);
  patrolTest('T85 Escola torre três níveis e um dia perdido', ($) async {
    final app = AppRobot($);
    await app.open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.schoolPieces,
    );
    final capture = TrainingCaptureRobot($);
    for (var level = 0; level < 3; level++) {
      await capture.openGuide(escola: true);
      await capture.tab('goals');
      final repository = $.tester
          .element(find.byKey(CourseGuideKeys.screen))
          .read<TrainingRepository>();
      final before = await repository.load(TrainingCourse.escola);
      final goal = before.day!.goals.singleWhere(
        (g) => g.kind == GoalKind.stars && g.ref == 'pieces.rook',
      );
      expect(goal.stars, level + 1);
      expect(goal.done, isFalse);
      await $(TrainingKeys.goalTile('stars', goal.ref)).scrollTo().tap();
      await $(StarChallengeKeys.screen).waitUntilVisible();
      await TrainingAcceptanceRobot($).finishStars();
      await $(TrainingKeys.nextGoal).waitUntilVisible();
      await $(TrainingKeys.nextGoal).tap();
      await $(CourseGuideKeys.screen).waitUntilVisible();
      final after = await repository.load(TrainingCourse.escola);
      expect(after.school.pieceLevels['rook'], level + 1);
      expect(
        after.day!.goals.singleWhere((g) => g.key == goal.key).done,
        isTrue,
      );
      await capture.shot('school-rook-level-${level + 1}');
      // One whole missed day between medium and hard grants no advancement.
      await app.advanceTime(Duration(days: level == 1 ? 2 : 1));
      await app.restart();
    }
    await capture.openGuide(escola: true);
    final state = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<CourseGuideCubit>()
        .state
        .training!;
    expect(state.school.pieceLevels['rook'], 3);
    expect(
      state.day!.goals.where(
        (g) => g.kind == GoalKind.stars && g.ref == 'pieces.rook',
      ),
      isEmpty,
    );
    await capture.tab('progress');
    await capture.shot('school-rook-three-stars');
  }, tags: ['training-school', 'training-school-levels']);
  patrolTest('T85 Escola Primeiros mates Coco e speedrun', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.schoolMates,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide(escola: true);
    await capture.tab('goals');
    final repository = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<TrainingRepository>();
    final planned = await repository.load(TrainingCourse.escola);
    final bots = planned.day!.goals
        .where((g) => g.kind == GoalKind.bot)
        .toList();
    expect(bots, hasLength(2));
    final speedrun = planned.day!.goals.singleWhere(
      (g) => g.kind == GoalKind.speedrun,
    );
    expect(speedrun.itemId, 'journey.mates');
    expect(speedrun.items['initialSeconds'], '900');
    await capture.shot('school-mates-followups');
    for (final goal in bots) {
      await $(TrainingKeys.goalTile('bot', goal.ref)).scrollTo().tap();
      await $(JourneyKeys.challengeScreen).waitUntilVisible();
      expect(find.textContaining('Coco'), findsWidgets);
      // Same legal mate-in-one fixture used by journey_test.dart. The game
      // writes a real dated source attempt for this exact rung/position ID.
      final board = FreeBoardRobot($);
      await board.openAt(
        '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        opponent: 'maia',
        level: 1000,
        user: Side.white,
        goal: 'win',
        position: goal.itemId,
        challenge: '1000/${goal.itemId}',
        fromScreen: JourneyKeys.challengeScreen,
        preserveStack: true,
      );
      await board.move('h1', 'h8');
      await ConclusionRobot($).close();
      await $(JourneyKeys.challengeScreen).waitUntilVisible();
      await $(TrainingKeys.nextGoal).waitUntilVisible();
      final proof = 'school-bot-next-goal-${goal.itemId}'.replaceAll('.', '-');
      await capture.shot(proof, ready: TrainingKeys.nextGoal);
      await capture.record(proof, () async {
        await $(TrainingKeys.nextGoal).tap();
      }, ready: CourseGuideKeys.screen);
      final observed = await repository.load(TrainingCourse.escola);
      expect(
        observed.day!.goals.singleWhere((g) => g.key == goal.key).done,
        isTrue,
      );
      await $.tester.scrollUntilVisible(
        find.byKey(TrainingKeys.goalTile('bot', goal.ref)),
        200,
        maxScrolls: 20,
      );
      await capture.shot('$proof-done');
    }
    await $(TrainingKeys.goalTile('speedrun', speedrun.ref)).scrollTo().tap();
    await $(SpeedrunKeys.screen).waitUntilVisible();
    await SpeedrunRobot($).start();
    await FreeBoardRobot($).resign();
    await ConclusionRobot($).close();
    await $(SpeedrunKeys.screen).waitUntilVisible();
    await $(TrainingKeys.nextGoal).waitUntilVisible();
    await capture.shot(
      'school-speedrun-next-goal',
      ready: TrainingKeys.nextGoal,
    );
    await capture.record('school-speedrun-next-goal', () async {
      await $(TrainingKeys.nextGoal).tap();
    }, ready: CourseGuideKeys.screen);
    final finished = await repository.load(TrainingCourse.escola);
    expect(
      finished.day!.goals
          .where((g) => g.kind == GoalKind.bot || g.kind == GoalKind.speedrun)
          .every((g) => g.done),
      isTrue,
    );
    await capture.shot('school-mates-followups-done');
    await $.tester.scrollUntilVisible(
      find.byKey(TrainingKeys.goalTile('speedrun', speedrun.ref)),
      200,
      maxScrolls: 20,
    );
    await capture.shot('school-speedrun-meta-done-bottom');
  }, tags: ['training-school-mates']);
  patrolTest('T85 Home acompanha a última meta dos dois cursos', ($) async {
    final app = AppRobot($);
    await app.open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.schoolLatest,
    );
    final capture = TrainingCaptureRobot($);
    await $(HomeKeys.courseCard).waitUntilVisible();
    HomeTraining selected() => $.tester
        .element(find.byKey(HomeKeys.screen))
        .read<HomeCubit>()
        .state
        .training!;
    expect(selected().config.course, TrainingCourse.pilares);
    await $(HomeKeys.goalAction).tap();
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await capture.move('a1a8');
    await $(TrainingKeys.nextGoal).tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await _homeFromGuide($);
    expect(selected().config.course, TrainingCourse.pilares);
    await capture.shot('home-latest-pilares', ready: HomeKeys.courseCard);
    await app.advanceTime(const Duration(minutes: 1));
    await capture.openGuide(escola: true);
    await capture.tab('goals');
    final guide = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<CourseGuideCubit>();
    final goal = guide.state.training!.day!.next!;
    expect(goal.kind, GoalKind.stars);
    await $(TrainingKeys.goalTile('stars', goal.ref)).scrollTo().tap();
    await TrainingAcceptanceRobot($).finishStars();
    await $(TrainingKeys.nextGoal).tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await _homeFromGuide($);
    final watch = Stopwatch()..start();
    while (selected().config.course != TrainingCourse.escola) {
      expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
      await $.pump();
    }
    expect(selected().config.course, TrainingCourse.escola);
    await capture.shot('home-latest-escola', ready: HomeKeys.courseCard);
    final next = selected().card.goal!;
    expect(next.kind, GoalKind.stars);
    await $(HomeKeys.goalAction).tap();
    await $(StarChallengeKeys.screen).waitUntilVisible();
    await TrainingAcceptanceRobot($).finishStars();
    await $(TrainingKeys.nextGoal).waitUntilVisible();
    await capture.shot('school-stars-next-goal', ready: TrainingKeys.nextGoal);
    await capture.record('home-school-next-goal', () async {
      await $(TrainingKeys.nextGoal).tap();
    }, ready: CourseGuideKeys.screen);
    final saved = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<CourseGuideCubit>()
        .state
        .training!;
    expect(saved.tab, CourseGuideTab.goals);
    expect(saved.day!.goals.singleWhere((g) => g.key == next.key).done, isTrue);
    await capture.shot('home-school-next-goal-done');
    await $.tester.scrollUntilVisible(
      find.byKey(TrainingKeys.goalTile(next.kind.name, next.ref)),
      200,
      maxScrolls: 20,
    );
    await capture.shot('school-stars-meta-done-bottom');
    final completed = e2eAnalytics
        .eventsNamed('treino_meta_fim')
        .where(
          (event) =>
              event.params['curso'] == 'escola' &&
              event.params['origem'] == 'home',
        );
    expect(completed, hasLength(1));
    expect(completed.single.params['mock'], 'nao');
  }, tags: ['training-home-course']);
  for (final course in TrainingCourse.values) {
    patrolTest('T85 Home folga ${course.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: course == TrainingCourse.escola
            ? E2ETrainingScenario.schoolDayOff
            : E2ETrainingScenario.dayOff,
      );
      await $(HomeKeys.courseCard).waitUntilVisible();
      final selected = $.tester
          .element(find.byKey(HomeKeys.screen))
          .read<HomeCubit>()
          .state
          .training!;
      expect(selected.config.course, course);
      expect(selected.card.status, HomeCourseStatus.dayOff);
      await TrainingCaptureRobot($)
          .shot('home-rest-${course.name}', ready: HomeKeys.courseCard);
    }, tags: ['training-home-course']);
  }
  for (final phase in [
    ThemePhase.firm,
    ThemePhase.reinforce,
    ThemePhase.redo,
  ]) {
    patrolTest('T85 sete dias fecham ciclo ${phase.name}', ($) async {
      final app = AppRobot($);
      await app.open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        trainingScenario: E2ETrainingScenario.cycle,
      );
      final capture = TrainingCaptureRobot($);
      await capture.openGuide();
      final guide = $.tester
          .element(find.byKey(CourseGuideKeys.screen))
          .read<CourseGuideCubit>();
      final id = guide.state.training!.cycles.keys.single;
      for (var day = 0; day < 7; day++) {
        await capture.exercise(id);
        final correct =
            phase == ThemePhase.firm ||
            phase == ThemePhase.reinforce && day < 4;
        await capture.move(correct ? 'a1a8' : 'a1a2');
        await $(TrainingKeys.nextGoal).tap();
        if (day < 6) {
          await $(CourseGuideKeys.screen).waitUntilVisible();
          await app.advanceTime(const Duration(days: 1));
          await app.restart();
          await capture.openGuide();
        }
      }
      await $(TrainingKeys.exerciseEnd).waitUntilVisible();
      final repository = $.tester
          .element(find.byKey(TrainingKeys.exerciseEnd))
          .read<TrainingRepository>();
      final saved = await repository.load(TrainingCourse.pilares);
      expect(saved.cycles[id]!.cycleDays, hasLength(7));
      expect(saved.cycles[id]!.phase, phase);
      expect(
        saved.cycles[id]!.score,
        phase == ThemePhase.firm
            ? 100
            : phase == ThemePhase.reinforce
            ? 40
            : 0,
      );
      await capture.shot(
        'cycle-${phase.name}',
        ready: TrainingKeys.exerciseEnd,
      );
      if (phase == ThemePhase.reinforce) {
        final count = saved.cycles[id]!.reinforcement.length;
        await $(TrainingKeys.endPrimary).tap();
        for (var i = 0; i < count; i++) {
          await $(CourseGuideKeys.screen).waitUntilVisible();
          await app.advanceTime(const Duration(days: 1));
          await app.restart();
          await capture.openGuide();
          await capture.tab('goals');
          await $(TrainingKeys.goalTile('reinforce', id)).scrollTo().tap();
          await $(TrainingKeys.exerciseBoard).waitUntilVisible();
          await capture.move('a1a2');
          await $(TrainingKeys.nextGoal).tap();
        }
        await $(TrainingKeys.exerciseEnd).waitUntilVisible();
        final reinforced = await $.tester
            .element(find.byKey(TrainingKeys.exerciseEnd))
            .read<TrainingRepository>()
            .load(TrainingCourse.pilares);
        expect(reinforced.cycles[id]!.phase, ThemePhase.redo);
        expect(reinforced.cycles[id]!.reinforceDays, hasLength(count));
        await capture.shot('cycle-redo-after', ready: TrainingKeys.exerciseEnd);
      }
    }, tags: ['training-cycle']);
  }
}

Future<void> _homeFromGuide(PatrolIntegrationTester $) async {
  for (
    var i = 0;
    i < 3 && find.byKey(HomeKeys.screen).evaluate().isEmpty;
    i++
  ) {
    await $(BackButton).tap();
  }
  await HomeRobot($).expectVisible();
}
