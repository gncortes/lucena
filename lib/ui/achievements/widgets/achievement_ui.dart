import 'package:flutter/material.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';

/// O nome do adversário de um nível do Maia: o do personagem (`Coco`) ou,
/// sem ele, o do motor (`Maia 1000`).
String levelName(
  AppLocalizations l10n,
  List<Character> characters,
  int? level,
) =>
    characters.forLevel(level)?.name ??
    OpponentKind.maia.label(l10n, level: level);

/// O nome do adversário de um degrau pelo id (`1000` → `Coco`, `stockfish`).
String rungLabel(
  AppLocalizations l10n,
  String? rungId, [
  List<Character> characters = const [],
]) => rungId == OpponentKind.stockfish.code
    ? OpponentKind.stockfish.label(l10n)
    : levelName(l10n, characters, int.tryParse(rungId ?? ''));

/// Como cada conquista aparece: ícone, nome e o que é preciso fazer.
extension AchievementUi on Achievement {
  IconData get iconData => switch (icon) {
    'military_tech' => Icons.military_tech,
    'workspace_premium' => Icons.workspace_premium,
    'star' => Icons.star,
    'bolt' => Icons.bolt,
    'local_fire_department' => Icons.local_fire_department,
    'timer' => Icons.timer,
    'verified' => Icons.verified,
    'rocket_launch' => Icons.rocket_launch,
    'psychology' => Icons.psychology,
    _ => Icons.emoji_events,
  };

  /// Com os [characters], os adversários aparecem pelo nome do personagem.
  String title(
    AppLocalizations l10n, [
    List<Character> characters = const [],
  ]) => switch (type) {
    AchievementType.firstFulfilled => l10n.achievementFirstTitle,
    AchievementType.rungCompleted => l10n.achievementRungTitle(
      rungLabel(l10n, rungId, characters),
    ),
    AchievementType.allLevels => switch (subcategory) {
      'queen' => l10n.achievementAllLevelsQueenTitle,
      'rook' => l10n.achievementAllLevelsRookTitle,
      _ => l10n.achievementAllLevelsTitle,
    },
    AchievementType.beatLevel => l10n.achievementBeatTitle(
      levelName(l10n, characters, level),
    ),
    AchievementType.beatStockfish => l10n.achievementBeatTitle(
      OpponentKind.stockfish.label(l10n),
    ),
    AchievementType.flawlessSpeedrun =>
      speedrunKind == null
          ? l10n.achievementFlawlessTitle
          : l10n.achievementFlawlessEndingTitle,
    AchievementType.recordImproved => l10n.achievementRecordTitle,
    AchievementType.underTime =>
      speedrunKind == null
          ? l10n.achievementFastTitle
          : l10n.achievementFastSpeedrunTitle,
  };

  String description(
    AppLocalizations l10n, [
    List<Character> characters = const [],
  ]) => switch (type) {
    AchievementType.firstFulfilled => l10n.achievementFirstHint,
    AchievementType.rungCompleted => l10n.achievementRungHint(
      rungLabel(l10n, rungId, characters),
    ),
    AchievementType.allLevels => l10n.achievementAllLevelsHint,
    AchievementType.beatLevel => l10n.achievementBeatLevelHint(
      levelName(l10n, characters, level),
    ),
    AchievementType.beatStockfish => l10n.achievementBeatStockfishHint,
    AchievementType.flawlessSpeedrun =>
      speedrunKind == null
          ? l10n.achievementFlawlessHint
          : l10n.achievementFlawlessEndingHint,
    AchievementType.recordImproved => l10n.achievementRecordHint,
    AchievementType.underTime =>
      speedrunKind == null
          ? l10n.achievementFastHint(under?.inSeconds ?? 0)
          : l10n.achievementFastSpeedrunHint((under?.inMinutes ?? 0)),
  };
}
