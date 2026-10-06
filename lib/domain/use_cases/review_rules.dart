import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import '../models/game_review.dart';

/// A revisão de uma partida a partir das linhas da engine em cada posição.
/// As contas da chance de vitória, da precisão e dos limites de imprecisão,
/// erro e erro grave são as do Lichess (`docs/tasks/T37.md`).
abstract final class ReviewRules {
  /// Perdas de chance de vitória (pontos de 0 a 100) de cada julgamento.
  static const inaccuracyLoss = 5.0;
  static const mistakeLoss = 10.0;
  static const blunderLoss = 15.0;
  static const excellentLoss = 2.0;

  /// O melhor lance é "ótimo" quando o segundo melhor perde isto ou mais.
  static const greatGap = 10.0;

  /// Lance perdido: quem jogou tinha isto ou mais e caiu abaixo de
  /// [missAfter], ainda melhor ([missFloor]): deixar empatar ou perder é erro.
  static const missBefore = 90.0;
  static const missAfter = 70.0;
  static const missFloor = 55.0;

  /// A chance de vitória de [side] com a avaliação [score].
  static double winPercent(EngineScore score, Side side) =>
      side == Side.white ? score.whiteWinPercent : 100 - score.whiteWinPercent;

  /// A precisão de um lance que levou a chance de vitória de quem jogou de
  /// [before] para [after] (Lichess, com o bônus de incerteza de 1 ponto).
  static double moveAccuracy(double before, double after) {
    if (after >= before) return 100;
    final raw =
        103.1668100711649 * math.exp(-0.04354415386753951 * (before - after)) -
        3.166924740191411 +
        1;
    return raw.clamp(0, 100).toDouble();
  }

  /// A qualidade do lance, pela chance de vitória de quem jogou antes
  /// ([before]) e depois ([after]).
  static MoveQuality classify({
    required double before,
    required double after,
    bool forced = false,
    bool isBest = false,
    double? secondBest,
  }) {
    if (forced) return MoveQuality.forced;
    final loss = math.max(0, before - after);
    if (isBest) {
      if (secondBest != null && before - secondBest >= greatGap) {
        return MoveQuality.great;
      }
      return MoveQuality.best;
    }
    if (before >= missBefore && after < missAfter && after >= missFloor) {
      return MoveQuality.miss;
    }
    if (loss >= blunderLoss) return MoveQuality.blunder;
    if (loss >= mistakeLoss) return MoveQuality.mistake;
    if (loss >= inaccuracyLoss) return MoveQuality.inaccuracy;
    if (loss < excellentLoss) return MoveQuality.excellent;
    return MoveQuality.good;
  }

  /// A avaliação de [position]: a da engine ([lines]) ou, se a partida
  /// acabou ali, a do fim (mate ou empate). Nula sem uma nem outra.
  static EngineScore? scoreOf(Position position, List<EngineLine>? lines) {
    if (position.isCheckmate) {
      return EngineScore.mated(whiteMated: position.turn == Side.white);
    }
    if (position.isStalemate || position.isInsufficientMaterial) {
      return const EngineScore(centipawns: 0);
    }
    if (lines == null || lines.isEmpty) return null;
    return lines.first.score;
  }

