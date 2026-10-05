import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';

import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';

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

  group('com o histórico das partidas', () {
    Attempt game(AttemptOutcome outcome) => Attempt(
      positionId: 'basic.queen.0001',
      playedAt: at,
      outcome: outcome,
      fulfilled: outcome == AttemptOutcome.win,
      opponent: OpponentKind.maia,
      opponentLevel: 1000,
    );

    test('cada partida que contou vem com a variação e a partida dela, da '
        'mais recente para a mais antiga', () async {
      final progress = FakeProgressRepository();
      final rating = FakeRatingRepository();
      for (final outcome in [
        AttemptOutcome.win,
        AttemptOutcome.loss,
        AttemptOutcome.win,
      ]) {
        final played = game(outcome);
        final id = await progress.addAttempt(played);
        await rating.rate(
          played,
          userSide: Side.white,
          drawGoal: false,
          gameId: id,
        );
      }
      final cubit = RatingCubit(rating, progress: progress);
      addTearDown(cubit.close);
      await cubit.load();

      final games = cubit.state.games;
      expect(games.map((game) => game.attempt?.outcome), [
        AttemptOutcome.win,
        AttemptOutcome.loss,
        AttemptOutcome.win,
      ]);
      expect(games[0].change, greaterThan(0));
      expect(games[1].change, lessThan(0));
      // O ponto de partida não fica no histórico: a primeira não tem variação.
      expect(games[2].change, isNull);
      expect(games[0].entry, cubit.state.history.last);
    });

    test('sem o histórico das partidas, só os pontos do rating', () async {
      final rating = FakeRatingRepository();
      await rating.rate(
        game(AttemptOutcome.win),
        userSide: Side.white,
        drawGoal: false,
      );
      final cubit = RatingCubit(rating);
      addTearDown(cubit.close);
      await cubit.load();

      expect(cubit.state.games, hasLength(1));
      expect(cubit.state.games.single.attempt, isNull);
    });
  });
}
