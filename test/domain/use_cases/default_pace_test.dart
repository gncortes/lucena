import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/use_cases/default_pace.dart';

void main() {
  test('sem ritmo escolhido, o do nível do jogador', () {
    const expected = {
      RatingLevel.beginner: '900+10',
      RatingLevel.casual: '600+0',
      RatingLevel.intermediate: '300+3',
      RatingLevel.advanced: '180+2',
      RatingLevel.expert: '180+0',
      RatingLevel.master: '60+0',
    };
    for (final MapEntry(key: level, value: code) in expected.entries) {
      expect(DefaultPace.of(level: level).code, code, reason: level.name);
    }
  });

  test('todo ritmo inicial é um dos ritmos do speedrun', () {
    for (final level in RatingLevel.values) {
      expect(SpeedrunPaces.all, contains(DefaultPace.forLevel(level)));
    }
  });

  test('o ritmo escolhido vence o do nível', () {
    const threeZero = TimeControl(initial: Duration(minutes: 3));
    for (final level in RatingLevel.values) {
      expect(DefaultPace.of(saved: threeZero, level: level), threeZero);
    }
  });
}
