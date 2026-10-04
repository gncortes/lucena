import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';

void main() {
  test('as faixas cobrem todos os ratings, sem buraco nem sobreposição', () {
    expect(RatingLevel.values.first.min, isNull);
    expect(RatingLevel.values.last.max, isNull);
    for (var i = 1; i < RatingLevel.values.length; i++) {
      expect(RatingLevel.values[i].min, RatingLevel.values[i - 1].max! + 1);
    }
  });

  test('o rating gravado de cada faixa cai dentro dela', () {
    for (final level in RatingLevel.values) {
      expect(RatingLevel.of(level.rating), level);
    }
  });

  test('cada rating cai na faixa certa, inclusive nas bordas', () {
    expect(RatingLevel.of(0), RatingLevel.beginner);
    expect(RatingLevel.of(999), RatingLevel.beginner);
    expect(RatingLevel.of(1000), RatingLevel.casual);
    expect(RatingLevel.of(1299), RatingLevel.casual);
    expect(RatingLevel.of(1300), RatingLevel.intermediate);
    expect(RatingLevel.of(1899), RatingLevel.advanced);
    expect(RatingLevel.of(1900), RatingLevel.expert);
    expect(RatingLevel.of(2200), RatingLevel.master);
    expect(RatingLevel.of(5000), RatingLevel.master);
  });

  test('quem ainda não escolheu entra como jogador casual', () {
    expect(const UserProfile().level, RatingLevel.casual);
    expect(const UserProfile().rating, RatingLevel.casual.rating);
  });
}
