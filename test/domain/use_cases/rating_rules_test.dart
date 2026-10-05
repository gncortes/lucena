import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/use_cases/rating_rules.dart';

void main() {
  test('reproduz o exemplo do artigo do Glickman', () {
    final next = RatingRules.updateMany(
      const PlayerRating(rating: 1500, deviation: 200, volatility: 0.06),
      [
        (rating: 1400, deviation: 30, score: 1),
        (rating: 1550, deviation: 100, score: 0),
        (rating: 1700, deviation: 300, score: 0),
      ],
    );
    expect(next.rating, closeTo(1464.06, 0.01));
    expect(next.deviation, closeTo(151.52, 0.01));
    expect(next.volatility, closeTo(0.05999, 0.00001));
  });

  test('o começo tem a incerteza máxima', () {
    final start = PlayerRating.start(1500);
    expect(start.rating, 1500);
    expect(start.deviation, PlayerRating.initialDeviation);
    expect(start.volatility, PlayerRating.initialVolatility);
    expect(start.rounded, 1500);
  });

  group('adversário equivalente', () {
    test('placar de meio ponto é o mesmo rating', () {
      expect(
        RatingRules.equivalentOpponent(rating: 1500, expected: 0.5),
        closeTo(1500, 1e-9),
      );
    });

    test('placar de 0,76 é uns 200 pontos abaixo', () {
      expect(
        RatingRules.equivalentOpponent(rating: 1500, expected: 0.76),
        closeTo(1300, 1),
      );
      expect(
        RatingRules.equivalentOpponent(rating: 1500, expected: 0.24),
        closeTo(1700, 1),
      );
    });

    test('o placar fica entre 0,02 e 0,98', () {
      expect(
        RatingRules.equivalentOpponent(rating: 1500, expected: 1),
        RatingRules.equivalentOpponent(rating: 1500, expected: 0.98),
      );
      expect(
        RatingRules.equivalentOpponent(rating: 1500, expected: 0),
        RatingRules.equivalentOpponent(rating: 1500, expected: 0.02),
      );
    });
  });

  test('o placar previsto depende do objetivo', () {
    expect(
      RatingRules.expectedScore(win: 0.6, draw: 0.3, drawGoal: false),
      closeTo(0.75, 1e-9),
    );
    expect(
      RatingRules.expectedScore(win: 0.1, draw: 0.6, drawGoal: true),
      closeTo(0.7, 1e-9),
    );
    expect(RatingRules.score(fulfilled: true), 1);
    expect(RatingRules.score(fulfilled: false), 0);
    // Empatar quando o objetivo era vencer vale meio ponto.
    expect(RatingRules.score(fulfilled: false, draw: true), 0.5);
    // Se o objetivo era o empate, ele já cumpre: ponto inteiro.
    expect(RatingRules.score(fulfilled: true, draw: true), 1);
  });

  group('rate', () {
    const player = PlayerRating(rating: 1500, deviation: 100);

    test('vencer sobe, perder desce', () {
      final win = RatingRules.rate(player, expected: 0.7, fulfilled: true);
      final loss = RatingRules.rate(player, expected: 0.7, fulfilled: false);
      expect(win.rating, greaterThan(1500));
      expect(loss.rating, lessThan(1500));
      expect(win.deviation, lessThan(100));
    });

    test('empate: sobe contra o mais forte, desce contra o mais fraco', () {
      // Posição difícil: o adversário equivalente é mais forte.
      final hard = RatingRules.rate(
        player,
        expected: 0.3,
        fulfilled: false,
        draw: true,
      );
      // Posição ganha: o adversário equivalente é mais fraco.
      final easy = RatingRules.rate(
        player,
        expected: 0.9,
        fulfilled: false,
        draw: true,
      );
      final loss = RatingRules.rate(player, expected: 0.9, fulfilled: false);
      expect(hard.rating, greaterThan(1500));
      expect(easy.rating, lessThan(1500));
      // Mas o empate custa menos que a derrota.
      expect(easy.rating, greaterThan(loss.rating));
    });

    test('cumprir algo difícil vale mais que cumprir algo fácil', () {
      final hard = RatingRules.rate(player, expected: 0.2, fulfilled: true);
      final easy = RatingRules.rate(player, expected: 0.9, fulfilled: true);
      expect(hard.rating - 1500, greaterThan(easy.rating - 1500));
    });

    test('contra o Stockfish, o adversário é mais forte', () {
      final maia = RatingRules.rate(player, expected: 0.5, fulfilled: true);
      final stockfish = RatingRules.rate(
        player,
        expected: 0.5,
        fulfilled: true,
        stockfish: true,
      );
      expect(stockfish.rating, greaterThan(maia.rating));
    });

    test('com mais incerteza, o rating anda mais', () {
      final unsure = RatingRules.rate(
        const PlayerRating(rating: 1500, deviation: 300),
        expected: 0.5,
        fulfilled: true,
      );
      final sure = RatingRules.rate(
        const PlayerRating(rating: 1500, deviation: 50),
        expected: 0.5,
        fulfilled: true,
      );
      expect(unsure.rating - 1500, greaterThan(sure.rating - 1500));
    });
  });

  group('limites', () {
    test('o rating fica entre 100 e 3500', () {
      final top = RatingRules.update(
        const PlayerRating(rating: 3490, deviation: 350),
        opponentRating: 3500,
        score: 1,
      );
      expect(top.rating, 3500);
      final bottom = RatingRules.update(
        const PlayerRating(rating: 110, deviation: 350),
        opponentRating: 100,
        score: 0,
      );
      expect(bottom.rating, 100);
    });

    test('o desvio nunca passa de 350', () {
      final idle = RatingRules.updateMany(
        const PlayerRating(rating: 1500, deviation: 349.9),
        const [],
      );
      expect(idle.deviation, 350);
      final played = RatingRules.update(
        PlayerRating.start(1500),
        opponentRating: 1500,
        score: 0.5,
      );
      expect(played.deviation, lessThanOrEqualTo(350));
    });
  });
}
