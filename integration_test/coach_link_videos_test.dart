// T87 · Vídeos dos cenários que o coach_scenario_videos_test não cobre: conectar
// a conta (Lichess pelo login de lá, chess.com pelo nome) e a aba Seu jogo.
// Coletor no ar antes (tools/t87_captura_5556.py, porta 8794) e:
// bash tools/t87_patrol.sh coach_link_videos CAPTURA=1
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:lucena/ui/core/keys/coach_your_game_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_coach_repository.dart';
import '../testing/coach_fixtures.dart';
import '../testing/coach_your_game_fixtures.dart';
import 'robots/app_robot.dart';
import 'robots/coach_robot.dart';
import 'robots/training_capture_robot.dart';
import 'robots/your_game_robot.dart';

/// Pausa sem `pumpAndSettle`, para o vídeo mostrar a tela.
Future<void> _pause(PatrolIntegrationTester $, [int ms = 1500]) async {
  for (var t = 0; t < ms; t += 100) {
    await $.pump(const Duration(milliseconds: 100));
  }
}

FakeCoachRepository _yourGame() => FakeCoachRepository(
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
    ],
  },
);

void main() {
  patrolTest('L1 conectar o Lichess: abre o login do Lichess', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository(games: CoachFixtures.list());
    await app.open(systemLocale: const Locale('pt'), coach: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('L1-conectar-lichess');
    await t.openFromHome();
    await $(CoachKeys.linkAccount).waitUntilVisible();
    await _pause($);
    // O toque já abre o login de verdade (PKCE) no navegador do aparelho;
    // o vídeo termina na página de autorização, sem entrar com conta nenhuma.
    await $(CoachKeys.linkLichess).tap();
    await $.tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 6)),
    );
    await shot.end('L1-conectar-lichess');
  });

  patrolTest('L2 conectar o chess.com: nome errado, nome certo, grátis', (
    $,
  ) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository(games: CoachFixtures.list());
    await app.open(systemLocale: const Locale('pt'), coach: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('L2-conectar-chesscom');
    await t.openFromHome();
    await $(CoachKeys.linkAccount).waitUntilVisible();
    await _pause($);
    await $(CoachKeys.linkChesscom).tap();
    await $.pumpAndSettle();
    fake.linkFailure = LinkAccountFailure.doesNotExist;
    await $(CoachKeys.username).enterText('ninguem_aqui');
    await _pause($, 800);
    await $(CoachKeys.confirmAccount).tap();
    await $.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await $.pumpAndSettle();
    await $(CoachKeys.accountError).waitUntilVisible();
    await _pause($, 2500);
    fake.linkFailure = null;
    await $(CoachKeys.username).enterText('gabriel_lucena');
    await _pause($, 800);
    await $(CoachKeys.confirmAccount).tap();
    await $.pumpAndSettle();
    await $(CoachKeys.noPlan).waitUntilVisible();
    await _pause($, 3000);
    await $(CoachKeys.noPlan).scrollTo();
    await _pause($, 3000);
    await shot.end('L2-conectar-chesscom', ready: CoachKeys.today);
  });

  patrolTest('S1 Seu jogo: resumo, teoria, partidas-modelo e tema', ($) async {
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    final shot = TrainingCaptureRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      demo: true,
      coach: _yourGame(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('S1-seu-jogo');
    await yourGame.open();
    await yourGame.expectSummary();
    await _pause($, 2500);
    final area = find.byType(Scrollable).first;
    for (var i = 0; i < 3; i++) {
      await $.tester.drag(area, const Offset(0, -500));
      await $.pumpAndSettle();
      await _pause($, 1500);
    }
    $.tester.state<ScrollableState>(area).position.jumpTo(0);
    await $.pumpAndSettle();
    await yourGame.openTheoryFromFocus();
    await _pause($, 2500);
    await yourGame.pickCandidate('Nd7');
    await _pause($, 2000);
    await yourGame.openModelGames();
    await _pause($, 2500);
    await yourGame.backByArrow(YourGameKeys.theoryScreen);
    await yourGame.backByArrow(YourGameKeys.tab);
    await $(YourGameKeys.motif('garfo')).scrollTo().tap();
    await $(YourGameKeys.motifScreen).waitUntilVisible();
    await _pause($, 2500);
    await $(YourGameKeys.motifPosition(0)).tap();
    await $(CoachKeys.analysis).waitUntilVisible();
    await _pause($, 3000);
    await shot.end('S1-seu-jogo', ready: CoachKeys.analysis);
  });
}
