import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';

void main() {
  final at = DateTime.utc(2026, 10, 5);
  RatingEntry entry(double rating) => RatingEntry(
    rating: PlayerRating(rating: rating),
    at: at,
  );

  test('a variação é a da última partida', () {
    final state = RatingState(
      current: const PlayerRating(rating: 626),
      history: [entry(1100), entry(889.4), entry(626.2)],
    );
    expect(state.lastChange, -263);
  });

  test('sem duas partidas, sem variação', () {
    expect(const RatingState().lastChange, isNull);
    expect(RatingState(history: [entry(1100)]).lastChange, isNull);
  });
}
