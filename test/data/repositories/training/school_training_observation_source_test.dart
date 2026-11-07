import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/school_training_observation_source.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/domain/use_cases/training/reconcile_school_training.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';

import '../../../../testing/fakes/fake_ongoing_game_repository.dart';

import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/training/training_scenario_builder.dart';

/// The shared large scenario owns the existing stars/progress/speedrun fakes.
final class SchoolSourceFixture {
  SchoolSourceFixture() {
    scenario = TrainingScenarioBuilder(
      TrainingCourse.escola,
      date: DateTime(2026, 10, 26, 22),
      resources: TrainingResources(
        lessons: [
          for (final piece in ChallengePiece.values)
            TrainingLesson(
              id: 'pieces.${piece.name}',
              kind: TrainingLessonKind.school,
              title: piece.name,
              groupId: 'pieces',
            ),
          for (final id in ['mates.twoRooks', 'mates.queen'])
            TrainingLesson(
              id: id,
              kind: TrainingLessonKind.school,
              title: id,
              groupId: 'firstMates',
            ),
        ],
      ),
    );
    definition = sampleSpeedruns.first.copyWith(
      id: 'journey.mates',
      journeyOnly: true,
      time: const TimeControl(
        initial: Duration(seconds: 900),
        increment: Duration(seconds: 10),
      ),
      stages: [
        for (final id in ['basic.twoRooks.0001', 'basic.queen.0001'])
          Challenge(
            id: 'journey.mates/$id',
            position: sampleLadder.first.challenges.first.position.copyWith(
              id: id,
            ),
            opponent: sampleLadder.first.opponent,
          ),
      ],
    );
    journey = FakeJourneyRepository(speedruns: [definition]);
    source = SchoolTrainingObservationSource(
      now: scenario.now,
      stars: scenario.schoolStars,
      progress: scenario.schoolProgress,
      speedruns: scenario.schoolSpeedruns,
      journey: journey,
    );
  }
  late final TrainingScenarioBuilder scenario;
  late final Speedrun definition;
  late final FakeJourneyRepository journey;
  late final SchoolTrainingObservationSource source;
  TrainingState get mates => scenario.schoolMates();
  TrainingState get allUnlocked {
    var state = mates;
    for (final lesson in scenario.content.lessons.where(
      (l) => l.groupId == 'pieces',
    )) {
      state = CompleteTrainingLesson(scenario.now, scenario.config)(
        state,
        scenario.content,
        lesson,
      );
    }
    return state;
  }

  Attempt game({
    String position = 'basic.queen.0001',
    String? challenge = '1000/basic.queen.0001',
    bool fulfilled = true,
    DateTime? at,
    int? speedrunId,
    int? stage,
  }) => Attempt(
    positionId: position,
    challengeId: challenge,
    playedAt: at ?? scenario.now(),
    fulfilled: fulfilled,
    outcome: fulfilled ? AttemptOutcome.win : AttemptOutcome.loss,
    opponent: OpponentKind.maia,
    opponentLevel: 1000,
    speedrunAttemptId: speedrunId,
    speedrunStage: stage,
  );
  Future<SpeedrunAttempt> playRun({
    DateTime? at,
    int stages = 2,
    bool abandon = false,
    bool fulfilled = true,
  }) async {
    final attempt = await scenario.schoolSpeedruns.start(
      'journey.mates',
      (at ?? scenario.now()).subtract(const Duration(minutes: 5)),
    );
    for (var i = 0; i < stages; i++) {
      await scenario.schoolProgress.addAttempt(
        game(
          position: definition.stages[i].position.id,
          challenge: null,
          speedrunId: attempt.id,
          stage: i,
          fulfilled: fulfilled,
          at: at,
        ),
      );
    }
    if (abandon) {
      await scenario.schoolSpeedruns.abandon(attempt.id, at ?? scenario.now());
    }
    return attempt;
  }
}

