import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/marathon.dart';
import 'package:lucena/domain/use_cases/speedrun_score.dart';

import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  const pace = sampleSpeedrunTime; // 3+2
  final start = DateTime.utc(2026, 10, 7, 12);

  // Uma partida da etapa [stage]: o relógio do jogador correu [spent] e ele
  // fez [userMoves] lances (cada um com o acréscimo de 2 s).
  Attempt game(
    int stage, {
    required Duration spent,
    int userMoves = 0,
    bool won = true,
    Duration? bank,
  }) => Attempt(
    positionId: 'basic.queen.0001',
    playedAt: start,
    outcome: won ? AttemptOutcome.win : AttemptOutcome.loss,
    fulfilled: won,
    opponent: OpponentKind.maia,
    startFen: '8/8/8/4k3/8/8/8/4K2Q w - - 0 1',
    // O jogador começa: depois do último lance dele, o adversário ainda
    // responde (menos no mate).
    moves: List.filled(userMoves * 2 - (won ? 1 : 0), 'e1e2'),
    userSide: Side.white,
    userTime: Marathon.stageTime(pace, bank ?? pace.initial),
    userClock: spent,
    speedrunAttemptId: 1,
    speedrunStage: stage,
  );

  SpeedrunRun run(List<Attempt> games) => SpeedrunScore.run(
    sampleMarathon,
    SpeedrunAttempt(
      id: 1,
      speedrunId: sampleMarathon.id,
      startedAt: start,
      games: games,
    ),
  );

  test('a Maratona de um final: as mesmas etapas, com outro id', () {
    final ending = sampleSpeedruns[1];
    expect(sampleMarathon.id, 'marathon.queen');
    expect(sampleMarathon.kind, SpeedrunKind.marathon);
    expect(
      sampleMarathon.stages.map((s) => (s.position.id, s.opponent)),
      ending.stages.map((s) => (s.position.id, s.opponent)),
    );
    expect(sampleMarathon.stages.first.id, startsWith('marathon.queen/'));
    expect(Marathon.isMarathon('marathon.queen@30+0'), isTrue);
    expect(Marathon.isMarathon('ending.queen'), isFalse);
  });

  test('o acréscimo de cada lance volta para o banco', () {
    // 40 s no relógio, 5 lances com 2 s cada: o banco perdeu 30 s.
    expect(
      Marathon.consumed(
        game(0, spent: const Duration(seconds: 40), userMoves: 5),
      ),
      const Duration(seconds: 30),
    );
    // Com as pretas: o adversário começa.
    final black = Attempt(
      positionId: 'p',
      playedAt: start,
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      startFen: '8/8/8/4k3/8/8/8/4K2Q w - - 0 1',
      moves: const ['a', 'b', 'c', 'd'],
      userSide: Side.black,
      userTime: Marathon.stageTime(pace, pace.initial),
      userClock: const Duration(seconds: 10),
    );
    expect(Marathon.consumed(black), const Duration(seconds: 6));
  });

  test('cada etapa começa com o que sobrou; a partida perdida também tira '
      'do banco', () {
    final after = run([
      game(0, spent: const Duration(seconds: 25), userMoves: 5), // -15 s
      game(
        1,
        spent: const Duration(seconds: 20),
        userMoves: 5,
        won: false,
      ), // -10 s
    ]);
    // A etapa perdida continua a da vez, na mesma tentativa.
    expect(after.currentStage, 1);
    expect(after.stages[1].losses, 1);
    expect(after.inProgress, isTrue);
    final bank = Marathon.bank(after, pace);
    expect(bank, const Duration(minutes: 3) - const Duration(seconds: 25));
    // A etapa seguinte: o banco com o acréscimo do ritmo.
    expect(
      Marathon.stageTime(pace, bank),
      TimeControl(initial: bank, increment: const Duration(seconds: 2)),
    );
  });

  test('o banco não fica negativo', () {
    final over = run([game(0, spent: const Duration(minutes: 4), won: false)]);
    expect(Marathon.bank(over, pace), Duration.zero);
  });

  test('o recorde é o maior banco no fim: o menor total gasto', () {
    final stages = sampleMarathon.stages.length;
    SpeedrunAttempt attempt(int id, Duration perStage) => SpeedrunAttempt(
      id: id,
      speedrunId: sampleMarathon.id,
      startedAt: start,
      games: [
        for (var stage = 0; stage < stages; stage++)
          game(stage, spent: perStage, userMoves: 3).copyWith(
            speedrunAttemptId: id,
            playedAt: start.add(Duration(minutes: id * 10 + stage)),
          ),
      ],
    );
    final records = SpeedrunScore.records(sampleMarathon, [
      attempt(1, const Duration(seconds: 20)),
      attempt(2, const Duration(seconds: 12)),
    ]);
    // 12 s por etapa, 6 s de volta em acréscimos: 6 s do banco por etapa.
    expect(records.best, const Duration(seconds: 6) * stages);
    expect(
      Marathon.left(pace, records.best!),
      const Duration(minutes: 3) - const Duration(seconds: 6) * stages,
    );
  });

  group('MarathonEnd', () {
    Attempt ended(
      int stage, {
      required AttemptOutcome outcome,
      GameEndReason? reason,
      Duration spent = const Duration(seconds: 10),
    }) => game(stage, spent: spent, userMoves: 3).copyWith(
      outcome: outcome,
      fulfilled: outcome == AttemptOutcome.win,
      endReason: reason,
    );

    SpeedrunRun runOf(List<Attempt> games, {bool abandoned = false}) =>
        SpeedrunScore.run(
          sampleMarathon,
          SpeedrunAttempt(
            id: 1,
            speedrunId: sampleMarathon.id,
            startedAt: start,
            abandonedAt: abandoned ? start : null,
            games: games,
          ),
        );

    SpeedrunRunEnd end(SpeedrunRun run) => MarathonEnd.of(sampleMarathon, run);

    test('concluída vence qualquer outro motivo', () {
      final games = [
        for (var i = 0; i < sampleMarathon.stages.length; i++)
          ended(i, outcome: AttemptOutcome.win),
      ];

      expect(end(runOf(games)), SpeedrunRunEnd.completed);
    });

    test('derrota e empate na última partida', () {
      expect(
        end(
          runOf([
            ended(0, outcome: AttemptOutcome.win),
            ended(
              1,
              outcome: AttemptOutcome.loss,
              reason: GameEndReason.checkmate,
            ),
          ], abandoned: true),
        ),
        SpeedrunRunEnd.lost,
      );
      expect(
        end(
          runOf([
            ended(
              0,
              outcome: AttemptOutcome.draw,
              reason: GameEndReason.stalemate,
            ),
          ], abandoned: true),
        ),
        SpeedrunRunEnd.drawn,
      );
    });

    test('o tempo acabando na partida é sem tempo, perdendo ou empatando', () {
      for (final (outcome, reason) in [
        (AttemptOutcome.loss, GameEndReason.timeout),
        (AttemptOutcome.draw, GameEndReason.timeoutVsInsufficientMaterial),
      ]) {
        expect(
          end(runOf([ended(0, outcome: outcome, reason: reason)])),
          SpeedrunRunEnd.timeout,
          reason: reason.name,
        );
      }
    });

    test('venceu e o banco zerou: abandonada pelo reporter é sem tempo', () {
      // Três lances de 2 s de acréscimo voltam ao banco: gastou 3:06.
      final games = [
        ended(
          0,
          outcome: AttemptOutcome.win,
          spent: pace.initial + const Duration(seconds: 6),
        ),
      ];

      expect(end(runOf(games, abandoned: true)), SpeedrunRunEnd.timeout);
    });

    test('desistiu: com banco sobrando, desistindo da partida ou sem '
        'partida', () {
      expect(
        end(runOf([ended(0, outcome: AttemptOutcome.win)], abandoned: true)),
        SpeedrunRunEnd.abandoned,
      );
      expect(
        end(
          runOf([
            ended(
              0,
              outcome: AttemptOutcome.loss,
              reason: GameEndReason.resign,
            ),
          ], abandoned: true),
        ),
        SpeedrunRunEnd.abandoned,
      );
      expect(end(runOf(const [], abandoned: true)), SpeedrunRunEnd.abandoned);
    });
  });
}
