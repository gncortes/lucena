import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/achievement.dart';
import '../../services/asset_service.dart';
import '../../services/database/app_database.dart';
import 'achievements_repository.dart';

/// As definições de `assets/achievements.json` e as já mostradas no banco.
class LocalAchievementsRepository implements AchievementsRepository {
  LocalAchievementsRepository(this._assets, this._database);

  static const path = 'assets/achievements.json';

  final AssetService _assets;
  final AppDatabase _database;
  Future<List<Achievement>>? _all;

  @override
  Future<List<Achievement>> all() => _all ??= _load();

  Future<List<Achievement>> _load() async {
    final json =
        jsonDecode(await _assets.loadString(path)) as Map<String, dynamic>;
    return [
      for (final item
          in (json['achievements'] as List).cast<Map<String, dynamic>>())
        // Tipo que esta versão não conhece fica de fora.
        ?Achievement.fromJson(item),
    ];
  }

  @override
  Future<Map<String, DateTime>> unlocked() async {
    final rows = await _database.select(_database.unlockedAchievements).get();
    return {for (final row in rows) row.achievementId: row.at.toUtc()};
  }

  @override
  Future<void> unlock(Iterable<String> ids, DateTime at) async {
    await _database.batch((batch) {
      batch.insertAll(_database.unlockedAchievements, [
        for (final id in ids)
          UnlockedAchievementsCompanion.insert(achievementId: id, at: at),
      ], mode: InsertMode.insertOrIgnore);
    });
  }
}
