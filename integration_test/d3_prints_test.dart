import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/blind/view_models/blind_game_cubit.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/core/keys/week_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/e2e_prints_fixtures.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/blind_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_details_robot.dart';
import 'robots/placement_robot.dart';
import 'robots/race_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/training_capture_robot.dart';

/// Os prints da D3 no aparelho principal (1080x2400, 420 dpi): os 3 ajustes
/// do canvas (Conta do tour, enunciado do teste de nível, "Começando"), as
/// abas da Escola e a Sua semana com conta, e o grupo do tabuleiro (Partida
/// e Corrida, em vídeo). Coletor: `tools/capture/t85_capture_server.py`
/// (`E2E_CAPTURE_URL`); roteiro em `tools/capture/t85_d3_prints.sh`.
void main() {
  const ptBr = Locale('pt', 'BR');

  Future<void> openTour(PatrolIntegrationTester $) =>
      AppRobot($).open(systemLocale: ptBr, lightDevice: true, tour: true);

  patrolTest('D3 prints: Conta do tour com as ações no pé', ($) async {
    await openTour($);
    await TourRobot($).nextUntil(TourStep.account);
    await TrainingCaptureRobot($)
        .shot('D3TourConta', ready: TourKeys.accountLater);
  });

  patrolTest('D3 prints: enunciado do teste de nível', ($) async {
    await openTour($);
    final tour = TourRobot($);
    final placement = PlacementRobot($);
    await tour.nextUntilLevel();
    await tour.takeTest();
    await tour.start(leave: false);
    await placement.expectIntro();
    await placement.start();
    await $(PlacementKeys.board).waitUntilVisible();
    await TrainingCaptureRobot($)
        .shot('D3TesteNivelPergunta', ready: PlacementKeys.board);
  });

  patrolTest('D3 prints: "Começando" no Início', ($) async {
    await openTour($);
    final tour = TourRobot($);
    // "Estou começando": o caminho zero grava o objetivo de aprender, e o
    // Início mostra "Começando" até as primeiras partidas.
    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.beginner);
    await tour.start();
    await AppRobot($).restart();
    await $(HomeKeys.ratingPending).waitUntilVisible();
    await TrainingCaptureRobot($)
        .shot('D3InicioComecando', ready: HomeKeys.ratingPending);
  });

  patrolTest('D3 prints: abas da Escola e Sua semana, com conta', ($) async {
    await AppRobot($).open(
      systemLocale: ptBr,
      lightDevice: true,
      signedIn: true,
      trainingScenario: E2ETrainingScenario.schoolDayOne,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide(escola: true);
    for (final tab in [
      CourseGuideTab.lesson,
      CourseGuideTab.goals,
      CourseGuideTab.stats,
      CourseGuideTab.catalog,
    ]) {
      if (find.byKey(CourseGuideKeys.tab(tab.name)).evaluate().isEmpty) {
        continue;
      }
      await capture.tab(tab.name);
      await capture.shot('D3EscolaAba-${tab.name}');
    }
    final router = GoRouter.of(
      $.tester.element(find.byKey(HomeKeys.screen, skipOffstage: false)),
    );
    unawaited(router.push<void>(Routes.week));
    await $.pumpAndSettle();
    await capture.shot('D3SuaSemana', ready: WeekKeys.screen);
  });

  patrolTest('D3 prints: Partida no tabuleiro livre', ($) async {
    await AppRobot($).open(systemLocale: ptBr, lightDevice: true);
    final capture = TrainingCaptureRobot($);
    final free = FreeBoardRobot($);
    await free.open();
    await capture.shot('D3TabuleiroLivre', ready: FreeBoardKeys.board);
    await capture.record(
      'D3TabuleiroLivreLance',
      () => free.move('e2', 'e4'),
      ready: FreeBoardKeys.board,
    );
  });

  patrolTest('D3 prints: Partida às cegas', ($) async {
    await AppRobot($).open(systemLocale: ptBr, lightDevice: true);
    final capture = TrainingCaptureRobot($);
    final blind = BlindRobot($);
    // startWithoutMic já abre a entrada pelo Todos os modos.
    await blind.startWithoutMic();
    await $(BlindKeys.view(BlindView.board)).tap();
    await $.pumpAndSettle();
    await capture.shot('D3AsCegasTabuleiro', ready: BlindKeys.board);
  });

  patrolTest('D3 prints: Corrida, acerto e erro', ($) async {
    await AppRobot($).open(systemLocale: ptBr, lightDevice: true);
    final capture = TrainingCaptureRobot($);
    final race = RaceRobot($);
    await race.openFromAllModes();
    await race.start();
    await capture.shot('D3Corrida', ready: RaceKeys.gameView);
    await capture.record(
      'D3CorridaAcerto',
      race.solve,
      ready: RaceKeys.gameView,
    );
    await capture.record('D3CorridaErro', race.miss, ready: RaceKeys.gameView);
  });

  patrolTest('D3 prints: Ache o lance do final em destaque', ($) async {
    await AppRobot($).open(systemLocale: ptBr, lightDevice: true);
    await $(HomeKeys.screen).waitUntilVisible();
    unawaited(
      GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
          .push<void>(Routes.featuredEndgame(e2eFindMoveFeaturedId)),
    );
    await $(FeaturedKeys.findBoard).waitUntilVisible();
    await $.pumpAndSettle();
    await TrainingCaptureRobot($)
        .shot('D3AcheOLance', ready: FeaturedKeys.findBoard);
  });

  patrolTest('D3 prints: Detalhes da partida salva', ($) async {
    await AppRobot($).open(systemLocale: ptBr, lightDevice: true);
    final id = await seedAttempt(e2eSavedGame);
    await GameDetailsRobot($).open(id);
    await TrainingCaptureRobot($)
        .shot('D3DetalhesPartida', ready: GameDetailsKeys.screen);
  });
}