void main() {
  late SchoolSourceFixture f;
  setUp(() => f = SchoolSourceFixture());
  test('fixed 15+10 run started by Cubit is visible to the School source and qualifies its goal', () async {
    final cubit = SpeedrunCubit(
      journey: f.journey,
      speedruns: f.scenario.schoolSpeedruns,
      games: FakeOngoingGameRepository(),
      now: f.scenario.now,
    );
    addTearDown(cubit.close);
    await cubit.load(speedrunId: f.definition.id);
    final (definition, id) = (await cubit.startWith(f.definition.time))!;
    expect(definition.id, 'journey.mates');
    expect(definition.time.code, '900+10');
    for (var stage = 0; stage < definition.stages.length; stage++) {
      await f.scenario.schoolProgress.addAttempt(
        f.game(
          position: definition.stages[stage].position.id,
          challenge: null,
          speedrunId: id,
          stage: stage,
        ),
      );
    }
    final state = f.mates;
    final observations = await f.source.read(state);
    expect(observations.speedruns, hasLength(1));
    expect(observations.speedruns.single.id, 'journey.mates');
    final result = ReconcileSchoolTraining(f.scenario.now)(
      state,
      f.scenario.content,
      observations,
    );
    expect(
      result.day!.goals.where((g) => g.kind == GoalKind.speedrun).single.done,
      isTrue,
    );
  });
  test(
    'only fulfilled attempts for exact rung and position are bot observations',
    () async {
      final progress = f.scenario.schoolProgress;
      await progress.addAttempt(f.game());
      await progress.addAttempt(f.game(fulfilled: false));
      await progress.addAttempt(f.game(challenge: '1200/basic.queen.0001'));
      await progress.addAttempt(f.game(position: 'basic.rook.0001'));
      await progress.addAttempt(f.game(challenge: null));
      final result = await f.source.read(f.mates);
      expect(result.botWins, hasLength(1));
      expect(result.botWins.single.positionId, 'basic.queen.0001');
      expect(result.botWins.single.rung, '1000');
    },
  );
  test('dated source keeps bot dates for pure qualification; stars start at local midnight', () async {
    final at = f.scenario.now();
    for (final date in [
      at.subtract(const Duration(days: 1)),
      at.toUtc(),
      at.add(const Duration(hours: 1)),
    ]) {
      await f.scenario.schoolProgress.addAttempt(f.game(at: date));
      await f.scenario.schoolStars.addRun(
        piece: ChallengePiece.rook,
        level: ChallengeLevel.easy,
        points: 15,
        at: date,
      );
    }
    final result = await f.source.read(f.mates);
    expect(result.botWins, hasLength(3));
    expect(result.starRuns, hasLength(2));
    expect(
      result.starRuns.every((r) => !r.at.isBefore(DateTime(2026, 10, 26))),
      isTrue,
    );
    expect(
      result.starRuns.any((r) => r.at.isAfter(at)),
      isTrue,
    ); // rejected by reconcile, not fabricated here
  });
  test('empty, in-progress and abandoned-empty speedruns are visits, not finished play', () async {
    await f.playRun(stages: 0);
    await f.playRun(stages: 1);
    await f.playRun(stages: 0, abandon: true);
    await f.playRun(stages: 1, fulfilled: false);
    expect((await f.source.read(f.mates)).speedruns, isEmpty);
  });
  test(
    'completed and played-abandoned speedruns carry their finish timestamps',
    () async {
      final yesterday = f.scenario.now().subtract(const Duration(days: 1));
      final future = f.scenario.now().add(const Duration(hours: 1));
      await f.playRun(at: yesterday);
      await f.playRun(at: f.scenario.now().toUtc());
      await f.playRun(at: future, stages: 1, abandon: true, fulfilled: false);
      final result = await f.source.read(f.mates);
      expect(result.speedruns, hasLength(3));
      expect(
        result.speedruns.map((r) => r.at),
        containsAll([yesterday, f.scenario.now().toUtc(), future]),
      );
      expect(result.speedruns.every((r) => r.id == 'journey.mates'), isTrue);
    },
  );
  test(
    'done goals and missing speedrun definitions do not create observations',
    () async {
      await f.scenario.schoolProgress.addAttempt(f.game());
      await f.playRun();
      final state = f.mates;
      final done = state.copyWith(
        day: state.day!.copyWith(
          goals: [for (final g in state.day!.goals) g.complete()],
        ),
      );
      final result = await f.source.read(done);
      expect(result.botWins, isEmpty);
      expect(result.speedruns, isEmpty);
      final noDefinition = SchoolTrainingObservationSource(
        now: f.scenario.now,
        stars: f.scenario.schoolStars,
        progress: f.scenario.schoolProgress,
        speedruns: f.scenario.schoolSpeedruns,
        journey: FakeJourneyRepository(speedruns: []),
      );
      expect((await noDefinition.read(state)).speedruns, isEmpty);
    },
  );
}
