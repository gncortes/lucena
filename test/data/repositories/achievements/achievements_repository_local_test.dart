import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/achievements/achievements_repository_local.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/domain/models/achievement.dart';

/// A conquista gravada guarda de onde veio (T51, A6); as gravadas antes,
/// sem a origem, continuam valendo.
void main() {
  test('da versão 6 para a 7: a conquista antiga fica só com a data e as '
      'novas guardam a partida e a tentativa', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // As tabelas da versão 6 que esta migração toca.
          raw
            ..execute(
              'CREATE TABLE unlocked_achievements (achievement_id TEXT NOT '
              'NULL, at INTEGER NOT NULL, PRIMARY KEY (achievement_id))',
            )
            ..execute(
              'INSERT INTO unlocked_achievements (achievement_id, at) '
              "VALUES ('first-fulfilled', 1759880460)",
            )
            ..execute('PRAGMA user_version = 6');
        },
      ),
    );
    addTearDown(database.close);
    final repository = LocalAchievementsRepository(
      const AssetService(),
      database,
    );

    final old = (await repository.unlocked())['first-fulfilled']!;
    expect(old.at, DateTime.utc(2025, 10, 7, 23, 41));
    expect(old.gameId, isNull);
    expect(old.speedrunAttemptId, isNull);
    expect(old.hasSource, isFalse);

    final fresh = UnlockedAchievement(
      id: 'first-speedrun',
      at: DateTime.utc(2026, 10, 7, 22, 41),
      gameId: 12,
      speedrunAttemptId: 3,
    );
    await repository.unlock([fresh]);
    final saved = (await repository.unlocked())['first-speedrun']!;
    expect(saved, fresh);
    expect(saved.hasSource, isTrue);
  });

  test('desbloquear de novo não troca a data nem a origem', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LocalAchievementsRepository(
      const AssetService(),
      database,
    );
    final first = UnlockedAchievement(
      id: 'beat-1000',
      at: DateTime.utc(2026, 10, 1),
      gameId: 1,
    );
    await repository.unlock([first]);
    await repository.unlock([
      UnlockedAchievement(
        id: 'beat-1000',
        at: DateTime.utc(2026, 10, 2),
        gameId: 2,
      ),
    ]);

    expect((await repository.unlocked()).values, [first]);
  });
}
