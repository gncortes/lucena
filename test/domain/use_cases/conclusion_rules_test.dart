import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/conclusion_rules.dart';

void main() {
  group('variante', () {
    test('partida avulsa, Jornada e às cegas', () {
      expect(ConclusionRules.kindOf(blind: false), ConclusionKind.game);
      expect(
        ConclusionRules.kindOf(blind: false, challengeId: '1000/x'),
        ConclusionKind.journey,
      );
      expect(ConclusionRules.kindOf(blind: true), ConclusionKind.blind);
    });

    test('speedrun: etapa vencida, perdida e o fim', () {
      expect(
        ConclusionRules.kindOf(blind: false, speedrun: true),
        ConclusionKind.speedrunStage,
      );
      expect(
        ConclusionRules.kindOf(blind: false, speedrun: true, lost: true),
        ConclusionKind.speedrunLost,
      );
      expect(
        ConclusionRules.kindOf(blind: false, speedrun: true, finished: true),
        ConclusionKind.speedrunEnd,
      );
    });

    test('Maratona: perdida e concluída', () {
      expect(
        ConclusionRules.kindOf(
          blind: false,
          speedrun: true,
          marathon: true,
          lost: true,
        ),
        ConclusionKind.marathonLost,
      );
      expect(
        ConclusionRules.kindOf(
          blind: false,
          speedrun: true,
          marathon: true,
          finished: true,
        ),
        ConclusionKind.marathonEnd,
      );
    });
  });

  test('resultado do ponto de vista do jogador', () {
    expect(ConclusionRules.resultOf(AttemptOutcome.win), ConclusionResult.won);
    expect(
      ConclusionRules.resultOf(AttemptOutcome.loss),
      ConclusionResult.lost,
    );
    expect(
      ConclusionRules.resultOf(AttemptOutcome.draw),
      ConclusionResult.draw,
    );
  });

  group('ações', () {
    test('avulsa gravada e com rating: jogar de novo, nova, analisar e os '
        'históricos', () {
      expect(
        ConclusionRules.actionsFor(
          ConclusionKind.game,
          recorded: true,
          rated: true,
        ),
        [
          ConclusionAction.playAgain,
          ConclusionAction.newGame,
          ConclusionAction.analyze,
          // Um atalho só para o histórico (rating e partidas na mesma tela).
          ConclusionAction.ratingHistory,
        ],
      );
    });

    test('avulsa sem gravar: só jogar de novo e nova', () {
      expect(ConclusionRules.actionsFor(ConclusionKind.game, recorded: false), [
        ConclusionAction.playAgain,
        ConclusionAction.newGame,
      ]);
    });

    test('Jornada com próximo desafio: ele primeiro', () {
      final actions = ConclusionRules.actionsFor(
        ConclusionKind.journey,
        recorded: true,
        hasNext: true,
      );
      expect(actions.take(2), [
        ConclusionAction.nextChallenge,
        ConclusionAction.playAgain,
      ]);
    });

    test('Jornada no fim do degrau: sem próximo desafio', () {
      expect(
        ConclusionRules.actionsFor(ConclusionKind.journey, recorded: true),
        isNot(contains(ConclusionAction.nextChallenge)),
      );
    });

    test('speedrun: continuar na etapa vencida; tentar de novo e o resumo na '
        'perdida; tentar de novo e a lista no fim', () {
      expect(
        ConclusionRules.actionsFor(
          ConclusionKind.speedrunStage,
          recorded: true,
        ).first,
        ConclusionAction.nextStage,
      );
      expect(
        ConclusionRules.actionsFor(
          ConclusionKind.speedrunLost,
          recorded: true,
        ).take(2),
        [ConclusionAction.retry, ConclusionAction.summary],
      );
      expect(
        ConclusionRules.actionsFor(
          ConclusionKind.speedrunEnd,
          recorded: true,
        ).where((action) => !action.name.contains('History')),
        [ConclusionAction.speedruns, ConclusionAction.analyze],
      );
      expect(
        ConclusionRules.actionsFor(
          ConclusionKind.marathonEnd,
          recorded: true,
        ).take(2),
        [ConclusionAction.retry, ConclusionAction.speedruns],
      );
      // Sem rating, o atalho do histórico vai pelas partidas.
      expect(
        ConclusionRules.actionsFor(ConclusionKind.speedrunEnd, recorded: true),
        contains(ConclusionAction.gamesHistory),
      );
    });
  });

  test('novo recorde: concluído e mais rápido que o de antes', () {
    ConclusionRun run({Duration? total, Duration? previous}) => ConclusionRun(
      speedrunId: 's',
      attemptId: 1,
      stage: 2,
      stageCount: 3,
      stages: const [],
      total: total,
      previousBest: previous,
    );
    expect(run(total: const Duration(seconds: 50)).newRecord, isTrue);
    expect(
      run(
        total: const Duration(seconds: 50),
        previous: const Duration(seconds: 60),
      ).newRecord,
      isTrue,
    );
    expect(
      run(
        total: const Duration(seconds: 70),
        previous: const Duration(seconds: 60),
      ).newRecord,
      isFalse,
    );
    expect(run().newRecord, isFalse);
  });

  test('lances do jogador às cegas, pela vez no começo', () {
    expect(ConclusionRules.userMoves(plies: 5, userSide: Side.white), 3);
    expect(ConclusionRules.userMoves(plies: 5, userSide: Side.black), 2);
    expect(
      ConclusionRules.userMoves(
        plies: 4,
        userSide: Side.black,
        startFen: '8/8/8/8/8/8/8/k6K b - - 0 1',
      ),
      2,
    );
  });

  group('partida curta (a análise rápida começa sozinha)', () {
    final end = DateTime.utc(2026, 10, 9, 12);
    Attempt game(int plies, {Duration? played, Duration? clock}) => Attempt(
      positionId: 'p',
      playedAt: end,
      startedAt: played == null ? null : end.subtract(played),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      moves: List.filled(plies, 'e2e4'),
      userClock: clock,
    );

    test('poucos lances: curta, qualquer que seja o tempo', () {
      expect(
        ConclusionRules.isShortGame(game(12, played: Duration(minutes: 9))),
        isTrue,
      );
    });

    test('sem lances: nada a analisar', () {
      expect(ConclusionRules.isShortGame(game(0)), isFalse);
    });

    test('mais lances: curta só abaixo de 30 s de jogo', () {
      expect(
        ConclusionRules.isShortGame(game(20, played: Duration(seconds: 25))),
        isTrue,
      );
      expect(
        ConclusionRules.isShortGame(game(20, played: Duration(seconds: 40))),
        isFalse,
      );
      // Sem a hora do começo, vale o relógio do jogador.
      expect(
        ConclusionRules.isShortGame(game(20, clock: Duration(seconds: 20))),
        isTrue,
      );
      expect(ConclusionRules.isShortGame(game(20)), isFalse);
      // Rápida, mas com lances demais para analisar num instante.
      expect(
        ConclusionRules.isShortGame(game(40, played: Duration(seconds: 25))),
        isFalse,
      );
    });
  });
}
