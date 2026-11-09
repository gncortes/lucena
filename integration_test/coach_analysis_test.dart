import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:lucena/ui/coach/view_models/coach_exercise_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_course_grants.dart';
import '../testing/fakes/fake_coach_repository.dart';
import '../testing/coach_fixtures.dart';
import 'robots/app_robot.dart';
import 'robots/coach_robot.dart';

// Treinador de partidas (T87, frente app-análise): as três pessoas do brief
// (grátis sem conta, assinante no Lichess, assinante no chess.com) e os
// erros do servidor, com Voltar do sistema e da seta, segundo plano e
// fechar à força no meio da espera, do exercício e da pontuação.
const _new = 'lichess_DeF67890';
const _analyzing = 'lichess_GhI13579';
const _loss = 'lichess_JkL24680';

FakeCourseGrantsRepository _subscriber() => FakeCourseGrantsRepository()
  ..current = const CourseGrants(
    courses: {'treinador': CourseGrant(origin: GrantOrigin.gift)},
  );

void main() {
  patrolTest('grátis sem conta: liga o Lichess (erros antes), vê o plano e '
      'a cota leva à venda', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final fake = FakeCoachRepository(games: CoachFixtures.list());
    await app.open(coach: fake);
    await t.openFromHome();
    // Canvas DLigarConta: a barra das abas já aparece no passo de ligar.
    t.wait(CoachKeys.linkAccount);

    // A conta não existe.
    fake.linkFailure = LinkAccountFailure.doesNotExist;
    await t.link(CoachKeys.linkLichess, 'ninguem_aqui');
    t.wait(CoachKeys.accountError);

    // Sem internet (ou o Lichess fora do ar).
    fake.linkFailure = LinkAccountFailure.noResponse;
    await $(CoachKeys.confirmAccount).tap();
    await $.pumpAndSettle();
    t.wait(CoachKeys.accountError);

    // A conta do Lucena sem o direito: o botão do plano aparece.
    fake.linkFailure = LinkAccountFailure.noPlan;
    await $(CoachKeys.confirmAccount).tap();
    await $.pumpAndSettle();
    t.wait(CoachKeys.discoverPlan);

    // Troca de site e volta ao Lichess: agora liga.
    await $(CoachKeys.switchSite).tap();
    await $.pumpAndSettle();
    await t.link(CoachKeys.linkLichess, ' gabriel_lucena ');
    expect(fake.links.last, (Platform.lichess, 'gabriel_lucena'));
    await $(CoachKeys.tabToday).waitUntilVisible();
    t.wait(CoachKeys.noPlan);

    // A cota da semana acabou: "Analisar" leva à venda; Voltar devolve.
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_new);
    fake
      ..analyzeFailure = 'permission-denied'
      ..analyzeReason = 'cota';
    await $(CoachKeys.begin).tap();
    await $.pumpAndSettle();
    t.hasNot(CoachKeys.start);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.wait(CoachKeys.start);

    // Seta e Voltar do sistema até a tela inicial.
    await $(CoachKeys.back).tap();
    await $.pumpAndSettle();
    t.wait(CoachKeys.games);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    expect(find.byKey(HomeKeys.analysisButton), findsOneWidget);
  });

  patrolTest('assinante no Lichess: espera com segundo plano e fechar à '
      'força, exercícios com erro e Voltar no meio, pontuação e análise', (
    $,
  ) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final fake = FakeCoachRepository.withData();
    await app.open(coach: fake, courseGrants: _subscriber());
    await t.openFromHome();
    t.wait(CoachKeys.lastGame);
    t.hasNot(CoachKeys.noPlan);

    // Pede a análise de uma partida nova: a espera.
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_new);
    await $(CoachKeys.begin).tap();
    await t.waitLoading();
    expect(fake.analysisRequests.single, (_new, false));

    // Segundo plano no meio da espera: continua esperando.
    await app.sendToBackgroundFor(const Duration(seconds: 40));
    await t.waitLoading();

    // Voltar do sistema na espera: a lista.
    await $.platform.android.pressBack();
    await $.pump(const Duration(seconds: 1));
    t.wait(CoachKeys.games);

    // "Me avise" pede o aviso e também volta à lista.
    await t.openGame(_new);
    await t.waitLoading();
    await $(CoachKeys.notifyMe).tap();
    await $.pump(const Duration(seconds: 1));
    expect(fake.analysisRequests.last, (_new, true));
    t.wait(CoachKeys.games);

    // Fechar à força na espera: a partida segue "analisando".
    await t.openGame(_new);
    await t.waitLoading();
    await app.restart();
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_new);
    await t.waitLoading();

    // O servidor termina: a tela troca sozinha para os exercícios.
    t.finish(fake, _new);
    await $(CoachKeys.start).waitUntilVisible();
    await $.pumpAndSettle();
    await $(CoachKeys.begin).tap();
    await t.waitExercise();

    // Erra o primeiro, tenta de novo e acerta.
    await t.miss();
    await $(CoachKeys.retry).waitUntilVisible();
    expect(t.phase, ExerciseStep.missed);
    await $(CoachKeys.retry).tap();
    await $.pumpAndSettle();
    expect(t.phase, ExerciseStep.playing);
    await t.solveAndAdvance();
    expect(t.index, 1);

    // Voltar do sistema no meio do segundo: a partida mostra "Continuar".
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.wait(CoachKeys.start);

    // Segundo plano no exercício e fechar à força: volta ao segundo.
    await $(CoachKeys.begin).tap();
    await t.waitExercise();
    expect(t.index, 1);
    await app.sendToBackgroundFor(const Duration(minutes: 5));
    await t.waitExercise();
    expect(t.index, 1);
    await app.restart();
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_new);
    await $(CoachKeys.begin).tap();
    await t.waitExercise();
    expect(t.index, 1);

    // Seta no meio do exercício também volta à partida.
    await $(CoachKeys.back).tap();
    await $.pumpAndSettle();
    t.wait(CoachKeys.start);
    await $(CoachKeys.begin).tap();
    await t.waitExercise();

    // Os três que faltam, até a pontuação.
    await t.solveAndAdvance();
    await t.solveAndAdvance();
    await t.solveAndAdvance();
    await $(CoachKeys.end).waitUntilVisible();
    t.wait(CoachKeys.endNote);

    // Segundo plano e fechar à força na pontuação: a partida vai ao resumo.
    await app.sendToBackgroundFor(const Duration(minutes: 1));
    t.wait(CoachKeys.end);
    await $(CoachKeys.analysisEnd).tap();
    await $(CoachKeys.analysis).waitUntilVisible();
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    await app.restart();
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_new);
    t.wait(CoachKeys.summary);
  });

  patrolTest('assinante no chess.com: filtros, resumo, posição-chave e '
      'análise completa', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final fake = FakeCoachRepository.withData()
      ..currentAccount = const CoachAccount(
        platform: Platform.chesscom,
        username: 'gabriel_cc',
      );
    await fake.saveProgress(
      CoachFixtures.idTiago,
      const GameProgress(remoteDone: 4, remoteCorrect: 3, remotePoints: 30),
    );
    await app.open(coach: fake, courseGrants: _subscriber());
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);

    await $(CoachKeys.timeControlFilter('blitz')).tap();
    await $.pumpAndSettle();
    t.wait(CoachKeys.game(_analyzing));
    t.hasNot(CoachKeys.game(_new));
    await $(CoachKeys.filterAll).tap();
    await $(CoachKeys.resultFilter('derrota')).tap();
    await $.pumpAndSettle();
    t.wait(CoachKeys.game(_loss));
    t.hasNot(CoachKeys.game(_new));
    await $(CoachKeys.filterAll).tap();
    await $.pumpAndSettle();

    // Partida já feita: abre no resumo.
    await t.openGame(CoachFixtures.idTiago);
    t.wait(CoachKeys.summary);
    await $(CoachKeys.keyPosition(1)).scrollTo().tap();
    await $(CoachKeys.analysis).waitUntilVisible();
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.wait(CoachKeys.summary);
    await $(CoachKeys.analysisSummary).scrollTo().tap();
    await $(CoachKeys.analysis).waitUntilVisible();
    await $.platform.android.pressBack();
    await $.pumpAndSettle();

    // Refazer abre os exercícios do começo.
    await $(CoachKeys.redo).scrollTo().tap();
    await t.waitExercise();
    expect(t.index, 0);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.wait(CoachKeys.summary);
  });

  patrolTest('erros: análise com erro no servidor, pedido sem rede e partida '
      'que sumiu', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final fake = FakeCoachRepository.withData();
    fake.perGame(
      CoachFixtures.list()
          .firstWhere((p) => p.id == _analyzing)
          .copyWith(status: GameStatus.error),
    );
    await app.open(coach: fake, courseGrants: _subscriber());
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_analyzing);
    t.wait(CoachKeys.error);

    // "Tentar de novo" sem rede: avisa e fica no erro.
    fake.analyzeFailure = 'unavailable';
    await $(CoachKeys.errorRetry).tap();
    await $.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    t.wait(CoachKeys.error);

    // Com rede: a espera.
    fake.analyzeFailure = null;
    await $(CoachKeys.errorRetry).tap();
    await t.waitLoading();
    await $.platform.android.pressBack();
    await $.pumpAndSettle();

    // A partida some do servidor com a tela aberta.
    await t.openGame(_loss);
    fake.currentGames = [
      for (final p in CoachFixtures.list())
        if (p.id != _loss) p,
    ];
    await $.pumpAndSettle();
    t.hasNot(CoachKeys.start);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.wait(CoachKeys.games);
    t.hasNot(CoachKeys.game(_loss));
  });
}
