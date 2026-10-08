import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/rating/rating_repository.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/use_cases/rating_rules.dart';

/// Rating na memória: toda partida conta com chance [expected] para o jogador.
class FakeRatingRepository implements RatingRepository {
  FakeRatingRepository({int start = 1150, this.expected = 0.5})
    : initial = start;

  /// O rating da faixa do perfil, antes da primeira partida.
  final int initial;
  double expected;
  final entries = <RatingEntry>[];

  @override
  Future<PlayerRating> current() async =>
      entries.isEmpty ? PlayerRating.start(initial) : entries.last.rating;

  @override
  Future<PlayerRating> start() async => PlayerRating.start(initial);

  @override
  Future<List<RatingEntry>> history() async => [...entries];

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
