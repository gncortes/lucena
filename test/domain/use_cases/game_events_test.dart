import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/use_cases/game_events.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';

void main() {
  TalkMemory history(List<int> scores) => TalkMemory(scores: scores);

  List<LineCategory> categories(
    List<int> scores,
    int now, {
    bool byCharacter = false,
    String? captured,
    bool promotion = false,
  }) => [
    for (final e in GameEvents.afterMove(
      memory: history(scores),
      move: MoveFacts(
        byCharacter: byCharacter,
        captured: captured,
        promotion: promotion,
      ),
      evaluation: Evaluation(centipawns: now),
    ))
      e.category,
  ];

  group('Evaluation e PositionAssessment', () {
    test('mate vira um número grande com sinal', () {
      expect(const Evaluation(mate: 3).score, 9970);
      expect(const Evaluation(mate: -2).score, -9980);
      expect(const Evaluation(centipawns: 9000).score, 5000);
      expect(const Evaluation(centipawns: -9000).score, -5000);
    });

    test('faixas do estado', () {
      expect(PositionAssessment.stateOf(500), PositionState.bigAdvantage);
      expect(PositionAssessment.stateOf(150), PositionState.better);
      expect(PositionAssessment.stateOf(0), PositionState.equal);
      expect(PositionAssessment.stateOf(-150), PositionState.worse);
      expect(PositionAssessment.stateOf(-500), PositionState.bigDisadvantage);
    });
  });

  group('afterMove', () {
    test('erro do jogador vira opponentBlunder', () {
      final events = GameEvents.afterMove(
        memory: history([0]),
        move: const MoveFacts(byCharacter: false),
        evaluation: const Evaluation(centipawns: 300),
      );
      expect(events.first, const GameEvent(LineCategory.opponentBlunder, 2));
      expect(categories([0], 600).first, LineCategory.opponentBlunder);
      expect(
        GameEvents.afterMove(
          memory: history([0]),
          move: const MoveFacts(byCharacter: false),
          evaluation: const Evaluation(centipawns: 600),
        ).first.intensity,
        3,
      );
    });

    test('queda depois do lance do jogador é lance forte dele', () {
      final events = GameEvents.afterMove(
        memory: history([300]),
        move: const MoveFacts(byCharacter: false),
        evaluation: const Evaluation(centipawns: 100),
      );
      expect(events.first.category, LineCategory.strongMove);
      expect(events.first.intensity, 1);
    });

    test('erro do personagem vira ownBlunder', () {
      expect(
        categories([100], -200, byCharacter: true).first,
        LineCategory.ownBlunder,
      );
    });

    test('virada dá comeback e não better nem bigAdvantage', () {
      final got = categories([-300, -200, 50], 450);
      expect(got.first, LineCategory.comeback);
      expect(got, isNot(contains(LineCategory.better)));
      expect(got, isNot(contains(LineCategory.bigAdvantage)));
    });

    test('vantagem que desmorona dá collapse', () {
      final got = categories([500, 450, 200], 0, byCharacter: true);
      expect(got.first, LineCategory.collapse);
      expect(got, isNot(contains(LineCategory.equal)));
    });

    test('mudança de estado sem virada', () {
      expect(categories([50], 150), [LineCategory.better]);
      expect(categories([150], 160), isEmpty);
    });

    test('sem avaliação anterior, nada de avaliação', () {
      expect(categories([], 600), isEmpty);
    });

    test('capturas e promoções dos dois lados', () {
      final queen = GameEvents.afterMove(
        memory: TalkMemory.empty,
        move: const MoveFacts(byCharacter: true, captured: 'queen'),
        evaluation: null,
      );
      expect(queen, [const GameEvent(LineCategory.pieceCaptured, 3)]);
      expect(categories([], 0, captured: 'rook'), [LineCategory.pieceLost]);
      expect(categories([], 0, captured: 'pawn'), isEmpty);
      expect(categories([], 0, byCharacter: true, promotion: true), [
        LineCategory.ownPromotion,
      ]);
      expect(categories([], 0, promotion: true), [
        LineCategory.opponentPromotion,
      ]);
    });
  });

  group('clock', () {
    List<LineCategory> clock({
      TalkMemory memory = TalkMemory.empty,
      required int character,
      required int player,
      bool playerToMove = false,
      int thinking = 0,
    }) => [
      for (final e in GameEvents.clock(
        memory: memory,
        characterTime: Duration(seconds: character),
        playerTime: Duration(seconds: player),
        playerToMove: playerToMove,
        playerThinking: Duration(seconds: thinking),
      ))
        e.category,
    ];

    test('pouco tempo e vantagem de relógio', () {
      expect(clock(character: 100, player: 15), [
        LineCategory.opponentLowTime,
        LineCategory.timeAdvantage,
      ]);
      expect(clock(character: 10, player: 100), [LineCategory.ownLowTime]);
      expect(clock(character: 300, player: 200), isEmpty);
    });

    test('eventos de uma vez só não voltam', () {
      final said = TalkMemory.empty.copyWith(
        onceFlags: {'opponentLowTime', 'timeAdvantage'},
      );
      expect(clock(memory: said, character: 100, player: 15), isEmpty);
    });

    test('jogador pensando', () {
      final long = GameEvents.clock(
        memory: TalkMemory.empty,
        characterTime: const Duration(minutes: 5),
        playerTime: const Duration(minutes: 5),
        playerToMove: true,
        playerThinking: const Duration(seconds: 70),
      );
      expect(long, [const GameEvent(LineCategory.opponentThinking, 2)]);
      expect(
        clock(character: 300, player: 300, playerToMove: true, thinking: 10),
        isEmpty,
      );
    });
  });

  group('TalkMemory', () {
    test('ida e volta pelo JSON', () {
      const memory = TalkMemory(
        scores: [10, -20, 300],
        spoken: ['a.1', 'a.2'],
        movesSinceLine: 3,
        onceFlags: {'ownLowTime'},
        lastLineId: 'a.2',
        emotion: Emotion.nervous,
      );
      expect(TalkMemory.fromJson(memory.toJson()), memory);
      expect(TalkMemory.fromJson(TalkMemory.empty.toJson()), TalkMemory.empty);
    });

    test('JSON incompleto não quebra', () {
      expect(TalkMemory.fromJson({}), TalkMemory.empty);
      expect(
        TalkMemory.fromJson({'scores': 'x', 'emotion': 'nova'}),
        TalkMemory.empty,
      );
    });

    test('remember guarda só as 12 últimas', () {
      var memory = TalkMemory.empty;
      for (var i = 0; i < 15; i++) {
        memory = GameEvents.remember(memory, i);
      }
      expect(memory.scores, [for (var i = 3; i < 15; i++) i]);
      expect(GameEvents.remember(memory, null), memory);
    });
  });

  group('mate adiado', () {
    // O jogador tem mate em 3 (do lado do personagem, levar mate).
    const mateIn3 = Evaluation(mate: -3);

    List<GameEvent> after(Evaluation now, {bool byCharacter = false}) =>
        GameEvents.afterMove(
          memory: history([mateIn3.score]),
          move: MoveFacts(byCharacter: byCharacter),
          evaluation: now,
        );

    test('o jogador encurtou o mate: nada a dizer', () {
      expect(
        after(const Evaluation(mate: -2)).map((e) => e.category),
        isNot(contains(LineCategory.mateDelayed)),
      );
    });

    test('o mate não encurtou: o personagem debocha da demora', () {
      expect(
        after(const Evaluation(mate: -4)).first,
        const GameEvent(LineCategory.mateDelayed, 2),
      );
      expect(
        after(mateIn3).first,
        const GameEvent(LineCategory.mateDelayed, 2),
      );
    });

    test('o mate escapou: o personagem diz que agora é empate', () {
      expect(
        after(const Evaluation(centipawns: -300)).first,
        const GameEvent(LineCategory.mateDelayed, 3),
      );
    });

    test('lance do personagem não conta como mate adiado', () {
      expect(
        after(
          const Evaluation(mate: -5),
          byCharacter: true,
        ).map((e) => e.category),
        isNot(contains(LineCategory.mateDelayed)),
      );
    });

    test('teve mate na mão: guardado nas avaliações', () {
      expect(
        GameEvents.playerHadMate(history([0, mateIn3.score, -300])),
        isTrue,
      );
      expect(GameEvents.playerHadMate(history([0, -4000])), isFalse);
    });
  });
}
