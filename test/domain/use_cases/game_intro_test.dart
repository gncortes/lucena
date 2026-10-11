import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_intro.dart';

void main() {
  test('cada modo, a sua entrada', () {
    final table = {
      // Treinar finais, Jornada, posição personalizada: contra a máquina.
      const GameMode(opponent: OpponentKind.maia, level: 1400):
          GameIntro.versus,
      const GameMode(opponent: OpponentKind.stockfish): GameIntro.versus,
      // Speedrun clássico: contra a máquina, sem contagem.
      const GameMode(
        opponent: OpponentKind.maia,
        level: 1000,
        speedrunId: 'ending.queen',
        speedrunAttemptId: 1,
      ): GameIntro.versus,
      // Maratona: com a contagem 3, 2, 1.
      const GameMode(
        opponent: OpponentKind.maia,
        level: 1000,
        userSide: Side.white,
        speedrunId: 'marathon.queen',
        speedrunAttemptId: 1,
      ): GameIntro.versusCountdown,
      // Dois jogadores no mesmo aparelho: sem entrada.
      const GameMode(): GameIntro.none,
    };
    for (final MapEntry(key: mode, value: intro) in table.entries) {
      expect(GameIntroRule.of(mode), intro, reason: '$mode');
    }
  });
}
