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
}
