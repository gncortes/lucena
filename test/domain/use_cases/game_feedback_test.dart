import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/game_feedback.dart';
import 'package:lucena/domain/use_cases/speedrun_score.dart';

import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  final day = DateTime.utc(2026, 10, 4, 12);
  final ladder = sampleLadder;
  final speedrun = sampleSpeedruns.first; // Duas etapas.

  Attempt game({
    bool fulfilled = true,
    OpponentKind opponent = OpponentKind.maia,
    int? level = 1000,
    String? challengeId,
  }) => Attempt(
    positionId: 'p',
    playedAt: day,
    outcome: fulfilled ? AttemptOutcome.win : AttemptOutcome.loss,
    fulfilled: fulfilled,
    opponent: opponent,
    opponentLevel: opponent == OpponentKind.maia ? level : null,
    challengeId: challengeId,
  );

  List<GameFeedback> after(Attempt played, List<Attempt> before) =>
      GameFeedbackRules.afterGame(game: played, before: before, ladder: ladder);

  test('primeira vitória contra o 2600 só uma vez', () {
    final first = game(level: 2600);
    expect(
      after(first, [game(level: 2400), game(level: 2600, fulfilled: false)]),
      [const GameFeedback(FeedbackKind.firstWinAgainstLevel, level: 2600)],
    );
    expect(after(game(level: 2600), [first]), isEmpty);
  });

  test('primeira vitória contra o Stockfish', () {
    final win = game(opponent: OpponentKind.stockfish);
    expect(after(win, []), [
      const GameFeedback(FeedbackKind.firstWinAgainstStockfish),
    ]);
    expect(after(win, [win]), isEmpty);
  });

  test('partida não cumprida não diz nada', () {
    expect(after(game(fulfilled: false, level: 2600), []), isEmpty);
  });

  test('degrau concluído só na partida que o conclui', () {
    final queen = game(challengeId: ladder[0].challenges[0].id);
    final rook = game(challengeId: ladder[0].challenges[1].id);

    expect(
      after(queen, []).where((f) => f.kind == FeedbackKind.rungCompleted),
      isEmpty,
    );
    expect(after(rook, [queen]), [
      const GameFeedback(FeedbackKind.rungCompleted, rungId: '1000'),
    ]);
    // Repetir um desafio de degrau já concluído não conclui de novo.
    expect(after(rook, [queen, rook]), isEmpty);
  });

  test('o último degrau conclui a Jornada', () {
    final before = [
      for (final rung in ladder.take(2))
        for (final challenge in rung.challenges)
          game(challengeId: challenge.id, level: rung.opponent.level),
      game(opponent: OpponentKind.stockfish),
    ];
    final last = game(
      opponent: OpponentKind.stockfish,
      challengeId: ladder.last.challenges.single.id,
    );
    expect(after(last, before), [
      const GameFeedback(FeedbackKind.rungCompleted, rungId: 'stockfish'),
      const GameFeedback(FeedbackKind.journeyCompleted),
    ]);
  });

  group('speedrun', () {
    SpeedrunRun run(int id, List<int> seconds) => SpeedrunScore.run(
      speedrun,
      SpeedrunAttempt(
        id: id,
        speedrunId: speedrun.id,
        startedAt: day,
        games: [
          for (final (stage, s) in seconds.indexed)
            Attempt(
              positionId: speedrun.stages[stage].position.id,
              playedAt: day.add(Duration(minutes: id * 10 + stage)),
              outcome: AttemptOutcome.win,
              fulfilled: true,
              opponent: OpponentKind.maia,
              userClock: Duration(seconds: s),
              speedrunAttemptId: id,
              speedrunStage: stage,
            ),
        ],
      ),
    );

    test('a primeira tentativa concluída é recorde, sem melhora', () {
      expect(
        GameFeedbackRules.afterSpeedrunStage(
          run: run(1, [60, 60]),
          previousCompleted: [],
          stage: 1,
        ),
        [
          const GameFeedback(
            FeedbackKind.newSpeedrunRecord,
            time: Duration(seconds: 120),
          ),
        ],
      );
    });

    test('recorde de etapa no meio da tentativa', () {
      expect(
        GameFeedbackRules.afterSpeedrunStage(
          run: run(2, [40]),
          previousCompleted: [
            run(1, [60, 60]),
          ],
          stage: 0,
        ),
        [
          const GameFeedback(
            FeedbackKind.stageRecord,
            time: Duration(seconds: 40),
          ),
        ],
      );
      expect(
        GameFeedbackRules.afterSpeedrunStage(
          run: run(2, [70]),
          previousCompleted: [
            run(1, [60, 60]),
          ],
          stage: 0,
        ),
        isEmpty,
      );
    });

    test('recorde melhorado diz quanto', () {
      expect(
        GameFeedbackRules.afterSpeedrunStage(
          run: run(3, [70, 30]),
          previousCompleted: [
            run(1, [60, 60]),
            run(2, [50, 80]),
          ],
          stage: 1,
        ),
        [
          const GameFeedback(
            FeedbackKind.stageRecord,
            time: Duration(seconds: 30),
          ),
          const GameFeedback(
            FeedbackKind.newSpeedrunRecord,
            time: Duration(seconds: 100),
          ),
          const GameFeedback(
            FeedbackKind.speedrunImproved,
            improvedBy: Duration(seconds: 20),
          ),
        ],
      );
    });

    test('sem bater o recorde, nada', () {
      expect(
        GameFeedbackRules.afterSpeedrunStage(
          run: run(2, [70, 70]),
          previousCompleted: [
            run(1, [60, 60]),
          ],
          stage: 1,
        ),
        isEmpty,
      );
    });
  });
}
