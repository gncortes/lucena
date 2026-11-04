import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/acordeao.dart';

/// H-ANI-22: a resposta abre empurrando o conteúdo; a seta gira 180°.
void main() {
  Widget app({bool reduzir = false, bool aberto = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Acordeao(
              inicialmenteAberto: aberto,
              cabecalho: const Text('Pergunta'),
              child: const SizedBox(height: 120, child: Text('Resposta')),
            ),
            const Text('Abaixo'),
          ],
        ),
      ),
    ),
  );

  double altura(WidgetTester tester) =>
      tester.getSize(find.byKey(MotionKeys.corpoDoAcordeao)).height;

  double giro(WidgetTester tester) => tester
      .widget<AnimatedRotation>(find.byKey(MotionKeys.setaDoAcordeao))
      .turns;

  testWidgets('abre em 300 ms empurrando o que está abaixo', (tester) async {
    await tester.pumpWidget(app());
    expect(altura(tester), 0);
    final abaixo = tester.getTopLeft(find.text('Abaixo')).dy;
    await tester.tap(find.text('Pergunta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(altura(tester), allOf(greaterThan(0), lessThan(120)));
    expect(tester.getTopLeft(find.text('Abaixo')).dy, greaterThan(abaixo));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(altura(tester), 120);
    expect(giro(tester), .5);
    expect(
      tester.getTopLeft(find.text('Abaixo')).dy,
      closeTo(abaixo + 120, .01),
    );
  });

  testWidgets('fecha de volta e a seta volta a 0', (tester) async {
    await tester.pumpWidget(app(aberto: true));
    expect(altura(tester), 120);
    expect(giro(tester), .5);
    await tester.tap(find.text('Pergunta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(altura(tester), allOf(greaterThan(0), lessThan(120)));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(altura(tester), 0);
    expect(giro(tester), 0);
  });

  testWidgets('o cabeçalho diz ao leitor de tela se está aberto', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(
      tester.getSemantics(find.byKey(MotionKeys.cabecalhoDoAcordeao)),
      matchesSemantics(
        isButton: true,
        hasExpandedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        label: 'Pergunta',
      ),
    );
  });

  testWidgets('movimento reduzido: aberta no primeiro quadro', (tester) async {
    await tester.pumpWidget(app(reduzir: true));
    await tester.tap(find.text('Pergunta'));
    await tester.pump();
    expect(altura(tester), 120);
    expect(giro(tester), .5);
  });
}
