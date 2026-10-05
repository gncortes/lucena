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
  final unlockedAt = <String, DateTime>{};

  @override
  Future<List<Achievement>> all() async => achievements;

  @override
  Future<Map<String, DateTime>> unlocked() async => {...unlockedAt};

  @override
  Future<void> unlock(Iterable<String> ids, DateTime at) async {
    for (final id in ids) {
      unlockedAt.putIfAbsent(id, () => at);
    }
  }
}