  /// A revisão da partida que começa em [start] com [moves]. [analyses] tem
  /// as linhas da engine em cada posição: a de início e a depois de cada
  /// lance (`moves.length + 1` itens; nulo onde a engine não respondeu).
  static GameReview review({
    required Position start,
    required List<Move> moves,
    required List<List<EngineLine>?> analyses,
    int depth = 0,
  }) {
    final reviewed = <ReviewedMove>[];
    final positions = <Position>[start];
    for (final move in moves) {
      positions.add(positions.last.play(move));
    }
    EngineScore? previous;
    final scores = <EngineScore>[];
    for (final (index, position) in positions.indexed) {
      final lines = index < analyses.length ? analyses[index] : null;
      // Sem resposta da engine, fica a avaliação anterior (nenhuma perda).
      final score =
          scoreOf(position, lines) ??
          previous ??
          const EngineScore(centipawns: 0);
      scores.add(score);
      previous = score;
    }
    for (final (index, move) in moves.indexed) {
      final position = positions[index];
      final side = position.turn;
      final lines = index < analyses.length ? analyses[index] : null;
      final best = lines == null || lines.isEmpty || lines.first.moves.isEmpty
          ? null
          : lines.first.moves.first;
      final before = winPercent(scores[index], side);
      final after = winPercent(scores[index + 1], side);
      final second = lines != null && lines.length > 1
          ? winPercent(lines[1].score, side)
          : null;
      reviewed.add(
        ReviewedMove(
          before: scores[index],
          after: scores[index + 1],
          best: best,
          bestLine: best == null ? const [] : lines!.first.moves,
          accuracy: moveAccuracy(before, after),
          quality: classify(
            before: before,
            after: after,
            forced:
                position.legalMoves.values.fold(
                  0,
                  (sum, targets) => sum + targets.size,
                ) ==
                1,
            isBest: best != null && _same(position, best, move),
            secondBest: second,
          ),
        ),
      );
    }
    final whiteFirst = start.turn == Side.white;
    final win = [for (final score in scores) score.whiteWinPercent];
    return GameReview(
      moves: reviewed,
      depth: depth,
      whiteAccuracy: sideAccuracy(win, whiteFirst: whiteFirst, white: true),
      blackAccuracy: sideAccuracy(win, whiteFirst: whiteFirst, white: false),
    );
  }

  /// O lance [uci] da engine é o lance [move] jogado (o roque pode vir
  /// escrito de dois jeitos).
  static bool _same(Position position, String uci, Move move) {
    final engine = Move.parse(uci);
    if (engine == null) return false;
    if (engine is NormalMove && move is NormalMove) {
      return position.normalizeMove(engine) == position.normalizeMove(move);
    }
    return engine == move;
  }

  /// A precisão de um lado (Lichess): a média entre a média ponderada pela
  /// volatilidade da partida e a média harmônica das precisões dos lances.
  /// [win] é a chance de vitória das brancas em cada posição, a de início
  /// primeiro. Nula se o lado não jogou.
  static double? sideAccuracy(
    List<double> win, {
    required bool whiteFirst,
    required bool white,
  }) {
    final moves = win.length - 1;
    if (moves < 1) return null;
    final windowSize = (moves ~/ 10).clamp(2, 8);
    final windows = <List<double>>[
      for (var i = 0; i < math.min(windowSize, win.length) - 2; i++)
        win.take(windowSize).toList(),
      if (win.length <= windowSize)
        win
      else
        for (var i = 0; i + windowSize <= win.length; i++)
          win.sublist(i, i + windowSize),
    ];
    final weights = [
      for (final window in windows)
        _standardDeviation(window).clamp(0.5, 12).toDouble(),
    ];
    final accuracies = <double>[];
    final weighted = <(double, double)>[];
    for (var i = 0; i < moves && i < weights.length; i++) {
      final isWhite = i.isEven == whiteFirst;
      if (isWhite != white) continue;
      final before = isWhite ? win[i] : 100 - win[i];
      final after = isWhite ? win[i + 1] : 100 - win[i + 1];
      final accuracy = moveAccuracy(before, after);
      accuracies.add(accuracy);
      weighted.add((accuracy, weights[i]));
    }
    if (accuracies.isEmpty) return null;
    final weightSum = weighted.fold(0.0, (sum, item) => sum + item.$2);
    final weightedMean =
        weighted.fold(0.0, (sum, item) => sum + item.$1 * item.$2) / weightSum;
    final harmonic =
        accuracies.length /
        accuracies.fold(0.0, (sum, a) => sum + 1 / math.max(a, 0.001));
    return (weightedMean + harmonic) / 2;
  }

  static double _standardDeviation(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.fold(0.0, (sum, v) => sum + (v - mean) * (v - mean)) /
        values.length;
    return math.sqrt(variance);
  }
}
