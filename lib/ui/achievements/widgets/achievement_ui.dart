import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/pace/pace_ui.dart';
import '../../../routing/routes.dart';

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
    _ => Icons.military_tech,
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
    AchievementType.speedrunCompleted => switch ((subcategory, pace)) {
      (final subcategory?, final pace?) => l10n.achievementSpeedrunPaceTitle(
        endgameName(l10n, subcategory),
        pace.label(l10n),
      ),
      _ => l10n.achievementSpeedrunTitle,
    },
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
    AchievementType.speedrunCompleted =>
      pace == null
          ? l10n.achievementSpeedrunHint
          : l10n.achievementSpeedrunPaceHint(pace!.label(l10n)),
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

/// Para onde levar quem quer uma conquista que falta, e o rótulo do botão.
class AchievementShortcut {
  const AchievementShortcut({required this.label, required this.route});

  final String label;
  final String route;
}

/// O detalhe e a lista: grupo, progresso, atalho e datas.
extension AchievementDetailUi on Achievement {
  /// O atalho para onde se conquista: o degrau do adversário na Jornada, o
  /// catálogo ou o speedrun.
  AchievementShortcut shortcut(
    AppLocalizations l10n, [
    List<Character> characters = const [],
  ]) {
    AchievementShortcut play(String rungId) => AchievementShortcut(
      label: l10n.achievementShortcutPlay(rungLabel(l10n, rungId, characters)),
      route: Routes.journeyRung(rungId),
    );
    final journey = AchievementShortcut(
      label: l10n.achievementShortcutJourney,
      route: Routes.journey,
    );
    final speedrun = AchievementShortcut(
      label: l10n.achievementShortcutSpeedrun,
      route: speedrunId == null
          ? Routes.speedruns
          : Routes.speedrun(speedrunId!),
    );
    return switch (type) {
      AchievementType.rungCompleted when rungId != null => play(rungId!),
      AchievementType.beatLevel when level != null => play('$level'),
      AchievementType.beatStockfish => play(OpponentKind.stockfish.code),
      AchievementType.allLevels => AchievementShortcut(
        label: l10n.achievementShortcutTrain,
        route: Routes.catalog,
      ),
      _ => fromSpeedrun ? speedrun : journey,
    };
  }
}

extension AchievementCategoryUi on AchievementCategory {
  String label(AppLocalizations l10n) => switch (this) {
    AchievementCategory.journey => l10n.achievementCategoryJourney,
    AchievementCategory.opponents => l10n.achievementCategoryOpponents,
    AchievementCategory.speedrun => l10n.achievementCategorySpeedrun,
  };
}

extension AchievementProgressUi on AchievementProgress {
  /// "3 de 9 níveis", "2 de 5 desafios".
  String label(AppLocalizations l10n) => switch (unit) {
    AchievementProgressUnit.levels => l10n.achievementProgressLevels(
      done,
      total,
    ),
    AchievementProgressUnit.challenges => l10n.achievementProgressChallenges(
      done,
      total,
    ),
  };
}

/// A data curta da linha: "hoje", "ontem", "há 3 dias" e, passado um mês,
/// o dia e o mês ("7 de out."; de outro ano, com o ano).
String relativeDay(
  AppLocalizations l10n,
  String locale,
  DateTime at,
  DateTime now,
) {
  final local = at.toLocal();
  final today = now.toLocal();
  final days = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
  if (days <= 0) return l10n.achievementsToday;
  if (days == 1) return l10n.achievementsYesterday;
  if (days < 30) return l10n.achievementsDaysAgo(days);
  return local.year == today.year
      ? DateFormat.MMMd(locale).format(local)
      : DateFormat.yMMMd(locale).format(local);
}

/// A data e a hora completas do detalhe: "7 de out. de 2026, 22:41".
String fullDateTime(AppLocalizations l10n, String locale, DateTime at) {
  final local = at.toLocal();
  return l10n.achievementsDateTime(
    DateFormat.yMMMd(locale).format(local),
    DateFormat.jm(locale).format(local),
  );
}
