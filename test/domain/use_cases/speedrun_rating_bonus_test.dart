import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/use_cases/marathon.dart';
import 'package:lucena/domain/use_cases/speedrun_rating_bonus.dart';

/// A regra do bônus: `docs/tasks/T65-regra-rating-speedrun.md` §2 (tabela) e
/// §3 (cadeias).
void main() {
  const rapid = PaceCategory.rapid;
  const blitz = PaceCategory.blitz;
  const bullet = PaceCategory.bullet;
  const ultra = PaceCategory.ultraBullet;
  const groups = [rapid, blitz, bullet, ultra];

  SpeedrunBonusSlot slot(
    PaceCategory group, {
    SpeedrunCategory category = SpeedrunCategory.beginner,
    bool marathon = false,
    String ending = 'rook',
  }) => SpeedrunBonusSlot(
    ending: ending,
    marathon: marathon,
    group: group,
    category: category,
  );

  group('o valor cheio (tabela da §2)', () {
    // R, categoria, clássico R/Bz/Bt/U, Maratona R/Bz/Bt/U.
    const beginner = SpeedrunCategory.beginner;
    const intermediate = SpeedrunCategory.intermediate;
    const advanced = SpeedrunCategory.advanced;
    final table = <(int, SpeedrunCategory, List<int>, List<int>)>[
      (800, beginner, [60, 120, 180, 200], [90, 180, 270, 300]),
      (800, advanced, [60, 120, 180, 200], [90, 180, 270, 300]),
      (1000, beginner, [50, 100, 150, 200], [75, 150, 225, 300]),
      (1000, intermediate, [75, 150, 200, 200], [115, 225, 300, 300]),
      (1000, advanced, [75, 150, 200, 200], [115, 225, 300, 300]),
      (1400, beginner, [0, 0, 0, 0], [0, 0, 0, 0]),
      (1400, intermediate, [55, 105, 160, 200], [80, 160, 235, 300]),
      (1400, advanced, [105, 200, 200, 200], [160, 300, 300, 300]),
      (1800, beginner, [0, 0, 0, 0], [0, 0, 0, 0]),
      (1800, intermediate, [0, 0, 0, 0], [0, 0, 0, 0]),
      (1800, advanced, [115, 200, 200, 200], [170, 300, 300, 300]),
      (2200, intermediate, [0, 0, 0, 0], [0, 0, 0, 0]),
      (2200, advanced, [30, 55, 85, 110], [40, 85, 125, 165]),
      (2600, advanced, [0, 0, 0, 0], [0, 0, 0, 0]),
    ];
    for (final (rating, category, classic, marathon) in table) {
      test('R $rating, ${category.name}', () {
        expect([
          for (final group in groups)
            SpeedrunRatingBonus.full(
              slot(group, category: category),
              rating: rating,
            ),
        ], classic);
        expect([
          for (final group in groups)
            SpeedrunRatingBonus.full(
              slot(group, category: category, marathon: true),
              rating: rating,
            ),
        ], marathon);
      });
    }
  });

  // Uma cadeia: cada conclusão sobe o rating, e a próxima parte dele.
  List<int> chain(int rating, List<SpeedrunBonusSlot> slots) {
    final paid = <int>[];
    final previous = <SpeedrunBonusSlot>[];
    for (final next in slots) {
      final bonus = SpeedrunRatingBonus.of(
        next,
        rating: rating,
        previous: previous,
      );
      paid.add(bonus);
      rating += bonus;
      previous.add(next);
    }
    return paid;
  }

  group('a cadeia com 75% (§3)', () {
    test('R fixo em 1000: Rápido 50; depois Blitz 75 de 100', () {
      expect(SpeedrunRatingBonus.of(slot(rapid), rating: 1000), 50);
      expect(
        SpeedrunRatingBonus.of(
          slot(blitz),
          rating: 1000,
          previous: [slot(rapid)],
        ),
        75,
      );
      expect(SpeedrunRatingBonus.of(slot(blitz), rating: 1000), 100);
    });

    test('um 1000 no mate de torre, do lento ao rápido', () {
      expect(chain(1000, [for (final g in groups) slot(g)]), [50, 70, 90, 85]);
    });

    test('a ordem inversa não dá vantagem que valha farm', () {
      expect(chain(1000, [for (final g in groups.reversed) slot(g)]), [
        200,
        70,
        30,
        10,
      ]);
    });

    test('um iniciante de 800, do lento ao rápido', () {
      expect(chain(800, [for (final g in groups) slot(g)]), [60, 85, 120, 135]);
    });

    test('a cadeia do canvas', () {
      final queenBlitz = slot(blitz, ending: 'queen');
      final queenRapid = slot(rapid, ending: 'queen');
      expect(SpeedrunRatingBonus.of(queenBlitz, rating: 1000), 100);
      expect(SpeedrunRatingBonus.full(queenRapid, rating: 1100), 40);
      expect(
        SpeedrunRatingBonus.of(
          queenRapid,
          rating: 1100,
          previous: [queenBlitz],
        ),
        30,
      );
      expect(
        SpeedrunRatingBonus.of(
          slot(
            rapid,
            ending: 'twoBishops',
            category: SpeedrunCategory.intermediate,
          ),
          rating: 1130,
          previous: [queenBlitz, queenRapid],
        ),
        80,
      );
      final marathon = slot(rapid, ending: 'queen', marathon: true);
      expect(SpeedrunRatingBonus.full(marathon, rating: 1237), 40);
      expect(
        SpeedrunRatingBonus.of(
          marathon,
          rating: 1237,
          previous: [queenBlitz, queenRapid],
        ),
        30,
      );
      expect(
        SpeedrunRatingBonus.of(
          slot(blitz),
          rating: 1267,
          previous: [queenBlitz, queenRapid, marathon],
        ),
        40,
      );
    });

    test('o mesmo grupo na mesma modalidade não paga de novo', () {
      expect(
        SpeedrunRatingBonus.of(
          slot(blitz),
          rating: 1000,
          previous: [slot(blitz)],
        ),
        0,
      );
      // A Maratona do mesmo grupo é outra modalidade: paga 75%.
      expect(
        SpeedrunRatingBonus.of(
          slot(blitz, marathon: true),
          rating: 1000,
          previous: [slot(blitz)],
        ),
        115,
      );
    });

    test('menos de 5 pontos é nada', () {
      // f = 1/400: 1399 × 5% × 1/400 ≈ 0,17.
      expect(SpeedrunRatingBonus.full(slot(rapid), rating: 1399), 0);
      // Cheio 5, 75% = 3,75 → 5; cheio 0 → 0.
      expect(
        SpeedrunRatingBonus.of(
          slot(rapid),
          rating: 1375,
          previous: [slot(blitz)],
        ),
        5,
      );
      expect(
        SpeedrunRatingBonus.of(
          slot(rapid),
          rating: 1390,
          previous: [slot(blitz)],
        ),
        0,
      );
    });
  });

  group('quem entra na cadeia', () {
    const blitzTime = TimeControl(
      initial: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    );
    const ending = Speedrun(
      id: 'ending.queen',
      kind: SpeedrunKind.ending,
      category: SpeedrunCategory.beginner,
      time: SpeedrunPaces.standard,
      stages: [],
    );

    test('o de final e a Maratona dele formam a mesma cadeia', () {
      final classic = SpeedrunRatingBonus.slotOf(
        SpeedrunPaces.withTime(ending, blitzTime),
      )!;
      final marathon = SpeedrunRatingBonus.slotOf(
        SpeedrunPaces.withTime(Marathon.of(ending), blitzTime),
      )!;
      expect(classic.ending, 'queen');
      expect(classic.marathon, isFalse);
      expect(classic.group, blitz);
      expect(marathon.ending, 'queen');
      expect(marathon.marathon, isTrue);
    });

    test('o 10+0 é Rápido; o 5+3, Blitz', () {
      expect(
        SpeedrunRatingBonus.slotOf(
          SpeedrunPaces.withTime(
            ending,
            const TimeControl(initial: Duration(minutes: 10)),
          ),
        )!.group,
        rapid,
      );
      expect(SpeedrunRatingBonus.slotOf(ending)!.group, blitz);
    });

    test('só da Jornada, de degrau ou de exercícios: sem bônus', () {
      expect(
        SpeedrunRatingBonus.slotOf(ending.copyWith(journeyOnly: true)),
        isNull,
      );
      expect(
        SpeedrunRatingBonus.slotOf(ending.copyWith(kind: SpeedrunKind.rung)),
        isNull,
      );
      expect(
        SpeedrunRatingBonus.slotOf(
          ending.copyWith(kind: SpeedrunKind.exercises),
        ),
        isNull,
      );
    });
  });
}
