import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/journey/journey_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/blind/view_models/blind_game_cubit.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/course_preview_keys.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/core/keys/week_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/e2e_prints_fixtures.dart';
import '../testing/fakes/fake_purchase_service.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/blind_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_details_robot.dart';
import 'robots/journey_robot.dart';
import 'robots/speedrun_robot.dart';
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

  patrolTest('D3 prints: o gráfico do rating se desenha (H-ANI-19)', ($) async {
    await AppRobot($).open(systemLocale: ptBr, lightDevice: true);
    await seedRatingHistory(const [
      1000,
      1040,
      1025,
      1080,
      1110,
      1095,
      1150,
      1190,
      1170,
      1230,
      1267,
    ]);
    await $(HomeKeys.screen).waitUntilVisible();
    final capture = TrainingCaptureRobot($);
    await capture.record('D3GraficoRating', () async {
      unawaited(
        GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
            .push<void>(Routes.rating),
      );
      await $(RatingKeys.chart).waitUntilVisible();
      await $.pumpAndSettle();
    }, ready: RatingKeys.chart);
  });

  patrolTest('D3 prints: Conhecer o Pilares cresce da folha do cadeado', (
    $,
  ) async {
    // PropV2MetaSemCompraDemoCadeadoFolha → apresentação (H-ANI-04, 560 ms).
    await AppRobot($).open(
      systemLocale: ptBr,
      lightDevice: true,
      demo: true,
      trainingScenario: E2ETrainingScenario.goalsLarge,
      purchases: FakePurchaseRepository(
        const PurchaseState(
          pricesReady: true,
          prices: {
            PilaresPlan.lifetime: r'R$ 99,90',
            PilaresPlan.monthly: r'R$ 19,90',
          },
        ),
      ),
    );
    await $(HomeKeys.screen).waitUntilVisible();
    unawaited(
      GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
          .push<void>(Routes.trainingGoals(TrainingCourse.pilares.name)),
    );
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    final trancada = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            'demo.goals.lockedTile.',
          ),
    );
    await $.scrollUntilVisible(finder: trancada.first);
    await $.tester.tap(trancada.first);
    await $.pumpAndSettle();
    await $(PurchaseKeys.demoGoalsLockSheetLearn).waitUntilVisible();
    final capture = TrainingCaptureRobot($);
    await capture.record('D3CadeadoConhecerPilares', () async {
      await $.pump(const Duration(milliseconds: 600));
      await $(PurchaseKeys.demoGoalsLockSheetLearn).tap();
      await $(CoursePreviewKeys.sale).waitUntilVisible();
      await $.pumpAndSettle();
    }, ready: CoursePreviewKeys.sale);
  }, tags: ['d3-mp4', 'd3-cadeado']);

  patrolTest('D3 prints: Metas da demo com o Capítulo 1 concluído', ($) async {
    // PropV2MetaDemoFimCap1B: "Capítulo 1 concluído" no "Hoje", barra cheia e
    // o convite na seção Lição, sem o do rodapé; o botão abre a apresentação.
    await AppRobot($).open(
      systemLocale: ptBr,
      lightDevice: true,
      demo: true,
      trainingScenario: E2ETrainingScenario.goalsLarge,
      purchases: FakePurchaseRepository(
        const PurchaseState(
          pricesReady: true,
          prices: {
            PilaresPlan.lifetime: r'R$ 99,90',
            PilaresPlan.monthly: r'R$ 19,90',
          },
        ),
      ),
    );
    await $(HomeKeys.screen).waitUntilVisible();
    final capture = TrainingCaptureRobot($);
    await capture.record('D3MetaDemoCap1Concluido', () async {
      await $.pump(const Duration(milliseconds: 600));
      unawaited(
        GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
            .push<void>(Routes.trainingGoals(TrainingCourse.pilares.name)),
      );
      await $(TrainingKeys.goalsChapterDone).waitUntilVisible();
      await $.pumpAndSettle();
      await $.pump(const Duration(milliseconds: 2500));
      await $.scrollUntilVisible(
        finder: find.byKey(PurchaseKeys.demoGoalsNoLessonLearnMore),
      );
      await $.pump(const Duration(milliseconds: 1500));
      await $(PurchaseKeys.demoGoalsNoLessonLearnMore).tap();
      await $(CoursePreviewKeys.sale).waitUntilVisible();
      await $.pumpAndSettle();
      await $.pump(const Duration(milliseconds: 1000));
    }, ready: CoursePreviewKeys.sale);
  }, tags: ['d3-mp4', 'd3-meta-demo']);

  patrolTest('D3 MP4: compra na demo e a lição do Cap. 2 entra nas Metas', (
    $,
  ) async {
    // Comprou no meio do dia: o dia de hoje ganha a lição na hora, e o que
    // já estava nas metas fica.
    final purchases = FakePurchaseRepository(
      const PurchaseState(
        pricesReady: true,
        prices: {
          PilaresPlan.lifetime: r'R$ 99,90',
          PilaresPlan.monthly: r'R$ 19,90',
        },
      ),
    );
    await AppRobot($).open(
      systemLocale: ptBr,
      lightDevice: true,
      demo: true,
      trainingScenario: E2ETrainingScenario.goalsLarge,
      purchases: purchases,
    );
    await $(HomeKeys.screen).waitUntilVisible();
    final lessonGoal = find.byWidgetPredicate(
      (w) => switch (w.key) {
        ValueKey<String>(:final value) => value.startsWith(
          'training.goal.lesson.',
        ),
        _ => false,
      },
    );
    final capture = TrainingCaptureRobot($);
    await capture.record('D3MetaDemoCompraLicao', () async {
      await $.pump(const Duration(milliseconds: 600));
      unawaited(
        GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
            .push<void>(Routes.trainingGoals(TrainingCourse.pilares.name)),
      );
      await $(TrainingKeys.goalsChapterDone).waitUntilVisible();
      await $.pumpAndSettle();
      await $.pump(const Duration(milliseconds: 1500));
      await $(PurchaseKeys.demoGoalsNoLessonLearnMore).tap();
      await $(CoursePreviewKeys.sale).waitUntilVisible();
      await $.pumpAndSettle();
      await $.pump(const Duration(milliseconds: 1000));
      // A loja confirma a compra vitalícia.
      purchases.state = purchases.state.copyWith(
        access: const PilaresAccess(kind: PilaresAccessKind.lifetime),
      );
      unawaited(
        GoRouter.of($.tester.element(find.byKey(CoursePreviewKeys.sale)))
            .push<void>(D2Paths.pilaresPurchaseDone),
      );
      await $(PurchaseKeys.doneScreen).waitUntilVisible();
      await $.pumpAndSettle();
      await $.pump(const Duration(milliseconds: 1500));
      // O voltar da compra concluída leva ao Início; de lá, as Metas.
      GoRouter.of($.tester.element(find.byKey(PurchaseKeys.doneScreen)))
          .go(Routes.home);
      await $(HomeKeys.screen).waitUntilVisible();
      await $.pump(const Duration(milliseconds: 800));
      unawaited(
        GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
            .push<void>(Routes.trainingGoals(TrainingCourse.pilares.name)),
      );
      await $(lessonGoal).waitUntilVisible();
      expect(find.byKey(TrainingKeys.goalsChapterDone), findsNothing);
      await $.pumpAndSettle();
      await $.pump(const Duration(milliseconds: 2500));
    }, ready: TrainingKeys.goalsSummary);
  }, tags: ['d3-mp4', 'd3-meta-compra']);

  patrolTest(
    'D3 MP4: Jornada e Degrau, a barra enche e a contagem sobe (H-ANI-13)',
    ($) async {
      await AppRobot($).open(systemLocale: ptBr, lightDevice: true);
      await $(HomeKeys.screen).waitUntilVisible();
      // Três desafios do primeiro degrau já cumpridos: a barra tem o que encher.
      final ladder = await $.tester
          .element(find.byKey(HomeKeys.screen))
          .read<JourneyRepository>()
          .ladder();
      final rung = ladder.first;
      for (final challenge in rung.challenges.take(3)) {
        await seedAttempt(
          e2eSavedGame.copyWith(
            positionId: challenge.position.id,
            challengeId: challenge.id,
          ),
        );
      }
      final journey = JourneyRobot($);
      final capture = TrainingCaptureRobot($);
      await capture.record('D3JornadaBarra', () async {
        await $.pump(const Duration(milliseconds: 500));
        await journey.open();
        await $.pumpAndSettle();
        await $.pump(const Duration(milliseconds: 800));
      }, ready: JourneyKeys.screen);
      await capture.record('D3DegrauBarra', () async {
        await $.pump(const Duration(milliseconds: 500));
        await journey.openRung(rung.id);
        await $.pumpAndSettle();
        await $.pump(const Duration(milliseconds: 800));
      }, ready: JourneyKeys.rungScreen);
    },
    tags: ['d3-mp4'],
  );

  patrolTest(
    'D3 MP4: o tempo que sobrou conta no resumo da Maratona (H-ANI-18)',
    ($) async {
      final app = AppRobot($);
      final speedrun = SpeedrunRobot($);
      final board = FreeBoardRobot($);
      await app.open(systemLocale: ptBr, lightDevice: true);
      await speedrun.open(pace: null);
      await speedrun.chooseMode(marathon: true);
      await speedrun.choosePace('30+0');
      await speedrun.openSpeedrun('marathon.e2e.ending@30+0');
      await speedrun.start();
      final (from, to) = E2EJourneyRepository.mate;
      for (var stage = 0; stage < 3; stage++) {
        if (stage > 0) {
          await speedrun.expectNextMarathonStage(stage);
        } else {
          await speedrun.waitVersusGone();
        }
        await app.advanceTime(const Duration(seconds: 2));
        await board.move(from, to);
      }
      await $(ConclusionKeys.screen).waitUntilVisible();
      await $.pumpAndSettle();
      await speedrun.back();
      await speedrun.openHistoryScreen();
      await $.pumpAndSettle();
      await TrainingCaptureRobot($).record('D3MaratonaResumo', () async {
        await $.pump(const Duration(milliseconds: 500));
        await $(SpeedrunKeys.historyRun(0)).scrollTo().tap();
        await $(SpeedrunKeys.attemptScreen).waitUntilVisible();
        await $.pumpAndSettle();
        await $.pump(const Duration(milliseconds: 800));
      }, ready: SpeedrunKeys.attemptScreen);
    },
    tags: ['d3-mp4'],
  );

  patrolTest('D3 prints: Detalhes da partida salva', ($) async {
    await AppRobot($).open(systemLocale: ptBr, lightDevice: true);
    final id = await seedAttempt(e2eSavedGame);
    await GameDetailsRobot($).open(id);
    await TrainingCaptureRobot($)
        .shot('D3DetalhesPartida', ready: GameDetailsKeys.screen);
  });
}
