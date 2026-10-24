import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
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

    // O problema é sorteado na faixa; o robô lê o lance certo da vez.
    expect(race.corrects, 0);
    await race.solve();
    expect(race.corrects, 1);

    // Três lances errados seguidos acabam a Corrida.
    await race.miss();
    await race.miss();
    await race.miss();
    await race.waitForResult();
    expect(find.byKey(RaceKeys.reviewMistakes), findsOneWidget);
    expect(find.byKey(RaceKeys.again), findsOneWidget);
    // A primeira Corrida: quantas faltam para o desempenho por final.
    await $(RaceKeys.diagnosisProgress).scrollTo();
    await $(NextStepsKeys.resultsInfo).scrollTo();
  });
}
