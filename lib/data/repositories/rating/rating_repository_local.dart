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
    final profile = await _profile.load();
    return PlayerRating.start(profile.rating);
  }

  @override
  Future<List<RatingEntry>> history() async {
    final query = _database.select(_database.ratingHistory)
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    return [
      for (final row in await query.get())
        RatingEntry(
          rating: _ratingOf(row),
          at: row.at.toUtc(),
          gameId: row.gameId,
        ),
    ];
  }

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
