import 'package:drift/drift.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/game_setup.dart';
import '../../services/database/app_database.dart';
import 'progress_repository.dart';

/// Histórico gravado no banco local.
class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> addAttempt(Attempt attempt) async {
    await _database
        .into(_database.attempts)
        .insert(
          AttemptsCompanion.insert(
            positionId: attempt.positionId,
            playedAt: attempt.playedAt,
            outcome: attempt.outcome.code,
            fulfilled: attempt.fulfilled,
            opponent: attempt.opponent.code,
            opponentLevel: Value(attempt.opponentLevel),
          ),
        );
  }

  @override
  Future<List<Attempt>> attemptsFor(String positionId) async {
    final query = _database.select(_database.attempts)
      ..where((row) => row.positionId.equals(positionId))
      ..orderBy([
        (row) => OrderingTerm.desc(row.playedAt),
        (row) => OrderingTerm.desc(row.id),
      ]);
    final rows = await query.get();
    return [
      for (final row in rows)
        Attempt(
          positionId: row.positionId,
          playedAt: row.playedAt,
          outcome: AttemptOutcome.fromCode(row.outcome),
          fulfilled: row.fulfilled,
          opponent: OpponentKind.fromCode(row.opponent),
          opponentLevel: row.opponentLevel,
        ),
    ];
  }

  @override
  Future<Set<String>> fulfilledPositions() async {
    final query = _database.selectOnly(_database.attempts, distinct: true)
      ..addColumns([_database.attempts.positionId])
      ..where(_database.attempts.fulfilled.equals(true));
    final rows = await query.get();
    return {for (final row in rows) row.read(_database.attempts.positionId)!};
  }
}
