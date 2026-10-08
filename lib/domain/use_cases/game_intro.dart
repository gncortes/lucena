import '../models/game_mode.dart';

/// A entrada de uma partida nova (T51, A2).
enum GameIntro {
  /// Sem entrada: dois jogadores no mesmo aparelho.
  none,

  /// Os cartões "você contra ele", sem contagem.
  versus,

  /// O versus com a contagem 3, 2, 1: a etapa da Maratona.
  versusCountdown,
}

abstract final class GameIntroRule {
  /// A entrada da partida em [mode]: contra a máquina (Maia, personagem ou
  /// Stockfish), em qualquer modo, o versus; na Maratona, com a contagem;
  /// entre duas pessoas, nada.
  static GameIntro of(GameMode mode) {
    if (mode.isMarathon) return GameIntro.versusCountdown;
    if (mode.opponent.isMachine) return GameIntro.versus;
    return GameIntro.none;
  }
}
