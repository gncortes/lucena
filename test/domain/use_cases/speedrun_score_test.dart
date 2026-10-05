import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/clock_format.dart';
import 'package:lucena/domain/use_cases/speedrun_score.dart';

import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  // O speedrun do degrau 1000: duas etapas.
  final speedrun = sampleSpeedruns.first;
  final day = DateTime.utc(2026, 10, 4, 12);

  Attempt game(
    int attempt,
    int stage, {
    required int seconds,
    bool won = true,
    int minutesLater = 0,
  }) => Attempt(
    positionId: speedrun.stages[stage].position.id,
    playedAt: day.add(Duration(minutes: minutesLater)),
    outcome: won ? AttemptOutcome.win : AttemptOutcome.loss,
    fulfilled: won,
    opponent: OpponentKind.maia,
    userClock: Duration(seconds: seconds),
    speedrunAttemptId: attempt,
    speedrunStage: stage,
  );

  SpeedrunAttempt attempt(int id, List<Attempt> games, {DateTime? abandoned}) =>
      SpeedrunAttempt(
        id: id,
        speedrunId: speedrun.id,
        startedAt: day,
        abandonedAt: abandoned,
        games: games,
      );

  test('tentativa nova: na primeira etapa, sem tempo', () {
    final run = SpeedrunScore.run(speedrun, attempt(1, []));

    expect(run.currentStage, 0);
    expect(run.total, Duration.zero);
    expect(run.inProgress, isTrue);
  });

  test('derrota repete a etapa e o tempo dela conta no total', () {
    final run = SpeedrunScore.run(
      speedrun,
      attempt(1, [
        game(1, 0, seconds: 20, won: false),
        game(1, 0, seconds: 15),
      ]),
    );

    expect(run.stages[0].losses, 1);
    expect(run.stages[0].wins, 1);
    expect(run.stages[0].time, const Duration(seconds: 35));
    expect(run.currentStage, 1);
    expect(run.losses, 1);
    expect(run.inProgress, isTrue);
  });

  test('todas as etapas cumpridas: concluída, com o total somado', () {
    final run = SpeedrunScore.run(
      speedrun,
      attempt(1, [game(1, 0, seconds: 30), game(1, 1, seconds: 40)]),
    );

    expect(run.completed, isTrue);
    expect(run.currentStage, 2);
    expect(run.total, const Duration(seconds: 70));
    expect(run.finishedAt, day);
  });

  test('abandonada não é concluída nem conta para recorde', () {
    final abandoned = attempt(1, [game(1, 0, seconds: 5)], abandoned: day);
    final run = SpeedrunScore.run(speedrun, abandoned);

    expect(run.abandoned, isTrue);
    expect(run.inProgress, isFalse);
    expect(SpeedrunScore.records(speedrun, [abandoned]).best, isNull);
  });

  test('recordes: melhor total e melhor etapa de qualquer tentativa', () {
    final first = attempt(1, [
      game(1, 0, seconds: 30),
      game(1, 1, seconds: 40),
    ]);
    final second = attempt(2, [
      game(2, 0, seconds: 50, minutesLater: 10),
      game(2, 1, seconds: 10, minutesLater: 11),
    ]);
    final records = SpeedrunScore.records(speedrun, [first, second]);

    expect(records.best, const Duration(seconds: 60));
    expect(records.bestStages, [
      const Duration(seconds: 30),
      const Duration(seconds: 10),
    ]);
    // A mais recente primeiro.
    expect(records.completed.map((run) => run.attempt.id), [2, 1]);
  });

  test('recorde de antes: só as tentativas que terminaram antes', () {
    final first = attempt(1, [
      game(1, 0, seconds: 30),
      game(1, 1, seconds: 40),
    ]);
    final second = attempt(2, [
      game(2, 0, seconds: 20, minutesLater: 10),
      game(2, 1, seconds: 20, minutesLater: 11),
    ]);
    final records = SpeedrunScore.records(speedrun, [first, second]);
    final runs = records.completed;

    expect(SpeedrunScore.previousBest(records, runs.last), isNull);
    expect(
      SpeedrunScore.previousBest(records, runs.first),
      const Duration(seconds: 70),
    );
  });

  group('como o tempo aparece', () {
    test('minutos, segundos e décimos', () {
      expect(
        RunTimeFormat.format(const Duration(seconds: 65, milliseconds: 340)),
        '1:05.3',
      );
      expect(
        RunTimeFormat.format(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03.0',
      );
      expect(RunTimeFormat.format(Duration.zero), '0:00.0');
    });

    test('diferença para o recorde, com sinal', () {
      expect(
        RunTimeFormat.difference(const Duration(seconds: 3, milliseconds: 250)),
        '+3.2',
      );
      expect(RunTimeFormat.difference(const Duration(seconds: -4)), '-4.0');
      expect(
        RunTimeFormat.difference(const Duration(minutes: -1, seconds: -4)),
        '-1:04.0',
      );
    });
  });
}
