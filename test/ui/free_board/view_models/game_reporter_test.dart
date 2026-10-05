import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_feedback.dart';
import 'package:lucena/ui/free_board/view_models/game_reporter.dart';

import '../../../../testing/fakes/fake_achievements_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_speedrun_repository.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeAchievementsRepository achievements;
  late FakeRatingRepository rating;
  late GameReporter reporter;
  final now = FakeNow(DateTime.utc(2026, 10, 4, 12));

  setUp(() {
    progress = FakeProgressRepository();
    achievements = FakeAchievementsRepository();
    rating = FakeRatingRepository();
    reporter = GameReporter(
      rating: rating,
      achievements: achievements,
      journey: FakeJourneyRepository(),
      progress: progress,
      speedruns: FakeSpeedrunRepository(progress),
      positions: FakePositionsRepository(),
      now: now,
    );
  });

  Future<GameReport> play({
    required bool fulfilled,
    int level = 2600,
    String? challengeId,
  }) async {
    final game = Attempt(
      positionId: samplePositions[0].id,
      playedAt: now(),
      outcome: fulfilled ? AttemptOutcome.win : AttemptOutcome.loss,
      fulfilled: fulfilled,
      opponent: OpponentKind.maia,
      opponentLevel: level,
      startFen: samplePositions[0].fen,
      challengeId: challengeId,
    );
    final id = await progress.addAttempt(game);
    return reporter.report(
      game,
      gameId: id,
      userSide: Side.white,
      drawGoal: false,
    );
  }

  test('a vitória muda o rating e traz as mensagens e conquistas', () async {
    final report = await play(fulfilled: true);

    expect(report.after!.rounded, greaterThan(report.before!.rounded));
    expect(
      report.feedback,
      contains(
        const GameFeedback(FeedbackKind.firstWinAgainstLevel, level: 2600),
      ),
    );
    expect(report.achievements.map((a) => a.id), [
      'first-fulfilled',
      'beat-2600',
    ]);
    expect(achievements.unlockedAt.keys, {'first-fulfilled', 'beat-2600'});
  });

  test('conquista já obtida não aparece de novo como nova', () async {
    await play(fulfilled: true);
    final second = await play(fulfilled: true);

    expect(second.achievements, isEmpty);
    expect(
      second.feedback.where((f) => f.kind == FeedbackKind.achievement),
      isEmpty,
    );
  });

  test('derrota: o rating desce e não há mensagem', () async {
    final report = await play(fulfilled: false);

    expect(report.after!.rounded, lessThan(report.before!.rounded));
    expect(report.feedback, isEmpty);
  });

  test('o desafio que completa o degrau avisa', () async {
    final rung = sampleLadder.first;
    await play(
      fulfilled: true,
      level: 1000,
      challengeId: rung.challenges[0].id,
    );
    final report = await play(
      fulfilled: true,
      level: 1000,
      challengeId: rung.challenges[1].id,
    );

    expect(
      report.feedback,
      contains(const GameFeedback(FeedbackKind.rungCompleted, rungId: '1000')),
    );
  });

  test('no desafio da Jornada, aponta o próximo', () async {
    final rung = sampleLadder.first;
    final report = await play(
      fulfilled: true,
      level: 1000,
      challengeId: rung.challenges[0].id,
    );

    expect(report.next!.challenge.id, rung.challenges[1].id);
  });

  test('fora da Jornada, sem próximo desafio', () async {
    final report = await play(fulfilled: true);

    expect(report.next, isNull);
  });

  test('speedrun em outro ritmo também traz o recorde', () async {
    final speedruns = FakeSpeedrunRepository(progress);
    reporter = GameReporter(
      rating: rating,
      achievements: achievements,
      journey: FakeJourneyRepository(),
      progress: progress,
      speedruns: speedruns,
      positions: FakePositionsRepository(),
      now: now,
    );
    final attempt = await speedruns.start('rung.1000@180+2', now());
    Attempt stage(int index) => Attempt(
      positionId: samplePositions[0].id,
      playedAt: now(),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      opponentLevel: 1000,
      startFen: samplePositions[0].fen,
      userClock: const Duration(seconds: 40),
      speedrunAttemptId: attempt.id,
      speedrunStage: index,
    );
    await progress.addAttempt(stage(0));
    final last = stage(1);
    final id = await progress.addAttempt(last);

    final report = await reporter.report(
      last,
      gameId: id,
      userSide: Side.white,
      drawGoal: false,
    );

    expect(
      report.feedback.map((f) => f.kind),
      contains(FeedbackKind.newSpeedrunRecord),
    );
  });

  group('o passo seguinte do speedrun', () {
    late FakeSpeedrunRepository speedruns;

    setUp(() {
      speedruns = FakeSpeedrunRepository(progress);
      reporter = GameReporter(
        rating: rating,
        achievements: achievements,
        journey: FakeJourneyRepository(),
        progress: progress,
        speedruns: speedruns,
        positions: FakePositionsRepository(),
        now: now,
      );
    });

    Future<GameReport> stage(int attempt, int index, {bool won = true}) async {
      final game = Attempt(
        positionId: samplePositions[0].id,
        playedAt: now(),
        outcome: won ? AttemptOutcome.win : AttemptOutcome.loss,
        fulfilled: won,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        startFen: samplePositions[0].fen,
        userClock: const Duration(seconds: 40),
        speedrunAttemptId: attempt,
        speedrunStage: index,
      );
      final id = await progress.addAttempt(game);
      return reporter.report(
        game,
        gameId: id,
        userSide: Side.white,
        drawGoal: false,
      );
    }

    test('venceu uma etapa: a próxima', () async {
      final attempt = await speedruns.start('rung.1000', now());

      final step = (await stage(attempt.id, 0)).speedrun!;

      expect(step.speedrunId, 'rung.1000');
      expect(step.attemptId, attempt.id);
      expect(step.stage, 1);
      expect(step.challenge, isNotNull);
      expect(step.lost, isFalse);
      expect(step.finished, isFalse);
    });

    test('venceu a última: o fim da tentativa', () async {
      final attempt = await speedruns.start('rung.1000', now());
      await stage(attempt.id, 0);

      final step = (await stage(attempt.id, 1)).speedrun!;

      expect(step.finished, isTrue);
      expect(step.stage, isNull);
      expect((await speedruns.attempt(attempt.id))!.abandonedAt, isNull);
    });

    test('perdeu: a tentativa termina ali e "tentar novamente" volta à '
        'primeira etapa', () async {
      final attempt = await speedruns.start('rung.1000', now());
      await stage(attempt.id, 0);

      final step = (await stage(attempt.id, 1, won: false)).speedrun!;

      expect(step.lost, isTrue);
      expect(step.stage, 0);
      expect(step.challenge, isNotNull);
      expect((await speedruns.attempt(attempt.id))!.abandonedAt, now());
    });

    test('fora do speedrun, sem passo seguinte', () async {
      final report = await play(fulfilled: true);

      expect(report.speedrun, isNull);
    });
  });
}
