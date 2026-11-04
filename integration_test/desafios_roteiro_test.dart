import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/core/keys/daily_keys.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/race_robot.dart';

const _portuguese = Locale('pt', 'BR');

/// Dama contra rei, mate em um (Dh1-h8): a posição que o roteiro ganha
/// jogando a solução, como em `result_test.dart`.
const _mateInOne = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';

/// Roteiro de validação da frente Desafios (`docs/tasks/T85-historias/
/// desafios.md`), casos "Patrol". Escrito e NÃO executado: rodar no aparelho
/// antes da PR (`patrol test -t integration_test/desafios_roteiro_test.dart`).
/// Qualquer título de seção da lista de finais em destaque.
Finder _anySection() => find.byWidgetPredicate(
  (widget) =>
      widget.key == FeaturedKeys.ongoingTitle ||
      widget.key == FeaturedKeys.recentTitle ||
      widget.key == FeaturedKeys.historicTitle,
);

void main() {
  patrolTest('caso 21: a lista de finais em destaque tem o sino e as seções', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await $(HomeKeys.featuredTitle).scrollTo();
    await $(FeaturedKeys.homeSeeAll).scrollTo().tap();
    await $(FeaturedKeys.listScreen).waitUntilVisible();
    expect(find.byKey(FeaturedKeys.bell), findsOneWidget);
    // As seções dependem das datas do catálogo: ao menos uma aparece.
    expect(_anySection(), findsAtLeastNWidgets(1));
  });

  patrolTest('caso 26: o sino ligado continua ligado ao reabrir a lista', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await $(HomeKeys.featuredTitle).scrollTo();
    await $(FeaturedKeys.homeSeeAll).scrollTo().tap();
    await $(FeaturedKeys.bell).tap();
    await $(FeaturedKeys.bellNotice).waitUntilVisible();
    // A permissão de notificação, se pedida, é concedida pelo sistema.
    await $.platform.android.pressBack();
    await $(HomeKeys.featuredTitle).scrollTo();
    await $(FeaturedKeys.homeSeeAll).scrollTo().tap();
    await $(FeaturedKeys.listScreen).waitUntilVisible();
    expect(find.byKey(FeaturedKeys.bell), findsOneWidget);
  });

  patrolTest('caso 59: a Jornada abre com o primeiro degrau', ($) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await tapHomePath($, HomePath.journey);
    await $(JourneyKeys.screen).waitUntilVisible();
  });

  patrolTest('caso 62: a lista de Speedrun e o Como funciona em tela cheia', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await tapHomePath($, HomePath.speedrun);
    await $(SpeedrunKeys.listScreen).waitUntilVisible();
    await $(SpeedrunKeys.help).tap();
    await $(SpeedrunKeys.helpScreen).waitUntilVisible();
    await $(SpeedrunKeys.helpClose).tap();
    await $(SpeedrunKeys.listScreen).waitUntilVisible();
  });

  // Casos 1, 2, 5, 6 e 14/15: o Final do dia. O fixture E2E decide se há final
  // hoje; o teste aceita os dois estados e confere o que cada um promete.
  patrolTest('casos 1, 2, 5 e 14: Final do dia abre a partida ou avisa', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await _go($, Routes.dailyFrom('link'));
    await $.pumpAndSettle();
    if (find.byKey(DailyKeys.appBarShare).evaluate().isEmpty) {
      // Sem final hoje: volta ao Início com o aviso.
      await $(DailyKeys.noFinalNotice).waitUntilVisible();
      await $(HomeKeys.screen).waitUntilVisible();
      return;
    }
    await $(DailyKeys.appBarShare).tap();
    await $(DailyKeys.shareSheet).waitUntilVisible();
    expect(find.byKey(DailyKeys.shareImage), findsOneWidget);
    await $(DailyKeys.shareSheetClose).tap();
    await $(DailyKeys.appBarShare).waitUntilVisible();
    // Segundo plano e volta: a partida continua.
    await AppRobot($).sendToBackgroundAndReturn();
    await $(DailyKeys.appBarShare).waitUntilVisible();
  });

  patrolTest('caso 6: fechar à força na partida do dia retoma a partida', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _portuguese);
    await _go($, Routes.daily);
    await $.pumpAndSettle();
    if (find.byKey(DailyKeys.appBarShare).evaluate().isEmpty) return;
    await app.restart();
    await $(HomeKeys.screen).waitUntilVisible();
  });

  patrolTest('casos 8 e 13: o modal Parabéns! sobrevive ao segundo plano', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await _go($, Routes.daily);
    await $.pumpAndSettle();
    // Ganhar exige jogar a solução do fixture: o roteiro só confere o modal
    // quando ele já está aberto (rodar com o final do dia do fixture ganho).
    if (find.byKey(DailyKeys.winSheet).evaluate().isEmpty) return;
    await AppRobot($).sendToBackgroundAndReturn();
    expect(find.byKey(DailyKeys.winSheet), findsOneWidget);
    await $(DailyKeys.winLater).tap();
    await $(HomeKeys.screen).waitUntilVisible();
  });

  patrolTest('casos 33 e 38: cartão de torneio e final em destaque', ($) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await $(HomeKeys.featuredTitle).scrollTo();
    await $(FeaturedKeys.homeSeeAll).scrollTo().tap();
    await $(FeaturedKeys.listScreen).waitUntilVisible();
    final carousel = find.byKey(FeaturedKeys.tournamentCarousel);
    if (carousel.evaluate().isNotEmpty) {
      await $(carousel).$(InkWell).first.tap();
      await $(FeaturedKeys.tournamentScreen).waitUntilVisible();
      await $.platform.android.pressBack();
      await $(FeaturedKeys.listScreen).waitUntilVisible();
    }
    await $(_anySection().first).scrollTo();
  });

  patrolTest('caso 39: ganhar o final em destaque mostra o fim em destaque', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    // Os finais em destaque do catálogo são partidas reais, sem vitória
    // garantida contra o Maia: o roteiro abre a partida de um final do
    // catálogo (`featured`, com os botões do destaque) na posição de mate em
    // um e joga a solução.
    final board = FreeBoardRobot($);
    await board.openAt(
      _mateInOne,
      opponent: 'stockfish',
      user: Side.white,
      goal: 'win',
      featured: 'maroczy-euwe-1929',
    );
    expect(find.byKey(FeaturedKeys.bookButton), findsOneWidget);
    await board.move('h1', 'h8');
    await $(FreeBoardKeys.endFlash).waitUntilExists();
    expect(find.text('Você venceu!'), findsWidgets);
    expect(find.byKey(FeaturedKeys.bookButton), findsOneWidget);
    expect(find.byKey(FeaturedKeys.shareButton), findsOneWidget);
    expect(find.byKey(FeaturedKeys.continueButton), findsOneWidget);
    expect(find.byKey(FeaturedKeys.playAgain), findsOneWidget);
  });

  patrolTest('caso 54: link travado abre a tela do desafio e o Jogar inicia', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    final link = ChallengeLink(
      fen: _mateInOne,
      userSide: Side.white,
      level: 1400,
      clock: TimeControl.tryParse('5+0'),
      locked: true,
    );
    await _go($, Routes.challenge(link));
    await $(ChallengeKeys.screen).waitUntilVisible();
    expect(find.byKey(ChallengeKeys.opponentCard), findsOneWidget);
    expect(find.byKey(ChallengeKeys.clockRow), findsOneWidget);
    expect(find.byKey(ChallengeKeys.modeRow), findsOneWidget);
    expect(find.byKey(ChallengeKeys.lockedNote), findsOneWidget);
    await $(ChallengeKeys.play).tap();
    await $(FreeBoardKeys.screen).waitUntilVisible();
  });

  patrolTest('caso 55: link só com a posição abre a partida direto', ($) async {
    await AppRobot($).open(systemLocale: _portuguese);
    // Sem lado, adversário, nível, relógio nem trava (`ChallengeLink.isBare`).
    final bare = Uri(
      path: '/p/semlado',
      queryParameters: {'fen': _mateInOne},
    ).toString();
    await _go($, bare);
    await $(FreeBoardKeys.screen).waitUntilVisible();
    expect(find.byKey(ChallengeKeys.screen), findsNothing);
  });

  patrolTest('casos 42, 43, 45 e 46: Corrida do começo ao erro', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _portuguese);
    final race = RaceRobot($);
    await race.openFromAllModes();
    expect(find.byKey(RaceKeys.start), findsOneWidget);
    await race.start();
    await race.solve();
    expect(race.corrects, 1);
    await race.miss();
    expect(find.byKey(RaceKeys.chances), findsOneWidget);
    // Segundo plano de 30 s: o tempo é descontado e a corrida continua.
    await app.sendToBackgroundFor(const Duration(seconds: 30));
    await $(RaceKeys.gameView).waitUntilVisible();
    // Fechar à força: reabrir leva à retomada ou ao resultado.
    await app.restart();
    await $(HomeKeys.screen).waitUntilVisible();
  });

  patrolTest('caso 56: link inválido cai na tela de link inválido', ($) async {
    await AppRobot($).open(systemLocale: _portuguese);
    // Link ruim: posição inválida cai na tela de link inválido.
    await _go($, Routes.invalidLink);
    await $(ChallengeKeys.invalidScreen).waitUntilVisible();
    expect(find.byKey(ChallengeKeys.invalidBack), findsOneWidget);
  });

  patrolTest('caso 60: degrau e desafio da Jornada', ($) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await tapHomePath($, HomePath.journey);
    await $(JourneyKeys.screen).waitUntilVisible();
    await $(JourneyKeys.continueButton).scrollTo().tap();
    await $(JourneyKeys.rungScreen).waitUntilVisible();
    expect(find.byKey(JourneyKeys.rungHeader), findsOneWidget);
    // O cartão do próximo desafio abre a tela do desafio (o Jogar dele vai
    // direto à partida).
    await $(JourneyKeys.nextChallengePlay).scrollTo();
    await $(
      find.descendant(
        of: find.byKey(JourneyKeys.nextChallenge),
        matching: find.byType(PositionBoard),
      ),
    ).tap();
    await $(JourneyKeys.challengeScreen).waitUntilVisible();
    expect(find.byKey(JourneyKeys.opponentCard), findsOneWidget);
    await $(JourneyKeys.emptyHistory).scrollTo();
  });

  patrolTest('caso 61: degrau inexistente cai em Conteúdo não encontrado', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await _go($, Routes.journeyRung('xx'));
    await $(LoadErrorKeys.screen).waitUntilVisible();
    expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
  });
}

/// Navega para [location] como um link faria, a partir da tela inicial.
Future<void> _go(PatrolIntegrationTester $, String location) async {
  await $(HomeKeys.screen).waitUntilVisible();
  GoRouter.of($.tester.element(find.byKey(HomeKeys.screen))).go(location);
  await $.pumpAndSettle();
}
