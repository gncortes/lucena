import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/ui/core/keys/ads_keys.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/course_preview_keys.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/lesson_finished_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_purchase_service.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/pilares_lesson_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/training_capture_robot.dart';

/// Vídeos por perfil (T85-videos-perfis): P6 aluno do Pilares e P7 quem está
/// na demonstração. Coletor: tools/capture/t85_capture_server.py.
void main() {
  const ptBr = Locale('pt', 'BR');
  const prices = {
    PilaresPlan.lifetime: r'R$ 99,90',
    PilaresPlan.monthly: r'R$ 19,90',
  };

  Future<void> hold(PatrolIntegrationTester $, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 50; i++) {
      await $.pump(const Duration(milliseconds: 50));
    }
  }

  /// Toca em [key] se ele estiver na tela; devolve se tocou.
  Future<bool> tapIf(PatrolIntegrationTester $, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) return false;
    await $.tester.ensureVisible(finder.first);
    await $.pump(const Duration(milliseconds: 300));
    await $.tester.tap(finder.first);
    await $.pump(const Duration(milliseconds: 400));
    await $.pumpAndSettle();
    return true;
  }

  Future<void> back(PatrolIntegrationTester $) async {
    final button = find.byType(BackButton);
    if (button.evaluate().isNotEmpty) {
      await $.tester.tap(button.first);
    } else {
      await $.tester.pageBack();
    }
    await $.pumpAndSettle();
  }

  Future<void> fling(PatrolIntegrationTester $, Key scroll, double dy) async {
    await $.tester.fling(find.byKey(scroll), Offset(0, dy), 800);
    await $.pumpAndSettle();
  }

  patrolTest('P7 demonstração do Pilares', ($) async {
    final purchases = FakePurchaseRepository(
      const PurchaseState(pricesReady: true, prices: prices),
    );
    await AppRobot($).open(
      systemLocale: ptBr,
      lightDevice: true,
      tour: true,
      demo: true,
      trainingScenario: E2ETrainingScenario.welcome,
      purchases: purchases,
    );
    final capture = TrainingCaptureRobot($);
    final tour = TourRobot($);
    await capture.begin('P7DemoPilares');
    await capture.mark('x1_Tour');
    await hold($);
    // Hesita: marca "Aprender a jogar", muda de ideia para "Melhorar o jogo".
    await $(GoalKeys.option(GoalPreference.learn)).tap();
    await hold($, 1200);
    await tour.answerGoal();
    await hold($);
    await tour.expectStep(TourStep.board);
    await tour.next();
    await hold($, 1200);
    await tour.back();
    await hold($, 1000);
    await tour.nextUntilLevel();
    await hold($);
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start();
    await $(HomeKeys.pillarsButton).waitUntilVisible();
    await capture.mark('x1_Inicio_e_venda_do_curso');
    await hold($, 2500);
    await $(HomeKeys.pillarsButton).tap();
    await $(CoursePreviewKeys.sale).waitUntilVisible();
    await $.pumpAndSettle();
    await hold($, 2500);
    await fling($, CoursePreviewKeys.saleScroll, -500);
    await hold($, 1500);
    await tapIf($, CoursePreviewKeys.tab(1));
    await hold($, 1500);
    await fling($, CoursePreviewKeys.saleScroll, -500);
    await hold($, 1500);
    // Volta ao Início sem comprar e entra de novo.
    await back($);
    await $(HomeKeys.pillarsButton).waitUntilVisible();
    await hold($, 1500);
    await $(HomeKeys.pillarsButton).tap();
    await $(CoursePreviewKeys.sale).waitUntilVisible();
    await hold($, 1500);
    unawaited(
      GoRouter.of($.tester.element(find.byKey(CoursePreviewKeys.sale)))
          .push<void>(D2Paths.plan(origin: 'destino')),
    );
    await $(PurchaseKeys.planSaleScreen).waitUntilVisible();
    await $.pumpAndSettle();
    await hold($, 3000);
    await capture.mark('x1_Demonstracao_Catalogo');
    await $(PurchaseKeys.planSaleStart).tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await hold($, 3000);
    // Abre a 1ª lição (aviso do anúncio) e sai.
    final lesson = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            'courseGuide.chapter.lesson.',
          ),
    );
    await $.tester.tap(lesson.first);
    await $.pumpAndSettle();
    await hold($, 2500);
    if (find.byKey(AdsKeys.noticeSheet).evaluate().isNotEmpty) {
      await $(AdsKeys.demoAdNoticeLater).tap();
      await $.pumpAndSettle();
      await hold($, 1500);
    }
    // Toca no capítulo trancado.
    await tapIf($, PurchaseKeys.demoCatalogLockedChapter(2));
    await hold($, 2500);
    if (find.byKey(AdsKeys.lockedSheet).evaluate().isNotEmpty) {
      await $(AdsKeys.demoLockedSheetLater).tap();
      await $.pumpAndSettle();
      await hold($, 1000);
    }
    await capture.mark('x1_Abas_da_demonstracao');
    for (final tab in ['goals', 'guide', 'stats', 'lesson']) {
      await capture.tab(tab);
      await hold($, 2500);
      await tapIf($, PurchaseKeys.demoGuideWeeks);
      await hold($, 1500);
      if (find.byKey(CourseGuideKeys.screen).evaluate().isEmpty) {
        await back($);
        await hold($, 1000);
      }
    }
    // Decide comprar: capítulo trancado -> Comprar o curso -> oferta.
    await capture.tab('catalog');
    await hold($, 1500);
    final tappedChapter = await tapIf(
      $,
      PurchaseKeys.demoCatalogLockedChapter(3),
    );
    await hold($, 1500);
    await capture.mark('x1_Oferta_e_compra');
    final tappedBuy = await tapIf($, AdsKeys.demoLockedSheetBuy);
    debugPrint('P7 capitulo=$tappedChapter comprar=$tappedBuy');
    await $(PurchaseKeys.offerScreen).waitUntilVisible();
    await $.pumpAndSettle();
    await hold($, 3000);
    await tapIf($, PurchaseKeys.planMonthly);
    await hold($, 1500);
    await tapIf($, PurchaseKeys.planLifetime);
    await hold($, 1500);
    await tapIf($, PurchaseKeys.buy);
    await hold($, 1500);
    purchases.state = purchases.state.copyWith(
      access: const PilaresAccess(kind: PilaresAccessKind.lifetime),
    );
    unawaited(
      GoRouter.of($.tester.element(find.byKey(PurchaseKeys.offerScreen)))
          .push<void>(D2Paths.pilaresPurchaseDone),
    );
    await $(CourseUnlockedKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await hold($, 3500);
    await capture.mark('x1_Primeira_tela_de_aluno');
    await tapIf($, CourseUnlockedKeys.action);
    await hold($, 4000);
    await capture.end('P7DemoPilares');
  });

  Finder goalTiles(String kind) => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('training.goal.$kind.'),
  );

  String refOf(Finder tile, String kind) =>
      (tile.evaluate().first.widget.key! as ValueKey<String>).value.substring(
        'training.goal.$kind.'.length,
      );

  patrolTest('P6 aluno do Pilares', tags: ['p6'], ($) async {
    final purchases = FakePurchaseRepository(
      const PurchaseState(pricesReady: true, prices: prices),
    );
    await AppRobot($).open(
      systemLocale: ptBr,
      lightDevice: true,
      tour: true,
      trainingScenario: E2ETrainingScenario.welcome,
      purchases: purchases,
    );
    final capture = TrainingCaptureRobot($);
    final tour = TourRobot($);
    await capture.begin('P6Pilares');
    await capture.mark('x1_Tour');
    await hold($);
    await tour.answerGoal();
    await hold($);
    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start();
    await $(HomeKeys.pillarsButton).waitUntilVisible();
    await capture.mark('x1_Compra_do_curso');
    await hold($, 2000);
    await $(HomeKeys.pillarsButton).tap();
    await $(CoursePreviewKeys.sale).waitUntilVisible();
    await hold($, 2500);
    await fling($, CoursePreviewKeys.saleScroll, -600);
    await hold($, 1500);
    await $(CoursePreviewKeys.buy).scrollTo().tap();
    await $(PurchaseKeys.offerScreen).waitUntilVisible();
    await $.pumpAndSettle();
    await hold($, 2500);
    await tapIf($, PurchaseKeys.planLifetime);
    await tapIf($, PurchaseKeys.buy);
    await hold($, 1500);
    purchases.state = purchases.state.copyWith(
      access: const PilaresAccess(kind: PilaresAccessKind.lifetime),
    );
    unawaited(
      GoRouter.of($.tester.element(find.byKey(PurchaseKeys.offerScreen)))
          .push<void>(D2Paths.pilaresPurchaseDone),
    );
    await $(CourseUnlockedKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await hold($, 3000);
    await capture.mark('x1_Guia_e_plano');
    await tapIf($, CourseUnlockedKeys.action);
    await hold($, 3500);
    await $.tester.tap(find.byType(BackButton).first);
    await $.pumpAndSettle();
    await hold($, 2500);
    await $(SettingsKeys.pilaresTrainingTile).scrollTo().tap();
    await $(CourseGuideKeys.continueButton).waitUntilVisible();
    await hold($, 3000);
    await $(CourseGuideKeys.continueButton).tap();
    await $(TrainingKeys.planScreen).waitUntilVisible();
    await hold($, 2000);
    await $(TrainingKeys.planChip(15)).tap();
    await hold($, 1000);
    await $(TrainingKeys.planChip(30)).tap();
    await hold($, 1500);
    await $(TrainingKeys.planSave).scrollTo().tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await hold($, 2500);
    await capture.mark('x1_Metas_do_dia');
    await capture.tab('goals');
    await hold($, 3000);
    // Primeira lição inteira.
    final first = goalTiles('lesson');
    final firstRef = refOf(first, 'lesson');
    await $.tester.ensureVisible(first.first);
    await $.tester.tap(first.first);
    await $(LessonScriptKeys.board).waitUntilVisible();
    await capture.mark('x1_Primeira_licao');
    await hold($, 2500);
    await PilaresLessonRobot($).playLesson(
      firstRef,
      // O gravador do emulador para em 180 s: a gravação segue em outra.
      onPractice: () async {
        await capture.end('P6Pilares');
        await capture.begin('P6PilaresB');
        await capture.mark('x5_Primeira_licao_pratica');
      },
    );
    await capture.mark('x1_Fim_da_licao');
    await hold($, 3000);
    await hold($, 2500);
    await tapIf($, LessonFinishedKeys.back);
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await hold($, 3000);
    await capture.mark('x1_Estatisticas');
    await capture.tab('stats');
    await hold($, 3500);
    await capture.end('P6PilaresB');
    await capture.begin('P6PilaresC');
    await capture.mark('x1_Dobrar_a_meta');
    // Tudo feito por hoje: dobra a meta, olha o catálogo e abre outra lição.
    await capture.tab('goals');
    await hold($, 2500);
    await tapIf($, TrainingKeys.doubleButton);
    await hold($, 2000);
    await capture.tab('catalog');
    await hold($, 2500);
    await capture.mark('x5_Outra_licao');
    await $.tester.ensureVisible(
      find.byKey(CourseGuideKeys.chapterLesson('pilares.c1.doubleAttack')),
    );
    await $.tester.tap(
      find.byKey(CourseGuideKeys.chapterLesson('pilares.c1.doubleAttack')),
    );
    await $(LessonScriptKeys.board).waitUntilVisible();
    await PilaresLessonRobot($).playLesson('pilares.c1.doubleAttack');
    await hold($, 1500);
    await tapIf($, LessonFinishedKeys.back);
    await hold($, 1500);
    // Teste do capítulo: abre, olha e sai (resolvê-lo não cabe nesta gravação).
    await capture.mark('x1_Teste_do_capitulo');
    await capture.tab('catalog');
    await hold($, 1500);
    await tapIf($, CourseGuideKeys.chapterLesson('pilares.c1'));
    await hold($, 4000);
    await back($);
    await hold($, 2000);
    await capture.end('P6PilaresC');
  });
}
