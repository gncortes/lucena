import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';

import '../../../../testing/fakes/fake_achievements_repository.dart';
import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_game_review_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_speedrun_repository.dart';

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

    test('os números do jogador: partidas, vitórias, dias seguidos, '
        'conquistas e o melhor speedrun', () async {
      final rating = FakeRatingRepository();
      final progress = FakeProgressRepository();
      final speedruns = FakeSpeedrunRepository(progress);
      final now = FakeNow(at.add(const Duration(hours: 3)));
      await progress.addAttempt(game(AttemptOutcome.win));
      await progress.addAttempt(game(AttemptOutcome.loss));
      // Um speedrun concluído: duas etapas de 30 s.
      final attempt = await speedruns.start('rung.1000', at);
      for (final stage in [0, 1]) {
        await progress.addAttempt(
          game(AttemptOutcome.win).copyWith(
            userClock: const Duration(seconds: 30),
            speedrunAttemptId: attempt.id,
            speedrunStage: stage,
          ),
        );
      }
      final cubit = RatingCubit(
        rating,
        progress: progress,
        achievements: FakeAchievementsRepository(),
        speedruns: speedruns,
        journey: FakeJourneyRepository(),
        now: now,
      );
      addTearDown(cubit.close);
      await cubit.load();

      final numbers = cubit.state.numbers!;
      expect(numbers.stats.games, 4);
      expect(numbers.stats.wins, 3);
      expect(numbers.stats.streakDays, 1);
      expect(numbers.achievementsUnlocked, 0);
      expect(numbers.achievementsTotal, greaterThan(0));
      expect(numbers.bestSpeedrun, const Duration(minutes: 1));
    });

    test('o histórico geral: todas as partidas, da mais recente para a mais '
        'antiga, e o rating nas que contaram', () async {
      final rating = FakeRatingRepository();
      final progress = FakeProgressRepository();
      // Uma partida que contou e, depois, duas que não (sem rating).
      final rated = game(AttemptOutcome.win);
      final id = await progress.addAttempt(rated);
      await rating.rate(
        rated,
        userSide: Side.white,
        drawGoal: false,
        gameId: id,
      );
      final later = game(AttemptOutcome.loss).copyWith(
        playedAt: at.add(const Duration(hours: 1)),
        opponent: OpponentKind.twoPlayers,
        opponentLevel: null,
      );
      final latest = game(AttemptOutcome.draw)
          .copyWith(playedAt: at.add(const Duration(hours: 2)));
      await progress.addAttempt(latest);
      await progress.addAttempt(later);
      final cubit = RatingCubit(
        rating,
        progress: progress,
        characters: FakeCharacterRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load();

      final log = cubit.state.log;
      expect(log.map((entry) => entry.attempt), [latest, later, rated]);
      expect(log.map((entry) => entry.rated != null), [false, false, true]);
      expect(log.last.rated!.entry, cubit.state.history.single);
      expect(cubit.state.characters, isNotEmpty);
    });

    test('partidas do mesmo instante: a gravada por último vem primeiro, com '
        'a variação dela', () async {
      final rating = FakeRatingRepository();
      final progress = FakeProgressRepository();
      for (final outcome in [AttemptOutcome.win, AttemptOutcome.loss]) {
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

      final log = cubit.state.log;
      expect(log.map((entry) => entry.attempt.outcome), [
        AttemptOutcome.loss,
        AttemptOutcome.win,
      ]);
      expect(log.first.rated!.change, lessThan(0));
      expect(log.last.rated!.change, isNull);
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
      expect(cubit.state.numbers, isNull);
    });

    test(
      'no histórico, a precisão do jogador nas partidas já revisadas',
      () async {
        final progress = FakeProgressRepository();
        final reviews = FakeGameReviewRepository();
        final reviewed = await progress.addAttempt(
          Attempt(
            positionId: 'basic.queen.0001',
            playedAt: at,
            outcome: AttemptOutcome.win,
            fulfilled: true,
            opponent: OpponentKind.maia,
            opponentLevel: 1000,
            userSide: Side.white,
          ),
        );
        final black = await progress.addAttempt(
          Attempt(
            positionId: 'basic.queen.0001',
            playedAt: at,
            outcome: AttemptOutcome.loss,
            fulfilled: false,
            opponent: OpponentKind.maia,
            opponentLevel: 1000,
            userSide: Side.black,
          ),
        );
        final plain = await progress.addAttempt(game(AttemptOutcome.loss));
        for (final id in [reviewed, black]) {
          await reviews.save(
            id,
            const GameReview(
              moves: [],
              whiteAccuracy: 91.4,
              blackAccuracy: 62.5,
            ),
          );
        }
        final cubit = RatingCubit(
          FakeRatingRepository(),
          progress: progress,
          reviews: reviews,
        );
        addTearDown(cubit.close);
        await cubit.load();

        final log = {for (final game in cubit.state.log) game.id: game};
        expect(log[reviewed]!.accuracy, 91.4);
        expect(log[black]!.accuracy, 62.5);
        expect(log[plain]!.accuracy, isNull);
      },
    );
  });
}
