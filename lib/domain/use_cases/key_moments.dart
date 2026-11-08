import '../models/game_review.dart';

/// Um momento decisivo da partida: o lance, de quem foi, a qualidade e
/// quanto da chance de vitória ele custou a quem o jogou.
class KeyMoment {
  const KeyMoment({
    required this.index,
    required this.byWhite,
    required this.move,
    required this.loss,
  });

  /// O lance (índice na lista de lances).
  final int index;

  /// Quem jogou: as brancas ou as pretas.
  final bool byWhite;
  final ReviewedMove move;

  /// Pontos de chance de vitória perdidos por quem jogou (0 a 100).
  final double loss;
}

/// Os momentos decisivos de uma partida revisada (H-PAR-13) e o resumo de
/// qualidades por lado. Dart puro.
abstract final class KeyMoments {
  /// Quantos momentos aparecem no máximo.
  static const maxMoments = 3;

  /// O custo mínimo, em pontos de chance de vitória, para um erro valer como
  /// momento decisivo.
  static const minLoss = 10.0;

  /// Os erros (erro, lance perdido e erro grave) de qualquer lado que mais
  /// custaram, no máximo [maxMoments], em ordem de partida.
  static List<KeyMoment> pick(GameReview review, {required bool firstIsWhite}) {
    final candidates = <KeyMoment>[];
    for (final (index, move) in review.moves.indexed) {
      final quality = move.quality;
      if (quality != MoveQuality.mistake &&
          quality != MoveQuality.miss &&
          quality != MoveQuality.blunder) {
        continue;
      }
      final byWhite = index.isEven == firstIsWhite;
      final before = byWhite
          ? move.before.whiteWinPercent
          : 100 - move.before.whiteWinPercent;
      final after = byWhite
          ? move.after.whiteWinPercent
          : 100 - move.after.whiteWinPercent;
      final loss = before - after;
      if (loss < minLoss) continue;
      candidates.add(
        KeyMoment(index: index, byWhite: byWhite, move: move, loss: loss),
      );
    }
    candidates.sort((a, b) => b.loss.compareTo(a.loss));
    final top = candidates.take(maxMoments).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return top;
  }

  /// Verdadeiro se o jogador (de brancas se [userIsWhite]) fez algum erro
  /// sério: erro, lance perdido ou erro grave.
  static bool userMadeNoError(
    GameReview review, {
    required bool firstIsWhite,
    required bool userIsWhite,
  }) {
    final counts = review.counts(
      white: userIsWhite,
      firstIsWhite: firstIsWhite,
    );
    return counts[MoveQuality.mistake]! +
            counts[MoveQuality.miss]! +
            counts[MoveQuality.blunder]! ==
        0;
  }

  /// As seis linhas da tabela de qualidades de um lado: o lance ótimo conta
  /// como melhor e o lance perdido como erro. Lances forçados não entram.
  static Map<MoveQuality, int> qualityTable(
    GameReview review, {
    required bool white,
    required bool firstIsWhite,
  }) {
    final counts = review.counts(white: white, firstIsWhite: firstIsWhite);
    return {
      MoveQuality.best: counts[MoveQuality.best]! + counts[MoveQuality.great]!,
      MoveQuality.excellent: counts[MoveQuality.excellent]!,
      MoveQuality.good: counts[MoveQuality.good]!,
      MoveQuality.inaccuracy: counts[MoveQuality.inaccuracy]!,
      MoveQuality.mistake:
          counts[MoveQuality.mistake]! + counts[MoveQuality.miss]!,
      MoveQuality.blunder: counts[MoveQuality.blunder]!,
    };
  }
}
