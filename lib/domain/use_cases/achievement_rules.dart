import '../models/achievement.dart';
import '../models/attempt.dart';
import '../models/game_setup.dart';
import '../models/journey.dart';
import '../models/pace.dart';
import '../models/speedrun.dart';
import '../models/speedrun_pace.dart';
import 'mastery.dart';

/// As regras das conquistas, todas calculadas do histórico.
abstract final class AchievementRules {
  /// Os níveis do Maia: 1000, 1200... 2600.
  static const maiaLevels = [
    1000,
    1200,
    1400,
    1600,
    1800,
    2000,
    2200,
    2400,
    2600,
  ];

  static bool earned(Achievement a, AchievementFacts f) {
    final fulfilled = f.games.where((game) => game.fulfilled);
    switch (a.type) {
      case AchievementType.firstFulfilled:
        return fulfilled.isNotEmpty;
      case AchievementType.rungCompleted:
        final done = f.games.fulfilledChallenges;
        return f.ladder.any(
          (rung) =>
              (a.rungId == null || rung.id == a.rungId) &&
              _complete(rung, done),
        );
      case AchievementType.allLevels:
        final levels = {
          for (final game in fulfilled)
            if (game.opponent == OpponentKind.maia &&
                f.subcategoryOf[game.positionId] == a.subcategory)
              game.opponentLevel,
        };
        return a.subcategory != null && levels.containsAll(maiaLevels);
      case AchievementType.beatLevel:
        final level = a.level;
        return level != null &&
            fulfilled.any(
              (game) =>
                  // Só o nível da conquista: vencer alguém mais forte não
                  // libera a de outro personagem.
                  game.opponent == OpponentKind.maia &&
                  game.opponentLevel == level,
            );
      case AchievementType.beatStockfish:
        return fulfilled.any((game) => game.opponent == OpponentKind.stockfish);
      case AchievementType.speedrunCompleted:
        return _completed(a, f).any((run) {
          final speedrun = f.speedruns[run.attempt.speedrunId];
          final (baseId, _) = SpeedrunPaces.parse(run.attempt.speedrunId);
          return (a.speedrunId == null || a.speedrunId == baseId) &&
              (a.pace == null ||
                  (speedrun != null &&
                      PaceCategory.of(speedrun.time) == a.pace));
        });
      case AchievementType.flawlessSpeedrun:
        return _completed(a, f).any((run) => run.losses == 0);
      case AchievementType.recordImproved:
        return _recordImproved(f.runs);
      case AchievementType.underTime:
        final under = a.under;
        if (under == null) return false;
        if (a.speedrunKind == null) {
          return fulfilled.any(
            (game) =>
                game.challengeId != null &&
                game.userClock != null &&
                game.userClock! < under,
          );
        }
        return _completed(a, f).any((run) => run.total < under);
    }
  }

  /// As conquistas de [all] ganhas e ainda não desbloqueadas, na ordem de
  /// [all].
  static List<Achievement> newlyEarned(
    List<Achievement> all,
    AchievementFacts facts,
    Set<String> alreadyUnlocked,
  ) => [
    for (final achievement in all)
      if (!alreadyUnlocked.contains(achievement.id) &&
          earned(achievement, facts))
        achievement,
  ];

  static bool _complete(Rung rung, Set<String> done) =>
      Mastery.of([rung], done).rungs.single.status == RungStatus.completed;

  /// As tentativas concluídas, da modalidade da conquista quando ela tem uma.
  static Iterable<SpeedrunRun> _completed(Achievement a, AchievementFacts f) =>
      f.runs.where(
        (run) =>
            run.completed &&
            (a.speedrunKind == null ||
                f.speedruns[run.attempt.speedrunId]?.kind ==
                    SpeedrunKind.fromCode(a.speedrunKind)),
      );

  static bool _recordImproved(List<SpeedrunRun> runs) {
    final bySpeedrun = <String, List<SpeedrunRun>>{};
    for (final run in runs) {
      if (run.finishedAt == null) continue;
      bySpeedrun.putIfAbsent(run.attempt.speedrunId, () => []).add(run);
    }
    for (final completed in bySpeedrun.values) {
      completed.sort((a, b) => a.finishedAt!.compareTo(b.finishedAt!));
      Duration? best;
      for (final run in completed) {
        if (best != null && run.total < best) return true;
        if (best == null || run.total < best) best = run.total;
      }
    }
    return false;
  }
}

extension AttemptsFulfilled on Iterable<Attempt> {
  /// Os desafios com partida de objetivo cumprido.
  Set<String> get fulfilledChallenges => {
    for (final game in this)
      if (game.fulfilled && game.challengeId != null) game.challengeId!,
  };
}
