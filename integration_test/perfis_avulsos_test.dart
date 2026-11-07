import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/platform_rating.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';
import 'robots/home_robot.dart';
import 'robots/placement_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/training_capture_robot.dart';

const _ptBr = Locale('pt', 'BR');

/// Dama contra rei, mate em um (Dh1-h8).
const _mateInOne = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';

/// Torre e rei contra rei: a torre vai e volta, o Maia responde de verdade.
const _rookShuffle = 'k7/8/8/8/8/8/8/4K2R w - - 0 1';

/// Mate em um com a torre (Th1-h8#, rei preto preso na oitava fileira).
const _rookMate = '1k6/8/1K6/8/8/8/8/7R w - - 0 1';

Future<void> _hold(PatrolIntegrationTester $, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await $.pump(const Duration(milliseconds: 50));
  }
}

/// Volta ao Início, como o botão Início do sistema faria.
Future<void> _goHome(PatrolIntegrationTester $) async {
  if (find.byKey(HomeKeys.screen).evaluate().isEmpty) {
    GoRouter.of($.tester.element(find.byType(Scaffold).first)).go('/');
    await $.pumpAndSettle();
  }
  await $(HomeKeys.screen).waitUntilVisible();
}

/// O botão voltar do sistema.
Future<void> _back(PatrolIntegrationTester $) async {
  await $.tester.binding.handlePopRoute();
  await $.pumpAndSettle();
}

/// Joga um mate em um contra o Maia [level] e devolve a conclusão aberta.
Future<void> _playMate(
  PatrolIntegrationTester $,
  String fen, {
  int level = 1600,
}) async {
  final board = FreeBoardRobot($);
  await board.openAt(
    fen,
    opponent: 'maia',
    level: level,
    user: Side.white,
    goal: 'win',
    position: 'basic.queen.0001',
  );
}

