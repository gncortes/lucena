import 'package:lucena/data/repositories/achievements/achievements_repository.dart';
import 'package:lucena/domain/models/achievement.dart';

/// Conquistas na memória.
class FakeAchievementsRepository implements AchievementsRepository {
  FakeAchievementsRepository([List<Achievement>? achievements])
    : achievements = achievements ?? sampleAchievements;

  static const sampleAchievements = [
    Achievement(id: 'first-fulfilled', type: AchievementType.firstFulfilled),
    Achievement(
      id: 'beat-2600',
      type: AchievementType.beatLevel,
      level: 2600,
      icon: 'military_tech',
    ),
  ];

  final List<Achievement> achievements;
  final unlockedById = <String, UnlockedAchievement>{};

  /// Os instantes, pelo id.
  Map<String, DateTime> get unlockedAt => {
    for (final entry in unlockedById.entries) entry.key: entry.value.at,
  };

  @override
  Future<List<Achievement>> all() async => achievements;

  @override
  Future<Map<String, UnlockedAchievement>> unlocked() async => {
    ...unlockedById,
  };

  @override
  Future<void> unlock(Iterable<UnlockedAchievement> achievements) async {
    for (final achievement in achievements) {
      unlockedById.putIfAbsent(achievement.id, () => achievement);
    }
  }
}
