import '../models/game_setup.dart';
import '../models/speedrun.dart';

/// A dificuldade de um speedrun na lista. Os de final trazem a sua; os de
/// adversário e as séries de exercícios ficam na faixa do adversário mais
/// forte (o Coco e o Tito são de iniciante); a Jornada completa passa por
/// todas e aparece sempre (nula).
abstract final class SpeedrunCategories {
  static SpeedrunCategory? of(Speedrun speedrun) {
    final own = speedrun.category;
    if (own != null) return own;
    if (speedrun.kind == SpeedrunKind.full) return null;
    var strongest = 0;
    for (final stage in speedrun.stages) {
      final opponent = stage.opponent;
      final level = opponent.kind == OpponentKind.maia
          ? opponent.level ?? 0
          : 3000;
      if (level > strongest) strongest = level;
    }
    if (strongest == 0) return null;
    if (strongest <= 1200) return SpeedrunCategory.beginner;
    if (strongest <= 1800) return SpeedrunCategory.intermediate;
    return SpeedrunCategory.advanced;
  }
}
