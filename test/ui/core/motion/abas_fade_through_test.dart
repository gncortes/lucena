import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/abas_fade_through.dart';

import 'entrada_helpers.dart';

/// H-ANI-05: a troca de aba cruza o corpo e deixa a barra parada.
void main() {
  const barra = ValueKey('barra');
  const botaoFixo = ValueKey('botaoFixo');

  Widget abasDeBaixo(int aba, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(
      size: const Size(412, 800),
      disableAnimations: reduzir,
    ),
    child: MaterialApp(
      home: Scaffold(
        body: AbasFadeThrough(
          child: Center(key: ValueKey(aba), child: Text('Aba $aba')),
        ),
        bottomNavigationBar: NavigationBar(
          key: barra,
          selectedIndex: aba,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
            NavigationDestination(icon: Icon(Icons.school), label: 'Treino'),
          ],
        ),
      ),
    ),
  );

  Widget venda(int aba, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(
      size: const Size(412, 800),
      disableAnimations: reduzir,
    ),
    child: MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: 48,
              child: IndicadorQueDesliza(abas: 3, atual: aba),
            ),
            Expanded(
              child: AbasFadeThrough(
                venda: true,
                child: Center(key: ValueKey(aba), child: Text('Aba $aba')),
              ),
            ),
          ],
        ),
        bottomNavigationBar: FilledButton(
          key: botaoFixo,
          onPressed: () {},
          child: const Text('Comprar'),
        ),
      ),
    ),
  );

  /// A escala da aba: o `Transform` mais perto do texto.
  double escala(WidgetTester tester, int aba) {
    final t = find.ancestor(
      of: find.text('Aba $aba'),
      matching: find.byType(Transform),
    );
    if (t.evaluate().isEmpty) return 1;
    return tester.widget<Transform>(t.first).transform.storage[0];
  }

  double opacidade(WidgetTester tester, int aba) =>
      opacidadeAcima(tester, find.text('Aba $aba'));

  testWidgets('a aba 1 cresce de 0,92 a 1 e a barra não se mexe', (
    tester,
  ) async {
    await tester.pumpWidget(abasDeBaixo(0));
    final rect = tester.getRect(find.byKey(barra));
    await tester.pumpWidget(abasDeBaixo(1));
    for (var ms = 0; ms < 300; ms += 25) {
      expect(tester.getRect(find.byKey(barra)), rect);
      if (ms == 150) {
        expect(escala(tester, 1), allOf(greaterThan(.92), lessThan(1)));
      }
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pump();
    expect(escala(tester, 1), 1);
    expect(opacidade(tester, 1), 1);
    await tester.pumpAndSettle();
    expect(find.text('Aba 0'), findsNothing);
  });

  testWidgets('a aba de saída some em 90 ms; a nova só aparece depois', (
    tester,
  ) async {
    await tester.pumpWidget(abasDeBaixo(0));
    await tester.pumpWidget(abasDeBaixo(1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacidade(tester, 0), greaterThan(0));
    expect(opacidade(tester, 1), 0);
    await tester.pump(const Duration(milliseconds: 15));
    expect(opacidade(tester, 0), 0);
    await tester.pumpAndSettle();
  });

  testWidgets('venda: 450 ms, o indicador desliza junto e o botão fica', (
    tester,
  ) async {
    await tester.pumpWidget(venda(0));
    final botao = tester.getRect(find.byKey(botaoFixo));
    final antes = tester.getRect(find.byKey(MotionKeys.indicadorDaAba));
    await tester.pumpWidget(venda(1));
    await tester.pump(const Duration(milliseconds: 225));
    final meio = tester.getRect(find.byKey(MotionKeys.indicadorDaAba));
    expect(meio.left, greaterThan(antes.left));
    expect(meio.left, lessThan(antes.left + antes.width));
    expect(tester.getRect(find.byKey(botaoFixo)), botao);
    expect(opacidade(tester, 0), 0, reason: 'saiu em 135 ms');
    expect(opacidade(tester, 1), allOf(greaterThan(0), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 225));
    await tester.pump();
    expect(
      tester.getRect(find.byKey(MotionKeys.indicadorDaAba)).left,
      closeTo(antes.left + antes.width, .01),
    );
    expect(escala(tester, 1), 1);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('movimento reduzido: escala 1 e o indicador pula direto', (
    tester,
  ) async {
    await tester.pumpWidget(venda(0, reduzir: true));
    final antes = tester.getRect(find.byKey(MotionKeys.indicadorDaAba));
    await tester.pumpWidget(venda(1, reduzir: true));
    expect(
      tester.getRect(find.byKey(MotionKeys.indicadorDaAba)).left,
      closeTo(antes.left + antes.width, .01),
    );
    for (var ms = 0; ms <= 120; ms += 10) {
      expect(escala(tester, 1), 1);
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(opacidade(tester, 1), 1);
    await tester.pumpAndSettle();
    expect(find.text('Aba 0'), findsNothing);
  });

  testWidgets('abas de baixo com movimento reduzido: fade de 100 ms', (
    tester,
  ) async {
    await tester.pumpWidget(abasDeBaixo(0, reduzir: true));
    await tester.pumpWidget(abasDeBaixo(1, reduzir: true));
    await tester.pump(const Duration(milliseconds: 50));
    expect(escala(tester, 1), 1);
    expect(opacidade(tester, 1), allOf(greaterThan(0), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 60));
    expect(opacidade(tester, 1), 1);
  });
}
