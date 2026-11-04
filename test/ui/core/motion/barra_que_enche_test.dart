import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/barra_que_enche.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';

/// H-ANI-13: a barra enche em 700 ms; numa mudança real, sai do valor
/// anterior; reentrar na tela não repete.
void main() {
  Widget tela(double valor, {bool reduzir = false, EntradasVistas? vistas}) {
    final barra = EntradaDaTela(
      id: 'PropV1TreinoCatalogo',
      child: BarraQueEnche(valor: valor),
    );
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduzir),
        child: Scaffold(
          body: vistas == null
              ? barra
              : EntradasVistasEscopo(vistas: vistas, child: barra),
        ),
      ),
    );
  }

  double lido(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(MotionKeys.barraQueEnche),
          matching: find.byType(LinearProgressIndicator),
        ),
      )
      .value!;

  testWidgets('enche de 0 até o valor em 700 ms', (tester) async {
    await tester.pumpWidget(tela(.6));
    expect(lido(tester), 0);
    await tester.pump(const Duration(milliseconds: 350));
    expect(lido(tester), allOf(greaterThan(0), lessThan(.6)));
    await tester.pump(const Duration(milliseconds: 350));
    expect(lido(tester), .6);
  });

  testWidgets('mudança real: sai do valor anterior, não de 0', (tester) async {
    await tester.pumpWidget(tela(.6));
    await tester.pumpAndSettle();
    await tester.pumpWidget(tela(.8));
    expect(lido(tester), .6);
    await tester.pump(const Duration(milliseconds: 350));
    expect(lido(tester), allOf(greaterThan(.6), lessThan(.8)));
    await tester.pump(const Duration(milliseconds: 350));
    expect(lido(tester), .8);
  });

  testWidgets('reentrar na mesma tela: já no valor final', (tester) async {
    final vistas = EntradasVistas();
    await tester.pumpWidget(tela(.6, vistas: vistas));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(tela(.6, vistas: vistas));
    expect(lido(tester), .6);
  });

  testWidgets('movimento reduzido: o valor final no primeiro quadro', (
    tester,
  ) async {
    await tester.pumpWidget(tela(.6, reduzir: true));
    expect(lido(tester), .6);
    await tester.pumpWidget(tela(.8, reduzir: true));
    expect(lido(tester), .8);
  });
}
