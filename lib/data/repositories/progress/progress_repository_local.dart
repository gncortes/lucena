import 'package:drift/drift.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_setup.dart';
import '../../services/database/app_database.dart';
import 'progress_repository.dart';

/// Histórico gravado no banco local.
class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> addAttempt(Attempt attempt) async {
    await _database.into(_database.games).insert(gameRow(attempt));
  }

  @override
  Future<List<Attempt>> attemptsFor(String positionId) =>
      _newestFirst((row) => row.positionId.equals(positionId));

  @override
  Future<Set<String>> fulfilledPositions() async {
    final games = _database.games;
    final query = _database.selectOnly(games, distinct: true)
      ..addColumns([games.positionId])
      ..where(games.fulfilled.equals(true));
    final rows = await query.get();
    return {for (final row in rows) row.read(games.positionId)!};
  }

  @override
  Future<List<Attempt>> attemptsForChallenge(String challengeId) =>
      _newestFirst((row) => row.challengeId.equals(challengeId));

  @override
  Future<Set<String>> fulfilledChallenges() async {
    final games = _database.games;
    final query = _database.selectOnly(games, distinct: true)
      ..addColumns([games.challengeId])
      ..where(games.fulfilled.equals(true) & games.challengeId.isNotNull());
    final rows = await query.get();
    return {for (final row in rows) row.read(games.challengeId)!};
  }

  Future<List<Attempt>> _newestFirst(
    Expression<bool> Function($GamesTable row) filter,
  ) async {
    final query = _database.select(_database.games)
      ..where(filter)
      ..orderBy([
        (row) => OrderingTerm.desc(row.playedAt),
        (row) => OrderingTerm.desc(row.id),
      ]);
    return [for (final row in await query.get()) attemptOf(row)];
  }

  /// A linha gravada de uma partida.
  static GamesCompanion gameRow(Attempt attempt) {
    return GamesCompanion.insert(
      positionId: attempt.positionId,
      playedAt: attempt.playedAt,
      outcome: attempt.outcome.code,
      fulfilled: attempt.fulfilled,
      opponent: attempt.opponent.code,
      opponentLevel: Value(attempt.opponentLevel),
      startedAt: Value(attempt.startedAt),
      startFen: Value(attempt.startFen),
      moves: Value(attempt.moves.join(' ')),
      endReason: Value(attempt.endReason?.name),
      userTime: Value(attempt.userTime?.code),
      opponentTime: Value(attempt.opponentTime?.code),
      userClockMs: Value(attempt.userClock?.inMilliseconds),
      challengeId: Value(attempt.challengeId),
      speedrunAttemptId: Value(attempt.speedrunAttemptId),
      speedrunStage: Value(attempt.speedrunStage),
    );
  }

  /// A partida de uma linha gravada.
  static Attempt attemptOf(GameRow row) {
    final userClockMs = row.userClockMs;
    return Attempt(
      positionId: row.positionId,
      // O banco devolve na hora local; o app trabalha com instantes em UTC.
      playedAt: row.playedAt.toUtc(),
      outcome: AttemptOutcome.fromCode(row.outcome),
      fulfilled: row.fulfilled,
      opponent: OpponentKind.fromCode(row.opponent),
      opponentLevel: row.opponentLevel,
      startedAt: row.startedAt?.toUtc(),
      startFen: row.startFen,
      moves: row.moves.isEmpty ? const [] : row.moves.split(' '),
      endReason: GameEndReason.values.asNameMap()[row.endReason],
      userTime: TimeControl.tryParse(row.userTime),
      opponentTime: TimeControl.tryParse(row.opponentTime),
      userClock: userClockMs == null
          ? null
          : Duration(milliseconds: userClockMs),
      challengeId: row.challengeId,
      speedrunAttemptId: row.speedrunAttemptId,
      speedrunStage: row.speedrunStage,
    );
  }
}
