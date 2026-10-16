import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/history_filter.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/use_cases/history_games.dart';
import 'package:lucena/domain/use_cases/rating_period.dart';

void main() {
  final now = DateTime.utc(2026, 10, 10, 12);

  RatingEntry entry(double rating, DateTime at, {int? game, int? bonus}) =>
      RatingEntry(
        rating: PlayerRating(rating: rating, deviation: 100, volatility: 0.06),
        at: at,
        gameId: game,
        speedrunAttemptId: bonus,
      );

  Attempt attempt(
    AttemptOutcome outcome,
    DateTime at, {
    TimeControl? time,
    int? speedrunAttempt,
  }) => Attempt(
    positionId: 'basic.queen.0001',
    playedAt: at,
    outcome: outcome,
    fulfilled: outcome == AttemptOutcome.win,
    opponent: OpponentKind.maia,
    userTime: time,
    speedrunAttemptId: speedrunAttempt,
  );

  const blitz = TimeControl(initial: Duration(minutes: 3));
  const bullet = TimeControl(initial: Duration(minutes: 1));
  final d1 = now.subtract(const Duration(days: 40));
  final d2 = now.subtract(const Duration(days: 3));
  final d3 = now.subtract(const Duration(days: 1));
  final d4 = now.subtract(const Duration(hours: 1));

  final history = [
    entry(1500, d1, game: 1),
    entry(1520, d2, game: 2),
    entry(1540, d3, bonus: 9),
    entry(1530, d4, game: 3),
    entry(1550, d4, game: 4),
  ];
  final attempts = {
    1: attempt(AttemptOutcome.win, d1, time: blitz),
    2: attempt(AttemptOutcome.win, d2, time: bullet),
    3: attempt(AttemptOutcome.loss, d4),
    // Etapa de speedrun: fora de Partidas.
    4: attempt(AttemptOutcome.win, d4, speedrunAttempt: 1),
  };

  List<HistoryGame> games() => HistoryGames.build(history, attempts: attempts);

  test('sem bônus nem etapa de speedrun, da mais recente para a antiga', () {
    final list = games();

    expect([for (final game in list) game.id], [3, 2, 1]);
    expect(HistoryGames.counted(history), 4);
  });

  test('a variação conta o bônus anterior; a primeira não tem', () {
    final list = games();

    // 1530 depois do bônus de 1540.
    expect(list[0].change, -10);
    expect(list[1].change, 20);
    expect(list[2].change, isNull);
  });

  test('filtros de período, resultado e ritmo', () {
    final all = games();

    expect(
      HistoryGames.filter(
        all,
        const GamesHistoryFilter(period: RatingPeriod.all),
        now,
      ),
      hasLength(3),
    );
    final recent = HistoryGames.filter(
      all,
      const GamesHistoryFilter(period: RatingPeriod.week),
      now,
    );
    expect([for (final g in recent) g.id], [3, 2]);
    final wins = HistoryGames.filter(
      all,
      const GamesHistoryFilter(result: AttemptOutcome.win),
      now,
    );
    expect([for (final g in wins) g.id], [2, 1]);
    final noClock = HistoryGames.filter(
      all,
      const GamesHistoryFilter(pace: GamesHistoryFilter.noClock),
      now,
    );
    expect([for (final g in noClock) g.id], [3]);
    final bullets = HistoryGames.filter(
      all,
      GamesHistoryFilter(pace: PaceCategory.of(bullet).code),
      now,
    );
    expect([for (final g in bullets) g.id], [2]);
  });

  test('placar', () {
    final score = HistoryGames.score(games());

    expect(score.wins, 2);
    expect(score.draws, 0);
    expect(score.losses, 1);
    expect(score.total, 3);
  });

  test('filtro grava e lê; lixo volta ao padrão', () {
    const filter = GamesHistoryFilter(
      period: RatingPeriod.week,
      result: AttemptOutcome.draw,
      pace: 'none',
    );

    expect(GamesHistoryFilter.fromCode(filter.code), filter);
    expect(GamesHistoryFilter.fromCode('{lixo'), const GamesHistoryFilter());
    expect(filter.count, 3);
    expect(const GamesHistoryFilter().isEmpty, isTrue);
  });
}
