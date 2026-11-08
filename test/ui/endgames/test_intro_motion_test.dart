import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/test_canvas_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/endgames/widgets/exercises_intro_screen.dart';

import '../../../testing/motion_expectations.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

/// H-ANI-16 na introdução do teste do capítulo (canvas `TesteIntro`): os dois
/// cartões entram em cascata na primeira vez da sessão; o Começar fica no
/// rodapé, fixo e tocável desde o início.
void main() {
  Future<void> abrir(
    WidgetTester tester, {
    EntradasVistas? vistas,
    VoidCallback? onStart,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    final tela = TestCanvasIntroPage(chapter: 2, count: 12, onStart: onStart);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: vistas == null
            ? tela
            : EntradasVistasEscopo(vistas: vistas, child: tela),
      ),
    );
  }

  for (final reduced in [false, true]) {
    testWidgets('os cartões entram em cascata (reduzido: $reduced)', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      var started = 0;
      await abrir(tester, onStart: () => started++);
      expectEntradaEmCascata(tester, itens: 2, animando: !reduced);
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.itemDaCascata(0)),
          matching: find.byKey(TestCanvasKeys.facts),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.itemDaCascata(1)),
          matching: find.byKey(ExercisesIntroKeys.tiers),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ExercisesIntroKeys.start));
      expect(started, 1);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(
        opacidadeDaParte(tester, find.byKey(MotionKeys.itemDaCascata(1))),
        1,
      );
    });
  }

  testWidgets('reabrir na mesma sessão mostra pronto', (tester) async {
    final vistas = EntradasVistas();
    await abrir(tester, vistas: vistas);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await abrir(tester, vistas: vistas);
    expectEntradaEmCascata(tester, itens: 2, animando: false);
  });
}
