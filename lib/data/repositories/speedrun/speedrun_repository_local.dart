import 'package:drift/drift.dart';

import '../../../domain/models/speedrun.dart';
import '../../services/database/app_database.dart';
import '../progress/progress_repository_local.dart';
import 'speedrun_repository.dart';

/// Tentativas gravadas no banco local.
class LocalSpeedrunRepository implements SpeedrunRepository {
  LocalSpeedrunRepository(this._database);

  final AppDatabase _database;

  @override
  Future<SpeedrunAttempt> start(String speedrunId, DateTime at) async {
    final id = await _database
        .into(_database.speedrunAttempts)
        .insert(
          SpeedrunAttemptsCompanion.insert(
            speedrunId: speedrunId,
            startedAt: at,
          ),
        );
    return SpeedrunAttempt(id: id, speedrunId: speedrunId, startedAt: at);
  }

  @override
  Future<void> abandon(int attemptId, DateTime at) async {
    await (_database.update(_database.speedrunAttempts)
          ..where((row) => row.id.equals(attemptId)))
        .write(SpeedrunAttemptsCompanion(abandonedAt: Value(at)));
  }

  @override
  Future<SpeedrunAttempt?> attempt(int attemptId) async {
    final row = await (_database.select(
      _database.speedrunAttempts,
    )..where((row) => row.id.equals(attemptId))).getSingleOrNull();
    if (row == null) return null;
    return (await _withGames([row])).single;
  }

  @override
  Future<List<SpeedrunAttempt>> attempts(String speedrunId) async {
    final rows =
        await (_database.select(_database.speedrunAttempts)
              ..where((row) => row.speedrunId.equals(speedrunId))
              ..orderBy([(row) => OrderingTerm.asc(row.id)]))
            .get();
    return _withGames(rows);
  }

  Future<List<SpeedrunAttempt>> _withGames(
    List<SpeedrunAttemptRow> rows,
  ) async {
    if (rows.isEmpty) return const [];
    final games =
        await (_database.select(_database.games)
              ..where(
                (row) => row.speedrunAttemptId.isIn([
                  for (final row in rows) row.id,
                ]),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.id)]))
            .get();
    return [
      for (final row in rows)
        SpeedrunAttempt(
          id: row.id,
          speedrunId: row.speedrunId,
          startedAt: row.startedAt.toUtc(),
          abandonedAt: row.abandonedAt?.toUtc(),
          games: [
            for (final game in games)
              if (game.speedrunAttemptId == row.id)
                LocalProgressRepository.attemptOf(game),
          ],
        ),
    ];
  }
}
