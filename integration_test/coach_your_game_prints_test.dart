// T87 · Prints da aba Seu jogo e das telas que saem dela, para o qa-telas
// (docs/qa/T87-app-seu-jogo/app). Coletor no ar antes:
// python3 tools/capture/t85_capture_server.py --serial emulator-5558
//   --output docs/qa/T87-app-seu-jogo --port 8796
// e o Patrol com --dart-define=E2E_CAPTURE_URL=http://10.0.2.2:8796.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/routing/frentes/coach_your_game_routes.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:lucena/ui/core/keys/coach_your_game_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_coach_repository.dart';
import '../testing/coach_fixtures.dart';
import '../testing/coach_your_game_fixtures.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/your_game_robot.dart';
import 'robots/training_capture_robot.dart';

FakeCoachRepository _coach() => FakeCoachRepository(
  account: CoachFixtures.account,
  games: YourGameFixtures.games(),
  stats: YourGameFixtures.stats(),
  modelGamesByEco: {
    'B12': [
      const ModelGame(
        source: 'torneio',
        title: 'Silva x Moreira',
        subtitle: 'Aberto de São Paulo 2024 · o mesmo 5...c5 que você jogou',
        url: 'https://lichess.org/study/exemplo1',
      ),
      const ModelGame(
        source: 'torneio',
        title: 'Costa x Pereira',
        subtitle:
            'Torneio de Curitiba 2023 · as pretas jogam 5...c5 e trocam em d4',
        url: 'https://lichess.org/study/exemplo2',
      ),
    ],
  },
);

/// O servidor fora do ar: a lista de partidas não chega.
class _CoachWithError extends FakeCoachRepository {
  _CoachWithError() : super(account: CoachFixtures.account);

  @override
  Stream<List<CoachGame>> games() => Stream.error(StateError('sem servidor'));
}

/// A aba inteira, uma tela por print (rola até o fim).
Future<void> _wholeTab(PatrolIntegrationTester $, String name) async {
  final shot = TrainingCaptureRobot($);
  final scrollableArea = find.byType(Scrollable).first;
  for (var i = 1; i <= 8; i++) {
    await shot.shot('$name-$i', ready: YourGameKeys.tab);
    final pos = $.tester.state<ScrollableState>(scrollableArea).position;
    if (pos.pixels >= pos.maxScrollExtent) break;
    await $.tester.drag(scrollableArea, const Offset(0, -600));
    await $.pumpAndSettle();
  }
  // De volta ao alto: o scrollTo do Patrol só desce.
  $.tester.state<ScrollableState>(scrollableArea).position.jumpTo(0);
  await $.pumpAndSettle();
}

void main() {
  patrolTest('T87 prints: aba, teoria e partidas-modelo', ($) async {
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    final shot = TrainingCaptureRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      coach: _coach(),
      trainingScenario: E2ETrainingScenario.large,
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await yourGame.open();
    await yourGame.expectSummary();
    await _wholeTab($, '01-aba');

    await yourGame.openTheoryFromFocus();
    await shot.shot('02-teoria', ready: YourGameKeys.theoryScreen);
    await yourGame.pickCandidate('Nd7');
    await shot.shot('03-teoria-linha', ready: YourGameKeys.theoryScreen);
    await yourGame.openModelGames();
    await shot.shot('04-modelos', ready: YourGameKeys.modelGamesScreen);
    await yourGame.backByArrow(YourGameKeys.theoryScreen);
    await yourGame.backByArrow(YourGameKeys.tab);

    await yourGame.openCourseFromFocus();
    await yourGame.expectGoalsWithHighlight();
    await shot.shot('05-metas-destaque', ready: YourGameKeys.goalsHighlight);
  });

  patrolTest('T87 prints: sem o curso, Pilares travado', ($) async {
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    final shot = TrainingCaptureRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      demo: true,
      coach: _coach(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await yourGame.open();
    await yourGame.openCourseFromFocus();
    await yourGame.expectPilaresLocked();
    // As partes e a oferta cabem numa tela só (411×914).
    await $(YourGameKeys.pilaresDiscover).scrollTo();
    await shot.shot('06-pilares-oferta', ready: YourGameKeys.pilaresScreen);
  });

  patrolTest('T87 prints: estilo, tema e a posição abrindo a análise', (
    $,
  ) async {
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    final shot = TrainingCaptureRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      demo: true,
      coach: _coach(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await yourGame.open();
    await $(YourGameKeys.style).scrollTo().tap();
    await $(YourGameKeys.styleScreen).waitUntilVisible();
    await shot.shot('08-estilo', ready: YourGameKeys.styleScreen);
    await yourGame.backByArrow(YourGameKeys.tab);

    await $(YourGameKeys.motif('garfo')).scrollTo().tap();
    await $(YourGameKeys.motifScreen).waitUntilVisible();
    await shot.shot('09-tema', ready: YourGameKeys.motifScreen);
    await shot.record(
      '10-tema-analise',
      () => $(YourGameKeys.motifPosition(0)).tap(),
      ready: CoachKeys.analysis,
    );
    await shot.shot('10-tema-analise', ready: CoachKeys.analysis);
  });

  patrolTest('T87 prints: aba sem partidas', ($) async {
    final shot = TrainingCaptureRobot($);
    await AppRobot($).open(
      systemLocale: const Locale('pt'),
      demo: true,
      coach: FakeCoachRepository(account: CoachFixtures.account),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    final context = $.tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(YourGamePaths.yourGame));
    // O centro do vazio é espaço em branco: existe, mas não é "visível" para o Patrol.
    await $(YourGameKeys.empty).waitUntilExists();
    await $.pumpAndSettle();
    await shot.shot('11-vazio', ready: YourGameKeys.screen);
  });

  patrolTest('T87 prints: aba com erro', ($) async {
    final shot = TrainingCaptureRobot($);
    await AppRobot($).open(
      systemLocale: const Locale('pt'),
      demo: true,
      coach: _CoachWithError(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    final context = $.tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(YourGamePaths.yourGame));
    await $(YourGameKeys.error).waitUntilVisible();
    await shot.shot('12-erro', ready: YourGameKeys.error);
  });
}
