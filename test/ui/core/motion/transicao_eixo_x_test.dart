import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/transicao_eixo_x.dart';

import 'entrada_helpers.dart';

/// H-ANI-03: avançar e voltar num passo a passo desliza para os lados.
void main() {
  Widget tela(int passo, {bool voltar = false, bool reduzir = false}) =>
      MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 800),
          disableAnimations: reduzir,
        ),
        child: MaterialApp(
          home: Scaffold(
            body: TransicaoEixoX(
              voltar: voltar,
              child: Center(key: ValueKey(passo), child: Text('Passo $passo')),
            ),
          ),
        ),
      );

  /// Quanto o texto do passo está fora do lugar, no eixo X.
  double dx(WidgetTester tester, int passo, double centro) =>
      tester.getCenter(find.text('Passo $passo')).dx - centro;

  /// A opacidade final do passo: o produto de todos os `Opacity` acima dele.
  double opacidade(WidgetTester tester, int passo) =>
      opacidadeAcima(tester, find.text('Passo $passo'));

  testWidgets('avançar: o passo 2 vem da direita e chega em 300 ms', (
    tester,
  ) async {
    await tester.pumpWidget(tela(1));
    final centro = tester.getCenter(find.text('Passo 1')).dx;
    await tester.pumpWidget(tela(2));
    await tester.pump(const Duration(milliseconds: 150));
    expect(dx(tester, 2, centro), greaterThan(0));
    expect(opacidade(tester, 2), lessThan(1));
    expect(dx(tester, 1, centro), lessThanOrEqualTo(0));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(dx(tester, 2, centro), 0);
    expect(opacidade(tester, 2), 1);
    await tester.pumpAndSettle();
    expect(find.text('Passo 1'), findsNothing);
  });

  testWidgets('a saída some em 90 ms; a entrada só aparece depois', (
    tester,
  ) async {
    await tester.pumpWidget(tela(1));
    await tester.pumpWidget(tela(2));
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacidade(tester, 1), greaterThan(0));
    expect(opacidade(tester, 2), 0);
    await tester.pump(const Duration(milliseconds: 15));
    expect(opacidade(tester, 1), 0);
    await tester.pumpAndSettle();
  });

  testWidgets('voltar: o passo 1 vem da esquerda e o 2 sai pela direita', (
    tester,
  ) async {
    await tester.pumpWidget(tela(2));
    final centro = tester.getCenter(find.text('Passo 2')).dx;
    await tester.pumpWidget(tela(1, voltar: true));
    await tester.pump(const Duration(milliseconds: 150));
    expect(dx(tester, 1, centro), lessThan(0));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(dx(tester, 1, centro), 0);
  });

  testWidgets('voltar: o passo que sai desliza para a direita', (tester) async {
    await tester.pumpWidget(tela(2));
    final centro = tester.getCenter(find.text('Passo 2')).dx;
    await tester.pumpWidget(tela(1, voltar: true));
    await tester.pump(const Duration(milliseconds: 50));
    expect(dx(tester, 2, centro), greaterThan(0));
    await tester.pumpAndSettle();
  });

  testWidgets('movimento reduzido: só fade, dx = 0 em todos os quadros', (
    tester,
  ) async {
    await tester.pumpWidget(tela(1, reduzir: true));
    final centro = tester.getCenter(find.text('Passo 1')).dx;
    await tester.pumpWidget(tela(2, reduzir: true));
    for (var ms = 0; ms <= 120; ms += 10) {
      expect(dx(tester, 2, centro), 0);
      if (find.text('Passo 1').evaluate().isNotEmpty) {
        expect(dx(tester, 1, centro), 0);
      }
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(opacidade(tester, 2), 1);
    await tester.pumpAndSettle();
    expect(find.text('Passo 1'), findsNothing);
  });
}
