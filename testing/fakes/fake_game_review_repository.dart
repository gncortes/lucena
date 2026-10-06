import 'package:lucena/data/repositories/review/game_review_repository.dart';
import 'package:lucena/domain/models/game_review.dart';

/// As revisões na memória.
class FakeGameReviewRepository implements GameReviewRepository {
  final reviews = <int, GameReview>{};

  @override
  Future<GameReview?> load(int gameId) async => reviews[gameId];

  @override
  Future<void> save(int gameId, GameReview review) async =>
      reviews[gameId] = review;

  @override
  Future<Map<int, ({double? white, double? black})>> accuracies(
    Iterable<int> gameIds,
  ) async => {
    for (final id in gameIds)
      if (reviews[id] case final review?)
        id: (white: review.whiteAccuracy, black: review.blackAccuracy),
  };
}