void main() {
  patrolTest('P3 Finais avulsos com conta e rating', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _ptBr, lightDevice: true, tour: true);
    final robot = TrainingCaptureRobot($);
    final tour = TourRobot($);
    final home = HomeRobot($);
    await robot.begin('P3Finais');

    // Tour: objetivo "Treinar finais", passos e faixa de rating.
    await robot.mark('x1_Tour');
    await _hold($);
    await tour.answerGoal(GoalPreference.train);
    await _hold($);
    for (final step in [TourStep.board, TourStep.theme, TourStep.voice]) {
      await tour.expectStep(step);
      await _hold($);
      await tour.next();
      if (step == TourStep.theme) {
        // Hesita: volta um passo e avança de novo.
        await _hold($, 1000);
        await tour.back();
        await _hold($, 1200);
        await tour.expectStep(TourStep.theme);
        await tour.next();
      }
    }
    await tour.expectStep(TourStep.level);
    await _hold($);
    await tour.chooseLevel(RatingLevel.intermediate);
    await _hold($);
    await tour.start(leave: false);
    await tour.expectStep(TourStep.region);
    await _hold($);
    await tour.next();
    await tour.expectStep(TourStep.account);
    await _hold($);
    await tour.next();
    await home.expectVisible();

    // Início e o primeiro final, pelo catálogo.
    await robot.mark('x1_Inicio');
    await _hold($, 2500);
    await robot.mark('x1_Catalogo_e_1o_final');
    final catalog = CatalogRobot($);
    await catalog.open();
    await _hold($);
    await catalog.openCategory('basic');
    await _hold($);
    await catalog.openPosition('basic.queen.0001');
    final setup = GameSetupRobot($);
    await setup.expectVisible();
    await _hold($, 2500);
    // Hesita: volta ao catálogo sem jogar e abre de novo.
    await _back($);
    await $.pumpAndSettle();
    await _hold($, 1500);
    await catalog.openPosition('basic.queen.0001');
    await setup.expectVisible();
    await _hold($, 1500);
    await setup.start();
    final board = FreeBoardRobot($);
    await board.expectVisible();
    await _hold($, 2000);
    await board.leave();
    await $.pumpAndSettle();
    await _hold($);
    await _goHome($);

    // Primeiro final vencido, resultado em 1x.
    await robot.mark('x1_Final_1_e_resultado');
    await _playMate($, _mateInOne);
    await _hold($);
    await board.move('h1', 'h8');
    await ConclusionRobot($).waitConclusion();
    await _hold($, 4000);
    await ConclusionRobot($).close();
    await home.expectVisible();

    // Finais 2 e 3 em 5x.
    await robot.mark('x5_Finais_2_e_3');
    await board.openAt(
      _rookShuffle,
      opponent: 'maia',
      level: 1400,
      user: Side.white,
      goal: 'win',
    );
    for (var move = 0; move < 3; move++) {
      final (from, to) = move.isEven ? ('h1', 'h2') : ('h2', 'h1');
      await board.move(from, to);
      await board.waitForMoves(move * 2 + 2);
    }
    await board.leave();
    await $.pumpAndSettle();
    await _goHome($);
    await _playMate($, _rookMate, level: 1400);
    await board.move('h1', 'h8');
    await ConclusionRobot($).waitConclusion();
    await _hold($, 2500);
    await ConclusionRobot($).close();
    await home.expectVisible();

    // Final do dia, no Início.
    await robot.mark('x1_Final_do_dia');
    await _hold($, 1500);
    if (find.byKey(FeaturedKeys.homeCard).evaluate().isNotEmpty) {
      await $(FeaturedKeys.homeCard).scrollTo().tap();
      await $.pumpAndSettle();
      await _hold($, 4000);
      await _back($);
      await _goHome($);
    }

    // Perfil: criar a conta e informar o rating pelo Lichess.
    await robot.mark('x1_Perfil_conta_e_rating');
    await home.openSettings();
    await _hold($);
    await ProfileRobot($).open();
    await _hold($, 2000);
    await $(ProfileKeys.createAccount).scrollTo().tap();
    await $(AccountKeys.enterScreen).waitUntilVisible();
    await _hold($, 1500);
    await $(AccountKeys.email).tap();
    await $(AccountKeys.createScreen).waitUntilVisible();
    await $(AccountKeys.emailField).enterText('gabriel@exemplo.com');
    await $(AccountKeys.passwordField).enterText('senha-segura-123');
    await _hold($, 1500);
    await $(AccountKeys.emailSubmit).tap();
    await $.pumpAndSettle();
    await _hold($, 1500);
    if (find.byKey(AccountKeys.acceptScreen).evaluate().isNotEmpty) {
      await $(AccountKeys.acceptCheck).tap();
      await _hold($, 800);
      await $(AccountKeys.acceptContinue).tap();
      await $.pumpAndSettle();
    }
    if (find.byKey(AccountKeys.dataScreen).evaluate().isNotEmpty) {
      await _hold($, 2500);
      await $(AccountKeys.dataSave).tap();
      await $.pumpAndSettle();
    }
    await _hold($, 2000);
    await $(ProfileKeys.screen).waitUntilVisible();
    e2eLichess.rating = PlatformRating(
      user: 'gabriel_xadrez',
      readAt: DateTime(2026, 11, 5),
      blitz: const ModeRating(rating: 1650, games: 240),
      rapid: const ModeRating(rating: 1700, games: 130),
    );
    await _hold($);
    await $(ProfileKeys.rowLevel).scrollTo().tap();
    await $(LevelKeys.screen).waitUntilVisible();
    await _hold($, 2000);
    // Hesita: sai de "Seu nível" sem escolher e entra de novo.
    await _back($);
    await $.pumpAndSettle();
    await _hold($, 1200);
    await $(ProfileKeys.rowLevel).scrollTo().tap();
    await $(LevelKeys.screen).waitUntilVisible();
    await _hold($);
    await $(LevelKeys.option(LevelChoice.known)).scrollTo().tap();
    await _hold($, 800);
    await $(LevelKeys.continueButton).tap();
    await $.pumpAndSettle();
    await _hold($, 1500);
    await $(LevelKeys.option(LevelChoice.lichess)).scrollTo().tap();
    await _hold($, 800);
    await $(LevelKeys.continueButton).tap();
    await $(LevelKeys.lichessScreen).waitUntilVisible();
    await _hold($, 3000);
    await $(LevelKeys.lichessUse).tap();
    await $.pumpAndSettle();
    await $(ProfileKeys.screen).waitUntilVisible();
    await _hold($, 3000);
    await robot.end('P3Finais');
  });

  patrolTest('P4 Desafio recebido por link', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _ptBr, lightDevice: true);
    final robot = TrainingCaptureRobot($);
    await robot.begin('P4DesafioLink');
    await _hold($, 1000);

    await robot.mark('x1_Abre_pelo_link');
    final link = ChallengeLink(
      fen: _mateInOne,
      userSide: Side.white,
      level: 1400,
      clock: TimeControl.tryParse('300+0'),
      locked: true,
    );
    GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
        .go(Routes.challenge(link));
    await $.pumpAndSettle();
    await _hold($, 2000);
    if (find.byKey(ChallengeKeys.setupScreen).evaluate().isNotEmpty) {
      await robot.mark('x1_Antes_do_desafio');
      await _hold($, 2500);
      await $(ChallengeKeys.setupPlay).tap();
      await $.pumpAndSettle();
    }
    await robot.mark('x1_Configuracao_do_desafio');
    await $(ChallengeKeys.screen).waitUntilVisible();
    await _hold($, 3500);
    // Hesita: sai do desafio e abre o link de novo.
    await _back($);
    await $.pumpAndSettle();
    await _hold($, 1500);
    if (find.byKey(ChallengeKeys.screen).evaluate().isEmpty) {
      GoRouter.of($.tester.element(find.byType(Scaffold).first))
          .go(Routes.challenge(link));
      await $.pumpAndSettle();
    }
    await $(ChallengeKeys.screen).waitUntilVisible();
    await _hold($, 1500);
    await $(ChallengeKeys.play).tap();
    await $(FreeBoardKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();

    await robot.mark('x1_Partida');
    await _hold($, 2000);
    await FreeBoardRobot($).move('h1', 'h8');
    await _hold($, 2500);

    await robot.mark('x1_Resultado_e_convite');
    await $(ChallengeKeys.endMeetApp).waitUntilExists();
    await _hold($, 3000);
    await $(ChallengeKeys.endMeetApp).scrollTo().tap();
    await $.pumpAndSettle();
    await _hold($, 4000);
    await robot.end('P4DesafioLink');
  });

  patrolTest('P5 Teste de nível', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _ptBr, lightDevice: true, tour: true);
    final robot = TrainingCaptureRobot($);
    final tour = TourRobot($);
    final placement = PlacementRobot($);
    await robot.begin('P5TesteNivel');

    await robot.mark('x1_Tour');
    await _hold($);
    await tour.answerGoal(GoalPreference.train);
    await _hold($);
    await tour.nextUntilLevel();
    await _hold($, 2000);
    await tour.takeTest();
    await _hold($, 1500);
    await tour.start(leave: false);
    await placement.expectIntro();

    await robot.mark('x1_Teste_de_nivel_abertura');
    await _hold($, 3000);
    // Hesita: volta do teste e reabre.
    await _back($);
    await $.pumpAndSettle();
    await _hold($, 1500);
    await tour.start(leave: false);
    await placement.expectIntro();
    await _hold($, 1500);
    await placement.start();

    await robot.mark('x1_Perguntas_1_a_3');
    for (var q = 1; q <= 20; q++) {
      if (q == 4) await robot.mark('x5_Perguntas_4_a_20');
      await $(PlacementKeys.prompt).waitUntilVisible();
      await _hold($, q <= 3 ? 2500 : 300);
      final options = find.byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> && k.value.startsWith('placement.option.');
      });
      if (options.evaluate().isNotEmpty && q % 3 != 0) {
        await $.tester.tap(options.first);
        await $.pumpAndSettle();
      } else {
        await $(PlacementKeys.dontKnow).tap();
        await $.pumpAndSettle();
      }
    }

    await robot.mark('x1_Resultado');
    await placement.expectResult();
    await _hold($, 4000);
    await placement.useLevel();
    await robot.mark('x1_Fim_do_tour_e_Inicio');
    await tour.expectStep(TourStep.region);
    await _hold($);
    await tour.leaveNextSteps();
    await HomeRobot($).expectVisible();
    await _hold($, 3500);
    await robot.end('P5TesteNivel');
  });
}
