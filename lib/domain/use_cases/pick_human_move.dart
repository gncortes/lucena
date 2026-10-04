import 'dart:math' as math;

/// Sorteia o lance do Maia entre os lances prováveis.
abstract final class PickHumanMove {
  /// Escolhe um lance de [moves] (lance → probabilidade). [temperature] 1
  /// sorteia na proporção das probabilidades; menor que 1 favorece os mais
  /// prováveis; 0 escolhe sempre o mais provável. [roll] é o número sorteado,
  /// de 0 (inclusive) a 1 (exclusive).
  ///
  /// Nulo se não há lance.
  static String? pick(
    Map<String, double> moves, {
    required double temperature,
    required double roll,
  }) {
    if (moves.isEmpty) return null;
    final best = moves.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    if (temperature <= 0) return best;

    final weights = {
      for (final MapEntry(key: move, value: probability) in moves.entries)
        move: math.pow(probability, 1 / temperature).toDouble(),
    };
    final total = weights.values.fold(0.0, (sum, weight) => sum + weight);
    if (total <= 0) return best;
    var threshold = roll.clamp(0.0, 1.0) * total;
    for (final MapEntry(key: move, value: weight) in weights.entries) {
      threshold -= weight;
      if (threshold < 0) return move;
    }
    return best;
  }
}
