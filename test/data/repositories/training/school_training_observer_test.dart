import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/observed_training_repository.dart';
import 'package:lucena/data/repositories/training/school_training_observer.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';

import 'school_training_observation_source_test.dart' show SchoolSourceFixture;

void main() {
  late SchoolSourceFixture f;
  setUp(() => f = SchoolSourceFixture());
  test(
    'all source kinds commit together; replay writes and emits nothing extra',
    () async {
      final state = f.allUnlocked;
      final storage = f.scenario.repository(state);
      addTearDown(storage.dispose);
      final observer = SchoolTrainingObserver(
        now: f.scenario.now,
        source: f.source,
      );
      final repository = ObservedTrainingRepository(
        storage,
        observers: {TrainingCourse.escola: observer.call},
      );
      final changes = <TrainingState>[];
      final subscription = repository.changes.listen((after) {
        changes.add(after);
      });
      addTearDown(subscription.cancel);
      final now = f.scenario.now();
      for (final piece in ChallengePiece.values) {
        await f.scenario.schoolStars.addRun(
          piece: piece,
          level: ChallengeLevel.easy,
          points: 19,
          at: now.toUtc(),
        );
        await f.scenario.schoolStars.addRun(
          piece: piece,
          level: ChallengeLevel.easy,
          points: 99,
          at: now.add(const Duration(hours: 1)),
        );
        await f.scenario.schoolStars.addRun(
          piece: piece,
          level: ChallengeLevel.easy,
          points: 30,
          at: now.subtract(const Duration(minutes: 1)),
        );
      }
      for (final id in ['basic.twoRooks.0001', 'basic.queen.0001']) {
        await f.scenario.schoolProgress.addAttempt(
          f.game(position: id, challenge: '1000/$id', at: now.toUtc()),
        );
      }
      await f.playRun(at: now.toUtc());
      final gate = Completer<void>();
      storage.beforeSave = gate.future;
      final pending = repository.load(TrainingCourse.escola);
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 0);
      expect(changes, isEmpty);
      gate.complete();
      final saved = await pending;
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 1);
      expect(changes, hasLength(1));
      expect(saved.day!.allDone, isTrue);
      expect(saved.school.pieceLevels.length, 6);
      expect(saved.school.botsCompletedOn.length, 2);
      expect(saved.school.speedrunCompletedOn, '2026-10-26');
      await repository.load(TrainingCourse.escola);
      await repository.transact(TrainingCourse.escola, (s) => s);
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 1);
      expect(changes, hasLength(1));
    },
  );
  test('stale/future, loss, wrong rung, visits and in-progress sources do not complete goals', () async {
    final state = f.allUnlocked;
    for (final at in [
      f.scenario.now().subtract(const Duration(days: 1)),
      f.scenario.now().add(const Duration(hours: 1)),
    ]) {
      await f.scenario.schoolStars.addRun(
        piece: ChallengePiece.rook,
        level: ChallengeLevel.easy,
        points: 15,
        at: at,
      );
      await f.scenario.schoolProgress.addAttempt(f.game(at: at));
      await f.playRun(at: at);
    }
    await f.scenario.schoolProgress.addAttempt(f.game(fulfilled: false));
    await f.scenario.schoolProgress.addAttempt(
      f.game(challenge: '1200/basic.queen.0001'),
    );
    await f.playRun(stages: 0, abandon: true);
    await f.playRun(stages: 1);
    final observer = SchoolTrainingObserver(
      now: f.scenario.now,
      source: f.source,
    );
    final result = await observer(state, f.scenario.content);
    expect(identical(result, state), isTrue);
    expect(result.school.pieceLevels, isEmpty);
    expect(result.school.botsCompletedOn, isEmpty);
    expect(result.school.speedrunCompletedOn, isNull);
  });
  test('command unlock consumes earlier same-day run inside its single transaction', () async {
    final state = f.scenario.schoolDayOne();
    final storage = f.scenario.repository(state);
    addTearDown(storage.dispose);
    final observer = SchoolTrainingObserver(
      now: f.scenario.now,
      source: f.source,
    );
    final repository = ObservedTrainingRepository(
      storage,
      observers: {TrainingCourse.escola: observer.call},
    );
    await f.scenario.schoolStars.addRun(
      piece: ChallengePiece.rook,
      level: ChallengeLevel.easy,
      points: 15,
      at: f.scenario.now().subtract(const Duration(minutes: 1)),
    );
    final saved = await repository.update(
      TrainingCourse.escola,
      (s) => CompleteTrainingLesson(f.scenario.now, f.scenario.config)(
        s,
        f.scenario.content,
        f.scenario.content.lessons.first,
      ),
    );
    expect(storage.writes, 1);
    expect(saved.school.pieceLevels['rook'], 1);
    expect(
      saved.day!.goals.where((g) => g.kind == GoalKind.stars).single.done,
      isTrue,
    );
  });
}
