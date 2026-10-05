import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/use_cases/rating_period.dart';

void main() {
  final now = DateTime.utc(2026, 10, 5, 12);

  RatingEntry at(int daysAgo, double rating) => RatingEntry(
    rating: PlayerRating(rating: rating),
    at: now.subtract(Duration(days: daysAgo)),
  );

  // Do mais antigo para o mais recente.
  final history = [
    at(400, 1100),
    at(100, 1180),
    at(40, 1150),
    at(20, 1210),
    at(5, 1200),
    at(0, 1230),
  ];

  group('entries', () {
    test('tudo: o histórico inteiro', () {
      expect(RatingPeriod.all.entries(history, now), history);
    });

    test('o período começa no ponto de antes dele, de onde o rating '
        'partiu', () {
      // 7 dias: as duas do período e a de 20 dias atrás.
      expect(RatingPeriod.week.entries(history, now), history.sublist(3));
      // 30 dias: as três do período e a de 40 dias atrás.
      expect(RatingPeriod.month.entries(history, now), history.sublist(2));
      expect(RatingPeriod.quarter.entries(history, now), history.sublist(1));
      expect(RatingPeriod.year.entries(history, now), history);
    });

    test('no limite do período, a partida conta', () {
      final edge = [at(10, 1100), at(7, 1150)];
      expect(RatingPeriod.week.entries(edge, now), edge);
    });

    test('sem partida no período, nada', () {
      expect(RatingPeriod.week.entries([at(30, 1100)], now), isEmpty);
      expect(RatingPeriod.week.entries(const [], now), isEmpty);
    });
  });

  group('change', () {
    test('a diferença entre o fim e o começo do período', () {
      expect(RatingPeriod.week.change(history, now), 1230 - 1210);
      expect(RatingPeriod.month.change(history, now), 1230 - 1150);
      expect(RatingPeriod.all.change(history, now), 1230 - 1100);
    });

    test('sem dois pontos, sem variação', () {
      expect(RatingPeriod.all.change([at(0, 1200)], now), isNull);
      expect(RatingPeriod.week.change([at(30, 1100)], now), isNull);
    });
  });

  group('highestRating', () {
    test('o ponto mais alto, com a data dele', () {
      expect(highestRating(history), history.last);
      final peak = [at(10, 1300), at(5, 1250)];
      expect(highestRating(peak)?.at, peak.first.at);
    });

    test('sem histórico, nulo', () {
      expect(highestRating(const []), isNull);
    });
  });
}
