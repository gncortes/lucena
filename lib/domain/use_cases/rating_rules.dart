import 'dart:math' as math;

import '../models/player_rating.dart';

/// O rating do jogador, no Glicko-2 (artigo do Glickman), com cada partida
/// como um período.
///
/// As partidas de treino começam de finais desequilibrados: vencer o Maia
/// 2600 numa posição ganha não é vencer um 2600. Por isso o adversário de
/// cada partida é um "adversário equivalente": o rating contra o qual o
/// jogador teria o placar que o próprio Maia prevê para aquela posição entre
/// o rating do jogador e o nível escolhido. Contra o Stockfish, vale o placar
/// previsto contra o Maia 2600, e o adversário equivalente ganha
/// [stockfishBonus].
abstract final class RatingRules {
  /// Desvio do adversário equivalente: o modelo é preciso, mas não exato.
  static const opponentDeviation = 60.0;

  /// O rating atribuído ao Stockfish.
  static const stockfishRating = 3000;

  /// O quanto o adversário equivalente sobe quando ele é o Stockfish.
  static const stockfishBonus = 400;

  /// Limites do rating.
  static const minRating = 100.0;
  static const maxRating = 3500.0;

  /// Restrição da volatilidade no tempo (τ).
  static const tau = 0.5;

  /// Conversão entre a escala do Glicko e a do Glicko-2.
  static const scale = 173.7178;

  /// Tolerância do cálculo da volatilidade.
  static const epsilon = 0.000001;

  /// Placar da partida para o rating: cumpriu o objetivo ou não.
  static double score({required bool fulfilled}) => fulfilled ? 1 : 0;

  /// O placar previsto pela cabeça de resultado do Maia, do ponto de vista
  /// do jogador. Se o objetivo é vencer, o empate vale meio ponto; se é só
  /// segurar o empate, o empate já cumpre o objetivo.
  static double expectedScore({
    required double win,
    required double draw,
    required bool drawGoal,
  }) => drawGoal ? win + draw : win + draw / 2;

  /// O rating do adversário contra o qual o placar esperado (Elo) de quem
  /// tem [rating] é [expected].
  static double equivalentOpponent({
    required double rating,
    required double expected,
  }) {
    final e = expected.clamp(0.02, 0.98);
    return rating + 400 * math.log(1 / e - 1) / math.ln10;
  }

  /// O novo rating depois de uma partida em que o placar previsto era
  /// [expected] (contra o Maia 2600, se for o [stockfish]).
  static PlayerRating rate(
    PlayerRating player, {
    required double expected,
    required bool fulfilled,
    bool stockfish = false,
  }) {
    var opponent = equivalentOpponent(
      rating: player.rating,
      expected: expected,
    );
    if (stockfish) opponent += stockfishBonus;
    return update(
      player,
      opponentRating: opponent,
      score: score(fulfilled: fulfilled),
    );
  }

  /// Um período do Glicko-2 com uma partida só.
  static PlayerRating update(
    PlayerRating player, {
    required double opponentRating,
    double opponentDeviation = RatingRules.opponentDeviation,
    required double score,
  }) => updateMany(player, [
    (rating: opponentRating, deviation: opponentDeviation, score: score),
  ]);

  /// Um período do Glicko-2 com [games] (passos do artigo do Glickman).
  static PlayerRating updateMany(
    PlayerRating player,
    List<({double rating, double deviation, double score})> games,
  ) {
    final mu = (player.rating - 1500) / scale;
    final phi = player.deviation / scale;
    final sigma = player.volatility;
    if (games.isEmpty) {
      final next = math.sqrt(phi * phi + sigma * sigma);
      return _finish(player.rating, next * scale, sigma);
    }

    var inverseV = 0.0;
    var sum = 0.0;
    for (final game in games) {
      final muJ = (game.rating - 1500) / scale;
      final g = _g(game.deviation / scale);
      final e = 1 / (1 + math.exp(-g * (mu - muJ)));
      inverseV += g * g * e * (1 - e);
      sum += g * (game.score - e);
    }
    final v = 1 / inverseV;
    final delta = v * sum;

    final newSigma = _volatility(phi: phi, sigma: sigma, v: v, delta: delta);
    final phiStar = math.sqrt(phi * phi + newSigma * newSigma);
    final newPhi = 1 / math.sqrt(1 / (phiStar * phiStar) + 1 / v);
    final newMu = mu + newPhi * newPhi * sum;
    return _finish(newMu * scale + 1500, newPhi * scale, newSigma);
  }

  static PlayerRating _finish(double rating, double deviation, double sigma) =>
      PlayerRating(
        rating: rating.clamp(minRating, maxRating),
        deviation: math.min(deviation, PlayerRating.initialDeviation),
        volatility: sigma,
      );

  static double _g(double phi) =>
      1 / math.sqrt(1 + 3 * phi * phi / (math.pi * math.pi));

  /// A nova volatilidade, pelo algoritmo de Illinois (passo 5 do artigo).
  static double _volatility({
    required double phi,
    required double sigma,
    required double v,
    required double delta,
  }) {
    final a = math.log(sigma * sigma);
    final phi2 = phi * phi;
    double f(double x) {
      final ex = math.exp(x);
      final d = phi2 + v + ex;
      return ex * (delta * delta - phi2 - v - ex) / (2 * d * d) -
          (x - a) / (tau * tau);
    }

    var lower = a;
    double upper;
    if (delta * delta > phi2 + v) {
      upper = math.log(delta * delta - phi2 - v);
    } else {
      var k = 1;
      while (f(a - k * tau) < 0) {
        k++;
      }
      upper = a - k * tau;
    }
    var fLower = f(lower);
    var fUpper = f(upper);
    while ((upper - lower).abs() > epsilon) {
      final c = lower + (lower - upper) * fLower / (fUpper - fLower);
      final fC = f(c);
      if (fC * fUpper <= 0) {
        lower = upper;
        fLower = fUpper;
      } else {
        fLower /= 2;
      }
      upper = c;
      fUpper = fC;
    }
    return math.exp(lower / 2);
  }
}
