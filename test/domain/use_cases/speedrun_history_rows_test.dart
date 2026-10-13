import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/history_filter.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/use_cases/speedrun_history_rows.dart';

import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  final bases = sampleSpeedruns;
  // O final da dama (iniciante, 3 etapas) no ritmo de 3+2 (blitz).
  final id = SpeedrunPaces.idFor('ending.queen', sampleSpeedrunTime);
  final speedrun = SpeedrunPaces.resolve(bases, id)!;
  final day = DateTime.utc(2026, 10, 4, 12);

  /// Uma tentativa que ganhou as primeiras [stages] etapas, cada uma em
  /// [seconds].
  SpeedrunAttempt attempt(
    int number, {
    int stages = 3,
    int seconds = 20,
    int daysLater = 0,
    String? speedrunId,
    DateTime? abandoned,
  }) => SpeedrunAttempt(
    id: number,
    speedrunId: speedrunId ?? id,
    startedAt: day.add(Duration(days: daysLater)),
    abandonedAt: abandoned,
    games: [
      for (var stage = 0; stage < stages; stage++)
        Attempt(
          positionId: speedrun.stages[stage].position.id,
          playedAt: day.add(Duration(days: daysLater, minutes: stage + 1)),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          userClock: Duration(seconds: seconds),
          speedrunAttemptId: number,
          speedrunStage: stage,
        ),
    ],
  );

  List<SpeedrunHistoryRow> classic(
    List<SpeedrunAttempt> attempts, {
    List<SpeedrunBonus> bonuses = const [],
  }) => SpeedrunHistoryRows.build(
    bases: bases,
    attempts: attempts,
    bonuses: bonuses,
    marathon: false,
  );

  SpeedrunBonus bonus(int attemptId, int points) => SpeedrunBonus(
    attemptId: attemptId,
    speedrunId: id,
    before: const PlayerRating(rating: 1500, deviation: 100, volatility: 0.06),
    after: PlayerRating(
      rating: 1500.0 + points,
      deviation: 100,
      volatility: 0.06,
    ),
    at: day,
  );

  test('a primeira conclusão não é recorde novo', () {
    final row = classic([attempt(1)]).single;

    expect(row.finished, isTrue);
    expect(row.newRecord, isFalse);
    expect(row.bestStage, isNull);
    expect(row.attempts, 1);
  });

  test('bater o tempo anterior é recorde novo; piorar não', () {
    final better = classic([
      attempt(1, seconds: 30),
      attempt(2, seconds: 20, daysLater: 1),
    ]).single;
    final worse = classic([
      attempt(1, seconds: 20),
      attempt(2, seconds: 30, daysLater: 1),
    ]).single;

    expect(better.newRecord, isTrue);
    expect(worse.newRecord, isFalse);
  });

  test('empatar o tempo não bate o recorde', () {
    final row = classic([attempt(1), attempt(2, daysLater: 1)]).single;

    expect(row.newRecord, isFalse);
  });

  test('sem conclusão: a etapa mais longe e as etapas do speedrun', () {
    final row = classic([
      attempt(1, stages: 1),
      attempt(2, stages: 2, daysLater: 1),
      attempt(3, stages: 0, daysLater: 2, abandoned: day),
    ]).single;

    expect(row.finished, isFalse);
    expect(row.bestStage, 3);
    expect(row.stages, 3);
    expect(row.attempts, 3);
  });

  test('o bônus vai só na linha da tentativa que o recebeu', () {
    final other = SpeedrunPaces.idFor('ending.queen', SpeedrunPaces.all.first);
    final rows = classic(
      [attempt(1), attempt(2, speedrunId: other)],
      bonuses: [bonus(1, 12)],
    );

    final paid = rows.firstWhere((row) => row.speedrun.id == id);
    final unpaid = rows.firstWhere((row) => row.speedrun.id == other);
    expect(paid.bonus, 12);
    expect(unpaid.bonus, isNull);
  });

  test('Clássico e Maratona não se misturam', () {
    final all = [attempt(1)];

    expect(
      SpeedrunHistoryRows.build(
        bases: bases,
        attempts: all,
        bonuses: const [],
        marathon: true,
      ),
      isEmpty,
    );
  });

  test('ordem: nível, depois o ritmo', () {
    final slow = SpeedrunPaces.idFor('ending.queen', SpeedrunPaces.all.last);
    final fast = SpeedrunPaces.idFor('ending.queen', SpeedrunPaces.all.first);
    final rows = classic([
      attempt(1, speedrunId: slow),
      attempt(2, speedrunId: fast),
    ]);

    expect([for (final row in rows) row.speedrun.id], [fast, slow]);
  });

  test('filtros por nível e ritmo, e o placar do que sobra', () {
    final fast = SpeedrunPaces.idFor('ending.queen', SpeedrunPaces.all.first);
    final rows = classic([
      attempt(1, seconds: 30),
      attempt(2, seconds: 20, daysLater: 1),
      attempt(3, speedrunId: fast, stages: 1),
    ]);

    final blitz = SpeedrunHistoryRows.filter(
      rows,
      const SpeedrunHistoryFilter(pace: PaceCategory.blitz),
    );
    final advanced = SpeedrunHistoryRows.filter(
      rows,
      const SpeedrunHistoryFilter(level: SpeedrunCategory.advanced),
    );
    final score = SpeedrunHistoryRows.score(rows);

    expect(blitz.single.speedrun.id, id);
    expect(advanced, isEmpty);
    expect(score.attempts, 3);
    expect(score.finished, 1);
    expect(score.newRecords, 1);
  });
}
