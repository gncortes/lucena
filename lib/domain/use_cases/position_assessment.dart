/// Estado discreto da posição, do ponto de vista do personagem.
enum PositionState { bigAdvantage, better, equal, worse, bigDisadvantage }

/// Uma avaliação do motor, do ponto de vista do personagem. Nunca aparece
/// para o jogador: só escolhe falas e emoções.
class Evaluation {
  const Evaluation({this.centipawns, this.mate});

  /// Vantagem em centipeões (positivo = personagem melhor).
  final int? centipawns;

  /// Mate em N (positivo = o personagem dá mate).
  final int? mate;

  /// Teto dos centipeões, para uma avaliação absurda não dominar a média.
  static const cap = 5000;

  /// Valor de um mate, um pouco menor quanto mais longe ele está.
  static const mateScore = 10000;

  /// Um número só: mate vira ±(10000 − |mate|·10); centipeões vão até ±5000.
  int get score {
    final m = mate;
    if (m != null && m != 0) {
      final value = mateScore - m.abs() * 10;
      return m > 0 ? value : -value;
    }
    return (centipawns ?? 0).clamp(-cap, cap);
  }

  @override
  bool operator ==(Object other) =>
      other is Evaluation &&
      other.centipawns == centipawns &&
      other.mate == mate;

  @override
  int get hashCode => Object.hash(centipawns, mate);
}

/// Faixas da avaliação que separam os estados da posição.
abstract final class PositionAssessment {
  /// A partir daqui (em centipeões), um lado está melhor.
  static const better = 120;

  /// A partir daqui, a vantagem é grande.
  static const bigAdvantage = 400;

  /// Variação de um lance que conta como erro grave.
  static const swing = 250;

  /// O estado da posição para o [score] do personagem.
  static PositionState stateOf(int score) {
    if (score >= bigAdvantage) return PositionState.bigAdvantage;
    if (score >= better) return PositionState.better;
    if (score <= -bigAdvantage) return PositionState.bigDisadvantage;
    if (score <= -better) return PositionState.worse;
    return PositionState.equal;
  }
}
