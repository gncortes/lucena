import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/rating/rating_repository.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/domain/use_cases/rating_rules.dart';

/// Rating na memória: toda partida conta com chance [expected] para o jogador.
class FakeRatingRepository implements RatingRepository {
  FakeRatingRepository({int start = 1150, this.expected = 0.5, this._now})
    : initial = start;

  /// O rating da faixa do perfil, antes da primeira partida.
  final int initial;
  double expected;
  final entries = <RatingEntry>[];
  final Now? _now;

  /// O speedrun de cada tentativa, para o bônus dizer de qual foi (o banco
  /// tira da tabela de tentativas).
  String Function(int attemptId)? speedrunOf;
  final _bonusSpeedruns = <int, String>{};

  @override
  Future<PlayerRating> current() async =>
      entries.isEmpty ? PlayerRating.start(initial) : entries.last.rating;

  @override
  Future<PlayerRating> start() async => PlayerRating.start(initial);

  @override
  Future<PlayerRating> at(DateTime at) async {
    for (final entry in entries.reversed) {
      if (!entry.at.isAfter(at)) return entry.rating;
    }
    return PlayerRating.start(initial);
  }

  @override
  Future<List<RatingEntry>> history() async => [...entries];

  @override
  Future<List<SpeedrunBonus>> speedrunBonuses() async {
    final bonuses = <SpeedrunBonus>[];
    var before = PlayerRating.start(initial);
    for (final entry in entries) {
      final attemptId = entry.speedrunAttemptId;
      if (attemptId != null) {
        bonuses.add(
          SpeedrunBonus(
            attemptId: attemptId,
            speedrunId: _bonusSpeedruns[attemptId] ?? '',
            before: before,
            after: entry.rating,
            at: entry.at,
          ),
        );
      }
      before = entry.rating;
    }
    return bonuses;
  }

  @override
  Future<SpeedrunBonus?> addSpeedrunBonus({
    required int attemptId,
    required int points,
  }) async {
    if (entries.any((entry) => entry.speedrunAttemptId == attemptId)) {
      return null;
    }
    final before = await current();
    final after = PlayerRating(
      rating: (before.rating + points).clamp(
        RatingRules.minRating,
        RatingRules.maxRating,
      ),
      deviation: before.deviation,
      volatility: before.volatility,
    );
    final at = _now?.call() ?? DateTime.utc(2026);
    entries.add(
      RatingEntry(rating: after, at: at, speedrunAttemptId: attemptId),
    );
    final speedrunId = speedrunOf?.call(attemptId) ?? '';
    _bonusSpeedruns[attemptId] = speedrunId;
    return SpeedrunBonus(
      attemptId: attemptId,
      speedrunId: speedrunId,
      before: before,
      after: after,
      at: at,
    );
  }

  @override
  Future<RatingEntry?> rate(
    Attempt game, {
    required Side userSide,
    required bool drawGoal,
    int? gameId,
  }) async {
    if (!game.opponent.isMachine) return null;
    final rated = RatingRules.rate(
      await current(),
      expected: expected,
      fulfilled: game.fulfilled,
      stockfish: game.opponent == OpponentKind.stockfish,
    );
    final entry = RatingEntry(rating: rated, at: game.playedAt, gameId: gameId);
    entries.add(entry);
    return entry;
  }
}
