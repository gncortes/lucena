import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/config/dependencies.dart' show hideDevToolsForPrints;
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/alerts_keys.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/my_progress_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/region_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_purchase_service.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// MP4 curtos (até 10 s) das animações da D2, um por grupo do quadro H-ANI.
/// Coletor: `tools/capture/t85_capture_server.py --serial <aparelho>`.
void main() {
  hideDevToolsForPrints = true;
  const prices = {
    PilaresPlan.lifetime: r'R$ 99,90',
    PilaresPlan.monthly: r'R$ 19,90',
  };
  const demo = PurchaseState(pricesReady: true, prices: prices);

  void push(PatrolIntegrationTester $, String route) {
    final router = GoRouter.of(
      $.tester.element(find.byKey(HomeKeys.screen, skipOffstage: false)),
    );
    unawaited(router.push<void>(route));
  }

  Future<void> hold(PatrolIntegrationTester $, int ms) async {
    for (var i = 0; i < ms ~/ 50; i++) {
      await $.pump(const Duration(milliseconds: 50));
    }
  }

  patrolTest('D2 vídeo: Notificações entram em cascata', ($) async {
    await AppRobot($)
        .open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    final capture = TrainingCaptureRobot($);
    await capture.begin('d2-notificacoes-cascata');
    await hold($, 800);
    push($, Routes.alerts);
    await hold($, 2500);
    await capture.end('d2-notificacoes-cascata', ready: AlertsKeys.screen);
  }, tags: ['d2-videos']);

  patrolTest('D2 vídeo: Seu país no eixo X', ($) async {
    await AppRobot($)
        .open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    final capture = TrainingCaptureRobot($);
    await capture.begin('d2-pais-eixo-x');
    await hold($, 800);
    push($, Routes.country);
    await hold($, 1500);
    await $(RegionKeys.countryScreen).waitUntilVisible();
    Navigator.of($.tester.element(find.byKey(RegionKeys.countryScreen))).pop();
    await hold($, 1500);
    await capture.end('d2-pais-eixo-x');
  }, tags: ['d2-videos']);

  patrolTest('D2 vídeo: passos da Conta no eixo X', ($) async {
    await AppRobot($)
        .open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    push($, Routes.accountEnterFrom('perfil'));
    await $.pumpAndSettle();
    final capture = TrainingCaptureRobot($);
    await capture.begin('d2-conta-eixo-x');
    await hold($, 600);
    await $(AccountKeys.email).tap(settlePolicy: SettlePolicy.noSettle);
    await hold($, 1500);
    Navigator.of(
      $.tester.element(
        find.byKey(AccountKeys.enterScreen, skipOffstage: false),
      ),
    ).pop();
    await hold($, 1500);
    await capture.end('d2-conta-eixo-x');
  }, tags: ['d2-videos']);

  patrolTest('D2 vídeo: Seu progresso conta até o valor', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      accountInvite: true,
    );
    final capture = TrainingCaptureRobot($);
    await capture.begin('d2-progresso-contadores');
    await hold($, 800);
    push($, D2Paths.progress);
    await hold($, 2500);
    await capture.end('d2-progresso-contadores', ready: MyProgressKeys.screen);
  }, tags: ['d2-videos']);

  patrolTest('D2 vídeo: escolher o plano e a compra concluída', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      demo: true,
      purchases: FakePurchaseRepository(demo),
    );
    final capture = TrainingCaptureRobot($);
    await capture.begin('d2-compra');
    await hold($, 600);
    push($, D2Paths.offer());
    await hold($, 800);
    await $(PurchaseKeys.planMonthly)
        .scrollTo(settlePolicy: SettlePolicy.noSettle);
    await hold($, 400);
    await $(PurchaseKeys.planMonthly).tap(settlePolicy: SettlePolicy.noSettle);
    await hold($, 900);
    await $(PurchaseKeys.planLifetime).tap(settlePolicy: SettlePolicy.noSettle);
    await hold($, 900);
    push($, D2Paths.pilaresPurchaseDone);
    await hold($, 2500);
    await capture.end('d2-compra', ready: CourseUnlockedKeys.screen);
  }, tags: ['d2-videos']);
}
