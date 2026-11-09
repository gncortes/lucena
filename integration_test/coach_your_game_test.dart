import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/coach_your_game_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_coach_repository.dart';
import '../testing/coach_fixtures.dart';
import '../testing/coach_your_game_fixtures.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/your_game_robot.dart';

/// T87: a aba Seu jogo do Treinador de partidas e o que sai dela (teoria,
/// partidas-modelo, Pilares e Metas de hoje). As partidas vêm do fake: o
/// aparelho nunca fala com o Lichess.
FakeCoachRepository _coach() => FakeCoachRepository(
  account: CoachFixtures.account,
  games: YourGameFixtures.games(),
  stats: YourGameFixtures.stats(),
  modelGamesByEco: {
    'B12': [const ModelGame(source: 'torneio', title: 'Carlsen x Caruana')],
  },
);

void main() {
  patrolTest('o resumo e o ritmo escolhido voltam depois de fechar o app', (
    $,
  ) async {
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    await app.open(systemLocale: const Locale('pt'), coach: _coach());
    await yourGame.open();
    await yourGame.expectSummary();
    yourGame.expectBase('Últimas 60 partidas do Lichess');

    await yourGame.pickTimeControl('blitz');
    yourGame.expectBase('Últimas 20 partidas do Lichess');

    await app.restart();
    await yourGame.open();
    yourGame.expectBase('Últimas 20 partidas do Lichess');

    await yourGame.openTheoryFromFocus();
    await yourGame.backBySystem(YourGameKeys.tab);
  });

  patrolTest('do foco à teoria e às partidas-modelo, com segundo plano', (
    $,
  ) async {
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    final coach = _coach();
    await app.open(systemLocale: const Locale('pt'), coach: coach);
    await yourGame.open();
    await yourGame.openTheoryFromFocus();
    await yourGame.pickCandidate('Nd7');

    await app.sendToBackgroundAndReturn();
    await $(YourGameKeys.theoryLine).waitUntilVisible();

    await yourGame.openModelGames();
    await yourGame.expectModelGame(0);
    await yourGame.enableModelGamesNotice();
    expect(coach.modelGamesNotices, [true]);

    await yourGame.backByArrow(YourGameKeys.theoryScreen);
    await yourGame.backByArrow(YourGameKeys.tab);
  });

  patrolTest('sem o curso: o foco leva às partes travadas e à oferta', (
    $,
  ) async {
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      demo: true,
      coach: _coach(),
    );
    await yourGame.open();
    await yourGame.openCourseFromFocus();
    await yourGame.expectPilaresLocked();
    await yourGame.discoverPilares();

    await yourGame.backByArrow(YourGameKeys.pilaresScreen);
    await yourGame.backByArrow(YourGameKeys.tab);
  });

  patrolTest('com o curso: o foco leva às Metas de hoje com a parte', (
    $,
  ) async {
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    // Com o plano já escolhido (sem plano, as Metas ainda não existem).
    await app.open(
      systemLocale: const Locale('pt'),
      coach: _coach(),
      trainingScenario: E2ETrainingScenario.large,
    );
    await yourGame.open();
    await yourGame.openCourseFromFocus();
    await yourGame.expectGoalsWithHighlight();
    await yourGame.backByArrow(YourGameKeys.tab, arrow: CourseGuideKeys.back);
  });
}
