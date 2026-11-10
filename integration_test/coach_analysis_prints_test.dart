// T87 · Prints e MP4 de todos os estados da análise de partidas, com o fake,
// para a prancha do Gabriel (docs/qa/T87-app-analise/app). Coletor no ar antes:
// python3 tools/t87_captura_5556.py docs/qa/T87-app-analise/app 8794
// e o Patrol: bash tools/t87_patrol.sh treinador_analise_prints CAPTURA=1.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_course_grants.dart';
import '../testing/fakes/fake_coach_repository.dart';
import '../testing/coach_fixtures.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';
import 'robots/coach_robot.dart';

const _new = 'lichess_DeF67890';
const _analyzing = 'lichess_GhI13579';
const _queue = 'lichess_MnO11223';

FakeCourseGrantsRepository _subscriber() => FakeCourseGrantsRepository()
  ..current = const CourseGrants(
    courses: {'treinador': CourseGrant(origin: GrantOrigin.gift)},
  );

/// A primeira lista vertical dentro de [screen] (nula se a tela não rola).
ScrollableState? _scrollable(PatrolIntegrationTester $, Key screen) {
  final everyone = find
      .descendant(
        of: find.byKey(screen).first,
        matching: find.byType(Scrollable),
        matchRoot: true,
      )
      .evaluate();
  for (final e in everyone) {
    final state = (e as StatefulElement).state;
    if (state is ScrollableState &&
        state.position.axis == Axis.vertical &&
        state.position.maxScrollExtent > 0) {
      return state;
    }
  }
  return null;
}

/// A tela inteira, um print por altura, até o fim da rolagem.
Future<void> _scrolling(
  PatrolIntegrationTester $,
  String name,
  Key screen,
) async {
  final shot = TrainingCaptureRobot($);
  for (var i = 1; i <= 6; i++) {
    await shot.shot('$name-$i', ready: screen);
    final pos = _scrollable($, screen)?.position;
    if (pos == null || pos.pixels >= pos.maxScrollExtent) break;
    pos.jumpTo((pos.pixels + 500).clamp(0, pos.maxScrollExtent));
    await $.pumpAndSettle();
  }
  _scrollable($, screen)?.position.jumpTo(0);
  await $.pumpAndSettle();
}

