import 'package:dartchess/dartchess.dart';
import 'package:drift/drift.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/player_rating.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/rating_rules.dart';
import '../../services/database/app_database.dart';
import '../maia/maia_repository.dart';
import '../profile/profile_repository.dart';
import 'rating_repository.dart';

/// O rating gravado no banco local. A chance de cada partida vem do Maia: o
/// que ele prevê, naquela posição, entre o rating do jogador e o adversário.
class LocalRatingRepository implements RatingRepository {
  LocalRatingRepository(
    this._database, {
    required this._maia,
    required this._profile,
    required this._now,
  });

  final AppDatabase _database;
  final MaiaRepository _maia;
  final ProfileRepository _profile;
  final Now _now;

  @override
  Future<PlayerRating> current() async {
    final query = _database.select(_database.ratingHistory)
      ..orderBy([(row) => OrderingTerm.desc(row.id)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row != null) return _ratingOf(row);
    return start();
  }

  @override
  Future<PlayerRating> start() async =>
      PlayerRating.start((await _profile.load()).rating);

  @override
  Future<PlayerRating> at(DateTime at) async {
    final query = _database.select(_database.ratingHistory)
      ..where((row) => row.at.isSmallerOrEqualValue(at))
      ..orderBy([(row) => OrderingTerm.desc(row.id)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row != null) return _ratingOf(row);
    return start();
  }

  @override
  Future<List<RatingEntry>> history() async => [
    for (final row in await _rows())
      RatingEntry(
        rating: _ratingOf(row),
        at: row.at.toUtc(),
        gameId: row.gameId,
        speedrunAttemptId: row.speedrunAttemptId,
      ),
  ];

  @override
  Future<List<SpeedrunBonus>> speedrunBonuses() async {
    final rows = await _rows();
    final attempts = {
      for (final attempt in await (_database.select(
        _database.speedrunAttempts,
      )..where((row) => row.id.isIn(_attemptIds(rows)))).get())
        attempt.id: attempt.speedrunId,
    };
    final bonuses = <SpeedrunBonus>[];
    var before = await start();
    for (final row in rows) {
      final attemptId = row.speedrunAttemptId;
      final speedrunId = attempts[attemptId];
      if (attemptId != null && speedrunId != null) {
        bonuses.add(
          SpeedrunBonus(
            attemptId: attemptId,
            speedrunId: speedrunId,
            before: before,
            after: _ratingOf(row),
            at: row.at.toUtc(),
          ),
        );
      }
      before = _ratingOf(row);
    }
    return bonuses;
  }

  @override
  Future<SpeedrunBonus?> addSpeedrunBonus({
    required int attemptId,
    required int points,
  }) => _database.transaction(() async {
    final paid =
        await (_database.select(_database.ratingHistory)
              ..where((row) => row.speedrunAttemptId.equals(attemptId)))
            .getSingleOrNull();
    final attempt = await (_database.select(
      _database.speedrunAttempts,
    )..where((row) => row.id.equals(attemptId))).getSingleOrNull();
    if (paid != null || attempt == null) return null;
    final before = await current();
    final after = PlayerRating(
      rating: (before.rating + points).clamp(
        RatingRules.minRating,
        RatingRules.maxRating,
      ),
      deviation: before.deviation,
      volatility: before.volatility,
    );
    final at = _now();
    await _database
        .into(_database.ratingHistory)
        .insert(
          RatingHistoryCompanion.insert(
            at: at,
            rating: after.rating,
            deviation: after.deviation,
            volatility: after.volatility,
            speedrunAttemptId: Value(attemptId),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return SpeedrunBonus(
      attemptId: attemptId,
      speedrunId: attempt.speedrunId,
      before: before,
      after: after,
      at: at.toUtc(),
    );
  });

  Future<List<RatingRow>> _rows() => (_database.select(
    _database.ratingHistory,
  )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();

  static List<int> _attemptIds(List<RatingRow> rows) => [
    for (final row in rows) ?row.speedrunAttemptId,
  ];

  @override
  Future<RatingEntry?> rate(
    Attempt game, {
    required Side userSide,
    required bool drawGoal,
    int? gameId,
  }) async {
    final stockfish = game.opponent == OpponentKind.stockfish;
    if (game.opponent != OpponentKind.maia && !stockfish) return null;
    final start = GameRules.fromFen(game.startFen ?? '');
    if (start == null) return null;
    final player = await current();
    // Contra o Stockfish, a chance é a contra o Maia mais forte.
    final level = stockfish
        ? MaiaLevels.max
        : MaiaLevels.nearest(game.opponentLevel ?? MaiaLevels.min);
    final user = MaiaLevels.nearest(player.rounded);
    final userMoves = start.turn == userSide;
    final prediction = await _maia.predictMatch(
      start,
      selfElo: userMoves ? user : level,
      oppoElo: userMoves ? level : user,
    );
    final rated = RatingRules.rate(
      player,
      expected: RatingRules.expectedScore(
        win: userMoves ? prediction.win : prediction.loss,
        draw: prediction.draw,
        drawGoal: drawGoal,
      ),
      fulfilled: game.fulfilled,
      draw: game.outcome == AttemptOutcome.draw,
      stockfish: stockfish,
    );
    final entry = RatingEntry(rating: rated, at: _now(), gameId: gameId);
    await _database
        .into(_database.ratingHistory)
        .insert(
          RatingHistoryCompanion.insert(
            gameId: Value(gameId),
            at: entry.at,
            rating: rated.rating,
            deviation: rated.deviation,
            volatility: rated.volatility,
          ),
        );
    return entry;
  }

  static PlayerRating _ratingOf(RatingRow row) => PlayerRating(
    rating: row.rating,
    deviation: row.deviation,
    volatility: row.volatility,
  );
}
