import 'dart:async';

import 'package:dartchess/dartchess.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';
import 'package:lucena/domain/use_cases/star_challenge_rules.dart';
import 'package:lucena/ui/school/view_models/star_challenge_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_star_challenge_repository.dart';

class DelayedRuns extends FakeStarChallengeRepository {
  final gate = Completer<void>();
  int writes = 0;
  @override
  Future<void> addRun({
    required ChallengePiece piece,
    required ChallengeLevel level,
    required int points,
    required DateTime at,
  }) async {
    writes++;
    await gate.future;
    await super.addRun(piece: piece, level: level, points: points, at: at);
  }
}

class FlakyRuns extends FakeStarChallengeRepository {
  bool fail = true;
  int writes = 0;
  @override
  Future<void> addRun({
    required ChallengePiece piece,
    required ChallengeLevel level,
    required int points,
    required DateTime at,
  }) async {
    writes++;
    if (fail) throw StateError('disk unavailable');
    await super.addRun(piece: piece, level: level, points: points, at: at);
  }
}

NormalMove capture(StarChallengeState state) => NormalMove(
  from: StarChallengeRules.pieceSquare(LessonRules.starsBoard(state.fen!))!,
  to: state.star!,
);

void main() {
  test(
    'finished result waits for durable run; repeated ticks write once',
    () async {
      final now = FakeNow(DateTime(2026, 10, 26, 12));
      final repository = DelayedRuns();
      final cubit = StarChallengeCubit(
        progress: repository,
        now: now,
        tickEvery: const Duration(hours: 1),
      );
      addTearDown(cubit.close);
      await cubit.load(ChallengePiece.rook, ChallengeLevel.easy);
      cubit.start();
      cubit.play(capture(cubit.state));
      final points = cubit.state.points;
      final lastCapture = capture(cubit.state);
      now.advance(const Duration(minutes: 1));
      cubit.tick();
      cubit.tick();
      expect(repository.writes, 1);
      expect(cubit.state.phase, ChallengePhase.running);
      expect(cubit.state.saving, isTrue);
      expect(cubit.state.interactive, isFalse);
      cubit.play(lastCapture);
      cubit.pause();
      cubit.resume();
      cubit.start();
      await cubit.retry();
      await cubit.load(ChallengePiece.queen, ChallengeLevel.hard);
      expect(cubit.state.points, points);
      expect(cubit.state.piece, ChallengePiece.rook);
      repository.gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.phase, ChallengePhase.finished);
      expect(repository.runs, hasLength(1));
      expect(repository.runs.single.points, points);
      expect(repository.runs.single.at, now());
      cubit.tick();
      expect(repository.writes, 1);
    },
  );
  test('failed write is caught; retry keeps immutable score and original date across midnight', () async {
    final now = FakeNow(DateTime(2026, 10, 26, 23, 58, 59));
    final repository = FlakyRuns();
    final cubit = StarChallengeCubit(
      progress: repository,
      now: now,
      tickEvery: const Duration(hours: 1),
    );
    addTearDown(cubit.close);
    await cubit.load(ChallengePiece.rook, ChallengeLevel.easy);
    cubit.start();
    cubit.play(capture(cubit.state));
    final points = cubit.state.points;
    final move = capture(cubit.state);
    now.advance(const Duration(minutes: 1));
    final finishedAt = now();
    cubit.tick();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.saveError, isTrue);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.phase, ChallengePhase.running);
    expect(repository.runs, isEmpty);
    cubit.play(move);
    cubit.tick();
    cubit.start();
    cubit.pause();
    cubit.resume();
    await cubit.retry();
    expect(repository.writes, 1);
    expect(cubit.state.points, points);
    now.advance(const Duration(seconds: 2));
    repository.fail = false;
    await Future.wait([cubit.retryFinish(), cubit.retryFinish()]);
    expect(repository.writes, 2);
    expect(repository.runs, hasLength(1));
    expect(repository.runs.single.at, finishedAt);
    expect(repository.runs.single.points, points);
    expect(cubit.state.phase, ChallengePhase.finished);
    expect(cubit.state.saveError, isFalse);
    expect(
      cubit.state.earned,
      StarChallengeRules.earned(ChallengeLevel.easy, points),
    );
    await cubit.retryFinish();
    cubit.tick();
    expect(repository.writes, 2);
    expect(
      StarChallengeRun.fromJson(repository.runs.single.toJson()).at
          .isAtSameMomentAs(finishedAt),
      isTrue,
    );
    expect(repository.runs.single.toJson()['at'], endsWith('Z'));
  });
}
