import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/race_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('corrida de problemas: um acerto, três erros e o resultado', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _english);
    final race = RaceRobot($);
    await race.openFromAllModes();
    await race.start();

    // O primeiro problema é o mais fácil: a dama em g7.
    expect(race.corrects, 0);
    await race.move('a1', 'g7');
    expect(race.corrects, 1);

    // Três lances errados seguidos acabam a Corrida.
    await race.move('h1', 'h2');
    await race.move('d5', 'e5');
    await race.move('b8', 'a8');
    await race.waitForResult();
    expect(find.byKey(RaceKeys.reviewMistakes), findsOneWidget);
    expect(find.byKey(RaceKeys.again), findsOneWidget);
  });
}
