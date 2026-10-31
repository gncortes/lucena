import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/training/school_training_observations.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/domain/use_cases/training/reconcile_school_training.dart';
import 'package:lucena/domain/use_cases/training/double_training_goals.dart';

import '../../../../testing/fakes/fake_now.dart';

void main() {
  const config = TrainingCourseConfig.escola;
  late FakeNow now;
  late TrainingResources resources;
  TrainingState initial({int minutes = 30, int weekdays = 127}) =>
      TrainingState(
        course: TrainingCourse.escola,
        installSeed: 'school',
        plan: TrainingPlan(minutes: minutes, weekdays: weekdays),
      );
  TrainingState complete(TrainingState state, String id) =>
      CompleteTrainingLesson(now, config)(
        state,
        resources,
        resources.lessons.firstWhere((l) => l.id == id),
      );
  TrainingState run(
    TrainingState state,
    ChallengeLevel level,
    int points, {
    DateTime? at,
  }) => ReconcileSchoolTraining(now)(
    state,
    resources,
    SchoolTrainingObservations(
      starRuns: [
        StarChallengeRun(
          piece: ChallengePiece.rook,
          level: level,
          points: points,
          at: at ?? now(),
        ),
      ],
    ),
  );
  setUp(() {
    now = FakeNow(DateTime(2026, 10, 26, 12));
    resources = TrainingResources(
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
        for (var i = 0; i < 29; i++)
          TrainingLesson(
            id: 'other.$i',
            kind: TrainingLessonKind.school,
            title: 'Other $i',
          ),
      ],
    );
  });
  test('plan quotas, real school configuration and no mock goals', () {
    for (final (minutes, quota) in [(15, 2), (30, 4), (60, 8), (120, 12)]) {
      final state = BuildDayGoals(now, config)(
        initial(minutes: minutes),
        resources,
      );
      expect(state.day!.goals.length, quota);
      expect(state.mock, isFalse);
    }
    expect(config.lessonMinutes, 6);
    expect(config.hasHelp, isFalse);
    expect(config.sections, [
      GoalSection.lessons,
      GoalSection.bots,
      GoalSection.stars,
    ]);
  });
  test(
    'same day unlock; partial, named, stale and future runs do not qualify',
    () {
      final state = complete(initial(), 'pieces.rook');
      expect(
        state.day!.goals.any(
          (g) => g.kind == GoalKind.stars && g.itemId == 'easy',
        ),
        isTrue,
      );
      for (final candidate in [
        run(state, ChallengeLevel.easy, 14),
        run(state, ChallengeLevel.named, 99),
        run(
          state,
          ChallengeLevel.easy,
          15,
          at: now().subtract(const Duration(days: 1)),
        ),
        run(
          state,
          ChallengeLevel.easy,
          15,
          at: now().add(const Duration(hours: 1)),
        ),
      ]) {
        expect(candidate.school.pieceLevels, isEmpty);
      }
      expect(run(state, ChallengeLevel.easy, 15).school.pieceLevels['rook'], 1);
    },
  );
  test(
    'missed day repeats; one level per day; hard completed leaves queue',
    () {
      var state = complete(initial(), 'pieces.rook');
      now.advance(const Duration(days: 1));
      state = BuildDayGoals(now, config)(state, resources);
      expect(state.day!.goals.last.itemId, 'easy');
      for (final (level, points) in [
        (ChallengeLevel.easy, 15),
        (ChallengeLevel.medium, 24),
        (ChallengeLevel.hard, 27),
      ]) {
        state = run(state, level, points);
        expect(state.school.pieceLevels['rook'], level.stars);
        expect(
          config.followUps
              .build(state, resources, now)
              .where((g) => g.ref == 'pieces.rook'),
          isEmpty,
        );
        state = run(state, ChallengeLevel.hard, 99);
        expect(state.school.pieceLevels['rook'], level.stars);
        now.advance(const Duration(days: 1));
        state = BuildDayGoals(now, config)(state, resources);
      }
      expect(state.day!.goals.where((g) => g.ref == 'pieces.rook'), isEmpty);
    },
  );
  test('off day delays followup and gives completed lesson credit', () {
    var state = complete(initial(weekdays: 4), 'pieces.rook');
    expect(state.day!.goals, isEmpty);
    expect(state.offDayCredits, ['pieces.rook']);
    now.advance(const Duration(days: 1));
    state = BuildDayGoals(now, config)(state, resources);
    expect(state.day!.goals.first.done, isTrue);
    expect(state.day!.goals.last.kind, GoalKind.stars);
  });
  test('bots and full firstMates module unlock same day and leave after dated wins', () {
    var state = complete(initial(), 'mates.twoRooks');
    expect(state.day!.goals.where((g) => g.kind == GoalKind.bot), hasLength(1));
    expect(state.day!.goals.where((g) => g.kind == GoalKind.speedrun), isEmpty);
    state = complete(state, 'mates.queen');
    expect(state.day!.goals.where((g) => g.kind == GoalKind.bot), hasLength(2));
    expect(
      state.day!.goals.where((g) => g.kind == GoalKind.speedrun),
      hasLength(1),
    );
    state = ReconcileSchoolTraining(now)(
      state,
      resources,
      SchoolTrainingObservations(
        botWins: [
          for (final id in ['basic.twoRooks.0001', 'basic.queen.0001'])
            SchoolBotWin(positionId: id, rung: '1000', at: now()),
        ],
        speedruns: [SchoolSpeedrunFinish(id: 'journey.mates', at: now())],
      ),
    );
    expect(state.school.botsCompletedOn.length, 2);
    expect(state.school.speedrunCompletedOn, '2026-10-26');
    expect(config.followUps.build(state, resources, now), isEmpty);
  });
  test('invisible lessons never unlock or complete', () {
    resources = TrainingResources(
      lessons: [
        const TrainingLesson(
          id: 'pieces.rook',
          kind: TrainingLessonKind.school,
          title: 'Rook',
          visible: false,
        ),
      ],
    );
    final state = complete(initial(), 'pieces.rook');
    expect(state.completedLessons, isEmpty);
    expect(state.day, isNull);
  });
  test('local and UTC timestamps for the same instant qualify all three sources equally', () {
    now = FakeNow(DateTime(2026, 10, 26, 22));
    var state = complete(initial(), 'pieces.rook');
    state = complete(state, 'mates.twoRooks');
    state = complete(state, 'mates.queen');
    for (final timestamp in [now(), now().toUtc()]) {
      final reconciled = ReconcileSchoolTraining(now)(
        state,
        resources,
        SchoolTrainingObservations(
          starRuns: [
            StarChallengeRun(
              piece: ChallengePiece.rook,
              level: ChallengeLevel.easy,
              points: 15,
              at: timestamp,
            ),
          ],
          botWins: [
            for (final id in ['basic.twoRooks.0001', 'basic.queen.0001'])
              SchoolBotWin(positionId: id, rung: '1000', at: timestamp),
          ],
          speedruns: [SchoolSpeedrunFinish(id: 'journey.mates', at: timestamp)],
        ),
      );
      expect(reconciled.school.pieceLevels['rook'], 1);
      expect(reconciled.school.botsCompletedOn, {
        'mates.twoRooks': '2026-10-26',
        'mates.queen': '2026-10-26',
      });
      expect(reconciled.school.speedrunCompletedOn, '2026-10-26');
      expect(
        reconciled.day!.goals
            .where(
              (g) =>
                  g.kind == GoalKind.stars ||
                  g.kind == GoalKind.bot ||
                  g.kind == GoalKind.speedrun,
            )
            .every((g) => g.done),
        isTrue,
      );
    }
  });
  test(
    'immutable JSON roundtrip and legacy defaults preserve operational history',
    () {
      final state = run(
        complete(initial(), 'pieces.rook'),
        ChallengeLevel.easy,
        15,
      );
      final json =
          jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>;
      expect(TrainingState.fromJson(json).school.pieceLevels['rook'], 1);
      expect(
        () => state.school.pieceLevels['rook'] = 3,
        throwsUnsupportedError,
      );
      json.remove('school');
      expect(TrainingState.fromJson(json).school.pieceLevels, isEmpty);
    },
  );
  test('double adds frozen quota, preserves section order and never advances a piece twice', () {
    var state = BuildDayGoals(now, config)(initial(minutes: 15), resources);
    for (final goal in state.day!.goals.toList()) {
      state = complete(state, goal.ref);
    }
    state = ReconcileSchoolTraining(now)(
      state,
      resources,
      SchoolTrainingObservations(
        starRuns: [
          for (final piece in [ChallengePiece.rook, ChallengePiece.bishop])
            StarChallengeRun(
              piece: piece,
              level: ChallengeLevel.easy,
              points: 15,
              at: now(),
            ),
        ],
      ),
    );
    state = complete(state, 'other.0');
    expect(state.day!.allDone, isTrue);
    state = state.copyWith(
      plan: state.plan.copyWith(minutes: 120, weekdays: 0),
    );
    state = DoubleTrainingGoals(now, config)(state, resources);
    expect(state.day!.doubled, isTrue);
    final newLessons = state.day!.goals
        .where((g) => g.kind == GoalKind.lesson && !g.done)
        .toList();
    expect(newLessons, hasLength(2));
    expect(
      state.day!.goals.where((g) => g.kind == GoalKind.stars),
      hasLength(2),
    );
    for (final goal in newLessons) {
      state = complete(state, goal.ref);
    }
    expect(
      state.day!.goals.where((g) => g.kind == GoalKind.stars),
      hasLength(4),
    );
    expect(
      state.day!.goals.where((g) => g.ref == 'pieces.rook'),
      hasLength(2),
    ); // lesson + original easy
    expect(state.school.pieceLevels['rook'], 1);
    final firstStar = state.day!.goals.indexWhere(
      (g) => g.kind == GoalKind.stars,
    );
    expect(
      state.day!.goals.skip(firstStar).every((g) => g.kind == GoalKind.stars),
      isTrue,
    );
  });
}
