import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/survey/widgets/survey_parts.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/motion_expectations.dart';
import '../../../testing/test_app.dart';

/// H-ANI-25 no "Obrigado" da Opinião (e do envio de opinião): o Viktor
/// entra e o botão desliza por último, já aceitando toque.
void main() {
  const backKey = Key('back');
  const partes = ['viktor', 'botoes'];

  Future<int Function()> abrir(
    WidgetTester tester, {
    EntradasVistas? vistas,
  }) async {
    var back = 0;
    final tela = ViktorThanks(
      title: 'Opinião',
      text: 'Obrigado.',
      backLabel: 'Voltar',
      onBack: () => back++,
      viktor: FakeCharacterRepository.viktor,
      closeKey: const Key('close'),
      backKey: backKey,
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: vistas == null
            ? tela
            : EntradasVistasEscopo(vistas: vistas, child: tela),
      ),
    );
    return () => back;
  }

  for (final reduced in [false, true]) {
    testWidgets('Viktor e o botão por último (reduzido: $reduced)', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final back = await abrir(tester);
      expectEntradaDeResultado(tester, partes: partes, animando: !reduced);
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.parteDoResultado('botoes')),
          matching: find.byKey(backKey),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(
        opacidadeDaParte(
          tester,
          find.byKey(MotionKeys.parteDoResultado('botoes')),
        ),
        1,
      );
      await tester.tap(find.byKey(backKey));
      expect(back(), 1);
      await tester.pumpAndSettle();
    });
  }

  testWidgets('reabrir na mesma sessão mostra pronto', (tester) async {
    final vistas = EntradasVistas();
    await abrir(tester, vistas: vistas);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await abrir(tester, vistas: vistas);
    expectEntradaDeResultado(tester, partes: partes, animando: false);
    await tester.pumpAndSettle();
  });
}