void main() {
  patrolTest('T87 prints: grátis, conectar a conta e Hoje sem plano', (
    $,
  ) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository(games: CoachFixtures.list());
    await app.open(systemLocale: const Locale('pt'), coach: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.openFromHome();
    await shot.shot('01-conectar-conta', ready: CoachKeys.linkAccount);
    await $(CoachKeys.linkChesscom).tap();
    await $.pumpAndSettle();
    await shot.shot('01b-conectar-usuario', ready: CoachKeys.username);
    fake.linkFailure = LinkAccountFailure.doesNotExist;
    await $(CoachKeys.username).enterText('ninguem_aqui');
    await $(CoachKeys.confirmAccount).tap();
    await $.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await $.pumpAndSettle();
    await shot.shot('01c-conectar-erro', ready: CoachKeys.accountError);
    await $(CoachKeys.username).enterText('gabriel_lucena');
    await $(CoachKeys.confirmAccount).tap();
    await $.pumpAndSettle();
    await $(CoachKeys.noPlan).waitUntilVisible();
    await _scrolling($, '03-hoje-sem-plano', CoachKeys.today);
  });

  patrolTest('T87 prints: assinante, da lista ao fim e ao resumo', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    fake.perGame(
      CoachFixtures.list()
          .firstWhere((p) => p.id == _queue)
          .copyWith(status: GameStatus.queued),
    );
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    // MP4 das animações padrão: a lista do Hoje em ordem e a troca de aba.
    await shot.begin('abas-e-listas');
    await t.openFromHome();
    await $.pump(const Duration(milliseconds: 1500));
    await t.tab(CoachKeys.tabGames);
    await $.pump(const Duration(milliseconds: 1500));
    await t.tab(CoachKeys.tabToday);
    await $.pump(const Duration(milliseconds: 1000));
    await shot.end('abas-e-listas', ready: CoachKeys.today);
    await _scrolling($, '02-hoje-com-plano', CoachKeys.today);
    await t.tab(CoachKeys.tabGames);
    await _scrolling($, '04-partidas', CoachKeys.games);

    // 6 · Analisando (com porcentagem) e 7 · Na fila (barra sem número).
    await t.openGame(_analyzing);
    await t.waitLoading();
    await shot.shot('06-analisando', ready: CoachKeys.loading);
    await $(CoachKeys.back).tap();
    await $.pumpAndSettle();
    // Na fila a barra corre sem fim: só pump, nunca pumpAndSettle.
    await $(CoachKeys.game(_queue)).scrollTo();
    await $.tester.tap(find.byKey(CoachKeys.game(_queue)));
    for (var i = 0; i < 10; i++) {
      await $.pump(const Duration(milliseconds: 200));
    }
    await shot.shot('07-na-fila', ready: CoachKeys.loading);
    await $.tester.tap(find.byKey(CoachKeys.back));
    for (var i = 0; i < 10; i++) {
      await $.pump(const Duration(milliseconds: 200));
    }

    // 5 · Partida nova e MP4 da análise até o fim dos exercícios.
    await shot.begin('analise-ate-fim');
    // A10 G2: com plano, a partida nova já pede a análise e abre a espera.
    await $(CoachKeys.game(_new)).scrollTo();
    await $.tester.tap(find.byKey(CoachKeys.game(_new)));
    await t.waitLoading();
    await $.pump(const Duration(seconds: 3));
    t.finish(fake, _new);
    await $(CoachKeys.start).waitUntilVisible();
    await $.pumpAndSettle();
    await shot.shot('05b-partida-pronta', ready: CoachKeys.start);
    await $(CoachKeys.begin).tap();
    await t.waitExercise();
    await shot.shot('10-exercicio', ready: CoachKeys.exercise);
    await t.miss();
    await $(CoachKeys.retry).waitUntilVisible();
    await $.pump(const Duration(milliseconds: 600));
    await shot.shot('11-exercicio-errou', ready: CoachKeys.exercise);
    await $(CoachKeys.retry).tap();
    await $.pumpAndSettle();
    await t.solve();
    await $(CoachKeys.next).waitUntilVisible();
    await $.pump(const Duration(milliseconds: 600));
    await shot.shot('11b-exercicio-acertou', ready: CoachKeys.exercise);
    await $(CoachKeys.next).tap();
    await $.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await t.solveAndAdvance();
    }
    await $(CoachKeys.end).waitUntilVisible();
    await $.pump(const Duration(seconds: 2));
    await shot.end('analise-ate-fim', ready: CoachKeys.end);
    await _scrolling($, '12-fim', CoachKeys.end);

    // 9 · Resumo da partida já feita, rolado até o fim.
    await $(CoachKeys.analysisEnd).tap();
    await $(CoachKeys.analysis).waitUntilVisible();
    await $.pumpAndSettle();
    await shot.shot('13-analise-completa', ready: CoachKeys.analysis);
    await $(GameDetailsKeys.tabMoves).tap();
    await $.pumpAndSettle();
    await shot.shot('13a-analise-lances', ready: CoachKeys.analysis);
    await $(GameDetailsKeys.tabEngine).tap();
    await $.pumpAndSettle();
    await shot.shot('13b-analise-motor', ready: CoachKeys.analysis);
    // Volta até a lista de partidas (ou a Home, se a pilha acabar antes).
    bool onScreen(Key k) => find.byKey(k).hitTestable().evaluate().isNotEmpty;
    for (var i = 0; i < 5; i++) {
      if (onScreen(CoachKeys.games) ||
          onScreen(CoachKeys.today) ||
          onScreen(HomeKeys.screen)) {
        break;
      }
      await $.platform.android.pressBack();
      await $.pumpAndSettle();
    }
    if (onScreen(CoachKeys.today)) {
      await t.tab(CoachKeys.tabGames);
    } else if (!onScreen(CoachKeys.games)) {
      await t.openFromHome();
      await t.tab(CoachKeys.tabGames);
    }
    await t.openGame(_new);
    await _scrolling($, '09-resumo', CoachKeys.summary);
  });

  // MP4 único do fluxo: Home → Análise → histórico com filtro → partida
  // nova → espera da análise → exercícios → fim → análise completa.
  patrolTest('T87 vídeo: fluxo inteiro', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    Future<void> pause([int ms = 1200]) => $.pump(Duration(milliseconds: ms));
    await shot.begin('fluxo-completo');
    await pause(1000);
    await t.openFromHome();
    await pause(2000);
    await t.tab(CoachKeys.tabGames);
    await pause(1500);
    await $(CoachKeys.timeControlFilter('blitz')).tap();
    await $.pumpAndSettle();
    await pause(1500);
    await $(CoachKeys.filterAll).tap();
    await $.pumpAndSettle();
    await pause(1000);
    await $(CoachKeys.game(_new)).scrollTo();
    await $.tester.tap(find.byKey(CoachKeys.game(_new)));
    await t.waitLoading();
    await pause(4000);
    t.finish(fake, _new);
    await $(CoachKeys.start).waitUntilVisible();
    await $.pumpAndSettle();
    await pause(1500);
    await $(CoachKeys.begin).tap();
    await t.waitExercise();
    await pause(1000);
    await t.miss();
    await $(CoachKeys.retry).waitUntilVisible();
    await pause(1200);
    await $(CoachKeys.retry).tap();
    await $.pumpAndSettle();
    await t.solve();
    await $(CoachKeys.next).waitUntilVisible();
    await pause(1200);
    await $(CoachKeys.next).tap();
    await $.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await t.solveAndAdvance();
    }
    await $(CoachKeys.end).waitUntilVisible();
    await pause(2500);
    await $(CoachKeys.analysisEnd).tap();
    await $(CoachKeys.analysis).waitUntilVisible();
    await $.pumpAndSettle();
    await pause(1500);
    await $(GameDetailsKeys.tabMoves).tap();
    await $.pumpAndSettle();
    await pause(1500);
    await $(GameDetailsKeys.tabEngine).tap();
    await $.pumpAndSettle();
    await pause(1500);
    await shot.end('fluxo-completo', ready: CoachKeys.analysis);
  });

  patrolTest('T87 prints: espera com frases e dica do exercício', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await $(CoachKeys.game(_new)).scrollTo();
    await $.tester.tap(find.byKey(CoachKeys.game(_new)));
    await t.waitLoading();
    await shot.begin('espera-frases');
    for (var i = 0; i < 14; i++) {
      await app.advanceTime(const Duration(seconds: 1));
      await $.pump(const Duration(milliseconds: 700));
      if (i == 1 || i == 5 || i == 9) {
        await shot.shot('06c-espera-$i', ready: CoachKeys.loading);
      }
    }
    await shot.end('espera-frases', ready: CoachKeys.loading);
    t.finish(fake, _new);
    await $(CoachKeys.start).waitUntilVisible();
    await $.pumpAndSettle();
    await $(CoachKeys.begin).tap();
    await t.waitExercise();
    await shot.begin('dica-sequencia');
    await shot.shot('10a-dica-antes', ready: CoachKeys.exercise);
    await $(CoachKeys.hint).tap();
    await $.pumpAndSettle();
    await shot.shot('10b-dica-1', ready: CoachKeys.exercise);
    await $(CoachKeys.hint).tap();
    await $.pumpAndSettle();
    await shot.shot('10c-dica-2', ready: CoachKeys.exercise);
    await shot.end('dica-sequencia', ready: CoachKeys.exercise);
  });

  patrolTest('T87 prints: erro da análise', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    fake.perGame(
      CoachFixtures.list()
          .firstWhere((p) => p.id == _analyzing)
          .copyWith(status: GameStatus.error),
    );
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_analyzing);
    await shot.shot('08-erro', ready: CoachKeys.error);
  });
}
