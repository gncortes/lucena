import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/external_page_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_purchase_service.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// Prints da passada de texto do Pilares (05/11): uma demonstração sem o
/// rótulo seco e com link novo (Malakhov × Dreev) e a fala do Morphy com o
/// contexto de quem ele é. Coletor: `tools/capture/t85_capture_server.py`
/// (`E2E_CAPTURE_URL`); conteúdo do curso em `CONTENT_URL` (porta 8791).
void main() {
  const ptBr = Locale('pt', 'BR');

  Future<void> openLesson(
    PatrolIntegrationTester $,
    String route,
    String text,
  ) async {
    final purchases = FakePurchaseRepository(
      const PurchaseState(
        pricesReady: true,
        access: PilaresAccess(kind: PilaresAccessKind.lifetime),
      ),
    );
    await AppRobot($).open(
      systemLocale: ptBr,
      lightDevice: true,
      purchases: purchases,
    );
    await $(HomeKeys.screen).waitUntilVisible();
    unawaited(
      GoRouter.of(
        $.tester.element(find.byKey(HomeKeys.screen)),
      ).push<void>(route),
    );
    await $(
      find.textContaining(text, findRichText: true),
    ).waitUntilVisible(timeout: const Duration(seconds: 60));
    await $.pump(const Duration(seconds: 3));
  }

  Key ready() => find.byKey(LessonScriptKeys.screen).evaluate().isNotEmpty
      ? LessonScriptKeys.screen
      : LessonScriptKeys.speech;

  patrolTest('Textos: demonstração sem rótulo, com o link do Malakhov', (
    $,
  ) async {
    await openLesson(
      $,
      Routes.endgameLessonScript('pilares.ab2', part: 'others2', stage: 1),
      'Malakhov',
    );
    final capture = TrainingCaptureRobot($);
    await capture.shot('TextosDemoMalakhov', ready: ready());
    await $.tester.tapOnText(find.textRange.ofSubstring('Malakhov').first);
    await $(ExternalPageKeys.sheet).waitUntilVisible();
    await $.pump(const Duration(seconds: 4));
    await capture.shot('TextosDemoMalakhovLink', ready: ExternalPageKeys.sheet);
  }, tags: ['textos-pilares']);

  patrolTest('Textos: Morphy apresentado na primeira menção', ($) async {
    await openLesson(
      $,
      Routes.endgameLessonScript('pilares.c3', part: 'rookBishopMates'),
      'Paul Morphy',
    );
    await TrainingCaptureRobot($).shot('TextosMorphyContexto', ready: ready());
  }, tags: ['textos-pilares']);
}
