import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/use_cases/rating_conversion.dart';

void main() {
  group('toLucena', () {
    test('os exemplos do canvas', () {
      expect(RatingConversion.toLucena(RatingOrigin.fide, 1450), 1650);
      expect(RatingConversion.toLucena(RatingOrigin.chesscom, 1405), 1650);
      expect(RatingConversion.toLucena(RatingOrigin.lichess, 1712), 1712);
    });

    test('CBX conta como FIDE; "não sei" fica igual', () {
      expect(RatingConversion.toLucena(RatingOrigin.cbx, 1450), 1650);
      expect(RatingConversion.toLucena(RatingOrigin.unknown, 1450), 1450);
    });

    test('nos limites de 400 e 3000', () {
      for (final origin in RatingOrigin.values) {
        final low = RatingConversion.toLucena(origin, 400);
        final high = RatingConversion.toLucena(origin, 3000);
        expect(low, inInclusiveRange(400, 3000));
        expect(high, 3000);
        expect(RatingConversion.toLucena(origin, 100), low);
        expect(RatingConversion.toLucena(origin, 3500), high);
      }
    });

    test('quem tem mais rating lá tem mais aqui', () {
      for (final origin in RatingOrigin.values) {
        var last = 0;
        for (var rating = 400; rating <= 3000; rating += 50) {
          final value = RatingConversion.toLucena(origin, rating);
          expect(value, greaterThanOrEqualTo(last));
          last = value;
        }
      }
    });
  });

  test('isValid aceita de 400 a 3000', () {
    expect(RatingConversion.isValid(399), isFalse);
    expect(RatingConversion.isValid(400), isTrue);
    expect(RatingConversion.isValid(3000), isTrue);
    expect(RatingConversion.isValid(3001), isFalse);
  });

  test('startRung arredonda para baixo, entre 1000 e 2600', () {
    expect(RatingConversion.startRung(1712), 1600);
    expect(RatingConversion.startRung(1650), 1600);
    expect(RatingConversion.startRung(1600), 1600);
    expect(RatingConversion.startRung(800), 1000);
    expect(RatingConversion.startRung(2900), 2600);
  });
}
