import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/aviso_que_abre.dart';
import 'package:lucena/ui/core/motion/sucesso_da_compra.dart';

import 'entrada_helpers.dart';

/// H-ANI-27: a compra concluída e o aviso da falha.
void main() {
  Widget app(Widget corpo, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(home: Scaffold(body: corpo)),
  );

  final sucesso = SucessoDaCompra(
    titulo: const Text('Compra concluída'),
    texto: const Text('O Pilares é seu.'),
    botoes: [
      FilledButton(onPressed: () {}, child: const Text('Começar')),
      TextButton(onPressed: () {}, child: const Text('Depois')),
    ],
  );

  final falha = const Column(
    children: [
      AvisoQueAbre(
        icone: Icon(Icons.error_outline),
        child: SizedBox(height: 80, child: Text('A compra não foi feita.')),
      ),
      Text('Abaixo'),
    ],
  );

  double circulo(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(MotionKeys.circuloDaCompra))
      .transform
      .storage[0];

  double luz(WidgetTester tester, String texto) =>
      opacidadeAcima(tester, find.text(texto));

  testWidgets('sucesso: o círculo cresce, o anel some, os botões por último', (
    tester,
  ) async {
    await tester.pumpWidget(app(sucesso));
    expect(circulo(tester), closeTo(.6, .001));
    expect(find.byKey(MotionKeys.anelDaCompra), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 380));
    expect(circulo(tester), 1);
    expect(find.byKey(MotionKeys.anelDaCompra), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byKey(MotionKeys.anelDaCompra), findsNothing);

    // Os botões são os últimos a chegar à opacidade 1.
    var botoesAntes = true;
    for (var i = 0; i < 20; i++) {
      final titulo = luz(tester, 'Compra concluída');
      final texto = luz(tester, 'O Pilares é seu.');
      final botoes = [luz(tester, 'Começar'), luz(tester, 'Depois')];
      if (botoes.any((o) => o == 1) && (titulo < 1 || texto < 1)) {
        botoesAntes = false;
      }
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(botoesAntes, isTrue);
    expect(luz(tester, 'Depois'), 1);
  });

  testWidgets('falha: o aviso abre em 320 ms empurrando o conteúdo', (
    tester,
  ) async {
    await tester.pumpWidget(app(falha));
    final abaixo = tester.getTopLeft(find.text('Abaixo')).dy;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final meio = tester.getSize(find.byKey(MotionKeys.avisoQueAbre)).height;
    expect(meio, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 160));
    final cheia = tester.getSize(find.byKey(MotionKeys.avisoQueAbre)).height;
    expect(meio, lessThan(cheia));
    expect(tester.getTopLeft(find.text('Abaixo')).dy, greaterThan(abaixo));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(MotionKeys.avisoQueAbre)).height, cheia);
  });

  testWidgets('falha: o ícone pulsa uma vez a 1,3', (tester) async {
    await tester.pumpWidget(app(falha));
    await tester.pump();
    var maior = 0.0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      final s = tester
          .widget<Transform>(find.byKey(MotionKeys.iconeDoAviso))
          .transform
          .storage[0];
      if (s > maior) maior = s;
    }
    expect(maior, closeTo(1.3, .02));
    expect(
      tester
          .widget<Transform>(find.byKey(MotionKeys.iconeDoAviso))
          .transform
          .storage[0],
      1,
    );
  });

  testWidgets('movimento reduzido: estados finais no primeiro quadro', (
    tester,
  ) async {
    await tester.pumpWidget(app(sucesso, reduzir: true));
    expect(circulo(tester), 1);
    expect(find.byKey(MotionKeys.anelDaCompra), findsNothing);
    expect(luz(tester, 'Depois'), 1);

    await tester.pumpWidget(app(falha, reduzir: true));
    expect(
      tester.getSize(find.byKey(MotionKeys.avisoQueAbre)).height,
      greaterThanOrEqualTo(80),
    );
    expect(
      tester
          .widget<Transform>(find.byKey(MotionKeys.iconeDoAviso))
          .transform
          .storage[0],
      1,
    );
  });
}
