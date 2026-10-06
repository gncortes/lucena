import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/review_rules.dart';

void main() {
  group('chance de vitória (Lichess)', () {
    test('zero é 50 %, e o mate e o teto valem o mesmo', () {
      expect(const EngineScore(centipawns: 0).whiteWinPercent, 50);
      expect(
        const EngineScore(mate: 3).whiteWinPercent,
        const EngineScore(centipawns: 1000).whiteWinPercent,
      );
      expect(
        const EngineScore(centipawns: 5000).whiteWinPercent,
        const EngineScore(centipawns: 1000).whiteWinPercent,
      );
      expect(const EngineScore(mate: -2).whiteWinPercent, lessThan(3));
    });

    test('+1 peão dá cerca de 59 % (valor do Lichess)', () {
      expect(
        const EngineScore(centipawns: 100).whiteWinPercent,
        closeTo(59.1, 0.1),
      );
    });

    test('posição em mate: quem levou fica com quase zero', () {
      expect(
        const EngineScore.mated(whiteMated: true).whiteWinPercent,
        lessThan(3),
      );
      expect(
        const EngineScore.mated(whiteMated: false).whiteWinPercent,
        greaterThan(97),
      );
    });
  });

  group('precisão do lance', () {
    test('sem perda vale 100; perder muito leva perto de zero', () {
      expect(ReviewRules.moveAccuracy(60, 60), 100);
      expect(ReviewRules.moveAccuracy(60, 70), 100);
      expect(ReviewRules.moveAccuracy(60, 55), closeTo(80.8, 0.1));
      expect(ReviewRules.moveAccuracy(90, 10), lessThan(2));
    });
  });

  group('classificação', () {
    MoveQuality of(double before, double after) =>
        ReviewRules.classify(before: before, after: after);

    test('os limites do Lichess: 5, 10 e 15 pontos', () {
      expect(of(60, 59), MoveQuality.excellent);
      expect(of(60, 57), MoveQuality.good);
      expect(of(60, 55), MoveQuality.inaccuracy);
      expect(of(60, 50), MoveQuality.mistake);
      expect(of(60, 45), MoveQuality.blunder);
    });

    test('lance perdido: ganhava e deixou escapar sem ficar perdido', () {
      expect(of(95, 60), MoveQuality.miss);
      expect(of(95, 50), MoveQuality.blunder);
      // Deixou empatar ou ficou perdido: é erro grave.
      expect(of(95, 20), MoveQuality.blunder);
    });

    test('o lance da engine é o melhor; ótimo se o segundo perde muito', () {
      expect(
        ReviewRules.classify(before: 60, after: 60, isBest: true),
        MoveQuality.best,
      );
      expect(
        ReviewRules.classify(
          before: 60,
          after: 60,
          isBest: true,
          secondBest: 45,
        ),
        MoveQuality.great,
      );
    });

    test('único lance legal é lance forçado', () {
      expect(
        ReviewRules.classify(before: 60, after: 10, forced: true),
        MoveQuality.forced,
      );
    });
  });

  group('revisão de uma partida', () {
    // Dama e rei contra rei: as brancas dão mate em 1 com Qg7#.
    final start = GameRules.fromFen('7k/8/5K2/8/8/8/8/6Q1 w - - 0 1')!;
    EngineLine line(String uci, {int? cp, int? mate}) => EngineLine(
      score: EngineScore(centipawns: cp, mate: mate),
      moves: [uci],
    );

    test(
      'o mate da engine é o melhor; o lance que deixa afogar é erro grave',
      () {
        final review = ReviewRules.review(
          start: start,
          moves: [Move.parse('g1g7')!],
          analyses: [
            [line('g1g7', mate: 1)],
            null,
          ],
        );
        expect(review.moves.single.quality, MoveQuality.best);
        expect(review.moves.single.best, 'g1g7');
        expect(review.whiteAccuracy, greaterThan(99));
        expect(review.blackAccuracy, isNull);

        final stalemate = ReviewRules.review(
          start: start,
          moves: [Move.parse('g1g6')!],
          analyses: [
            [line('g1g7', mate: 1)],
            null,
          ],
        );
        expect(stalemate.moves.single.quality, MoveQuality.blunder);
        expect(stalemate.moves.single.best, 'g1g7');
        expect(stalemate.whiteAccuracy, lessThan(15));
      },
    );

    test('guarda e lê de volta (JSON)', () {
      final review = ReviewRules.review(
        start: start,
        moves: [Move.parse('g1g7')!],
        analyses: [
          [line('g1g7', mate: 1)],
          null,
        ],
        depth: 14,
      );
      final again = GameReview.fromJson(review.toJson())!;
      expect(again.depth, 14);
      expect(again.moves.single.quality, MoveQuality.best);
      expect(again.moves.single.after, review.moves.single.after);
      expect(again.whiteAccuracy, review.whiteAccuracy);
      expect(GameReview.fromJson({'version': 0}), isNull);
    });

    test('a contagem separa os lados', () {
      final review = GameReview(
        moves: [
          for (final quality in [
            MoveQuality.best,
            MoveQuality.blunder,
            MoveQuality.mistake,
          ])
            ReviewedMove(
              before: const EngineScore(centipawns: 0),
              after: const EngineScore(centipawns: 0),
              quality: quality,
              accuracy: 50,
            ),
        ],
      );
      final white = review.counts(white: true, firstIsWhite: true);
      final black = review.counts(white: false, firstIsWhite: true);
      expect(white[MoveQuality.best], 1);
      expect(white[MoveQuality.mistake], 1);
      expect(black[MoveQuality.blunder], 1);
    });
  });

  group('distância do mate (finais ganhos)', () {
    test('quem dá o mate: cada lance a mais custa, até o erro', () {
      expect(ReviewRules.mateLoss(before: 5, after: 4), 0);
      expect(ReviewRules.mateLoss(before: 5, after: 6), 4);
      expect(ReviewRules.mateLoss(before: 5, after: 9), 10);
      expect(ReviewRules.mateLoss(before: 5, after: 30), lessThan(15));
      // Mate dado: nenhuma perda.
      expect(ReviewRules.mateLoss(before: 1, after: 0), 0);
      // Perdeu o mate forçado.
      expect(ReviewRules.mateLoss(before: 5), ReviewRules.mateLostLoss);
    });

    test('quem leva o mate: apressar custa, segurar não', () {
      expect(ReviewRules.mateLoss(before: -6, after: -6), 0);
      expect(ReviewRules.mateLoss(before: -6, after: -3), 6);
    });

    test('numa partida de dama contra rei, o lance que atrasa o mate é '
        'imprecisão e baixa a precisão', () {
      final start = GameRules.fromFen('7k/8/5K2/8/8/8/8/6Q1 w - - 0 1')!;
      final review = ReviewRules.review(
        start: start,
        moves: [Move.parse('g1g2')!],
        analyses: [
          [
            const EngineLine(score: EngineScore(mate: 1), moves: ['g1g7']),
          ],
          [
            const EngineLine(score: EngineScore(mate: 4), moves: ['h8h7']),
          ],
        ],
      );
      expect(review.moves.single.quality, MoveQuality.inaccuracy);
      expect(review.whiteAccuracy, lessThan(90));
    });
  });
}
