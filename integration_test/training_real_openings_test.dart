import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/play_training_opening.dart';
import 'package:lucena/domain/use_cases/training/training_date.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_screen.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() {
  for (final scenario in [
    'question',
    'practice-opposite',
    'practice-alternative',
    'question-alternative',
    'snapshot',
  ]) {
    patrolTest('T85 abertura autorada real $scenario', ($) async {
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
        installSeed: 'native-real-openings',
      );
      addTearDown(repository.dispose);
      final resources = await repository.resources(TrainingCourse.pilares);
      final excerpts = [
        for (final entry in resources.openings.entries)
          for (final excerpt in entry.value)
            (lesson: entry.key, excerpt: excerpt),
      ];
      expect(excerpts, hasLength(457));
      expect(excerpts.where((entry) => entry.excerpt.mock), isEmpty);
      final selected = excerpts.firstWhere(
        (entry) => _matches(scenario, entry.lesson, entry.excerpt),
      );
      final lesson = selected.lesson, excerpt = selected.excerpt;
      final date = trainingDate(e2eNow());
      await repository.transact(
        TrainingCourse.pilares,
        (old) => TrainingState(
          course: TrainingCourse.pilares,
          installSeed: old.installSeed,
          onboardingDone: true,
          day: DayGoals(
            date: date,
            studyDay: true,
            goals: [
              TrainingGoal(
                kind: GoalKind.openings,
                ref: 'openings',
                items: {lesson: excerpt.id},
              ),
            ],
          ),
          openings: {lesson: OpeningTrack(lessonId: lesson, startedOn: date)},
        ),
      );
      if (!context.mounted) throw StateError('Guide was unmounted');
      unawaited(
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => TrainingOpeningScreen(
              repository: repository,
              config: TrainingCourseConfig.pilares,
              now: e2eNow,
              lessonId: lesson,
              teacher: teacher,
              onNextGoal: () {},
            ),
          ),
        ),
      );
      await $(TrainingKeys.openingBoard).waitUntilVisible();
      await $.pumpAndSettle();
      final cubit = $.tester
          .element(find.byKey(TrainingKeys.openingBoard))
          .read<TrainingOpeningCubit>();
      expect(cubit.state.phase, TrainingOpeningPhase.playing);
      final proof = 'real-opening-$scenario';
      await capture.shot('$proof-before', ready: TrainingKeys.openingBoard);
      await capture.begin(proof);
      var recording = true;
      addTearDown(() async {
        if (recording) {
          await capture.end(proof);
        }
      });
      var played = 0;
      while (cubit.state.phase == TrainingOpeningPhase.playing) {
        if (played > 100) throw StateError('Authored opening did not finish');
        final before = cubit.state;
        final accepted = before.line!.acceptedAt(before.cursor);
        expect(accepted, isNotEmpty);
        var move = accepted.first;
        if (played == 0 && scenario == 'practice-alternative') {
          move = accepted.last;
        }
        if (played == 0 && scenario == 'question-alternative') {
          move = excerpt.script!.question!.alternatives.keys.first;
          expect(accepted, contains(move));
        }
        await capture.openingMove(move);
        expect(cubit.state.cursor, greaterThan(before.cursor));
        expect(cubit.state.wrong, false);
        played++;
        if (played == 1) {
          final current = cubit.state;
          await capture.shot(
            '$proof-after-move',
            ready: TrainingKeys.openingBoard,
          );
          await $(TrainingKeys.prevMove).tap();
          expect(cubit.state.reviewing, true);
          await capture.shot('$proof-review', ready: TrainingKeys.openingBoard);
          while (cubit.state.reviewing) {
            await $(TrainingKeys.nextMove).tap();
          }
          expect(cubit.state.fen, current.fen);
        }
      }
      await $(TrainingKeys.nextGoal).waitUntilVisible();
      await $.pumpAndSettle();
      expect(cubit.state.phase, TrainingOpeningPhase.complete);
      final saved = await repository.load(TrainingCourse.pilares);
      expect(saved.openings[lesson]!.doneTrechos[excerpt.id], date);
      expect(
        saved.openings[lesson]!.firstTry[excerpt.id],
        List.filled(played, true),
      );
      expect(saved.day!.allDone, true);
      await capture.shot('$proof-complete', ready: TrainingKeys.openingBoard);
      await capture.end(proof);
      recording = false;
    }, tags: const ['training-real-openings']);
  }
}

bool _matches(String scenario, String lesson, OpeningTrecho excerpt) {
  final example = excerpt.script;
  if (example == null) return false;
  final line = PlayTrainingOpening(excerpt);
  switch (scenario) {
    case 'question':
      return lesson == 'pilares.ab4.slav4' && excerpt.id == 'ideia.ex1';
    case 'practice-opposite':
      final position = GameRules.fromFen(line.fens[line.initialCursor])!;
      return example.practice != null &&
          position.turn != (excerpt.black ? Side.black : Side.white);
    case 'practice-alternative':
      return example.practice?.line.any((turn) => turn.right.length > 1) ??
          false;
    case 'question-alternative':
      return example.question?.alternatives.isNotEmpty ?? false;
    case 'snapshot':
      return line.studentMoves > 1 &&
          List.generate(
            line.san.length,
            (index) => line.moveAt(index),
          ).contains(null);
    default:
      return false;
  }
}
