import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/cartao_que_abre.dart';
import 'package:lucena/ui/core/motion/entrada_em_cascata.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';

import 'entrada_helpers.dart';

/// H-ANI-04: o cartão sem tabuleiro cresce até virar a tela que ele abre.
void main() {
  /// A tela de teste no tamanho do aparelho (412 × 800).
  void noAparelho(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(412, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  const tela = Size(412, 800);
  const destino = ValueKey('destino');

  Widget app(Widget corpo, {bool reduzir = false, EntradasVistas? vistas}) =>
      MediaQuery(
        data: MediaQueryData(size: tela, disableAnimations: reduzir),
        child: EntradasVistasEscopo(
          vistas: vistas ?? EntradasVistas(),
          child: MaterialApp(home: Scaffold(body: corpo)),
        ),
      );

  Widget cartao({
    bool venda = false,
    String rotulo = 'Abrir',
    Widget Function(BuildContext, VoidCallback)? aberto,
  }) => CartaoQueAbre(
    venda: venda,
    fechado: (context, abrir) => SizedBox(
      width: 100,
      height: 60,
      child: InkWell(onTap: abrir, child: Text(rotulo)),
    ),
    aberto: aberto ?? (context, fechar) => const SizedBox.expand(key: destino),
  );

  /// O retângulo do transform: o `Material` que recorta a tela aberta (o
  /// conteúdo dentro dele é a tela inteira encolhida num `FittedBox`).
  Rect retangulo(WidgetTester tester) => tester.getRect(
    find
        .ancestor(
          of: find.byKey(MotionKeys.cartaoQueAbre).last,
          matching: find.byType(Material),
        )
        .first,
  );

  testWidgets('o retângulo cresce entre o cartão e a tela em 450 ms', (
    tester,
  ) async {
    noAparelho(tester);
    await tester.pumpWidget(app(Center(child: cartao())));
    await tester.tap(find.text('Abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    final meio = retangulo(tester);
    expect(meio.width, allOf(greaterThan(100), lessThan(tela.width)));
    expect(meio.height, allOf(greaterThan(60), lessThan(tela.height)));
    await tester.pump(const Duration(milliseconds: 225));
    await tester.pump();
    expect(tester.getRect(find.byKey(destino)), Offset.zero & tela);
  });

  testWidgets('venda: a animação termina em 560 ms, não em 450', (
    tester,
  ) async {
    noAparelho(tester);
    await tester.pumpWidget(app(Center(child: cartao(venda: true))));
    await tester.tap(find.text('Abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 460));
    final meio = retangulo(tester);
    expect(meio.width, lessThan(tela.width));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(tester.getRect(find.byKey(destino)), Offset.zero & tela);
  });

  testWidgets('fechar volta ao cartão', (tester) async {
    noAparelho(tester);
    await tester.pumpWidget(
      app(
        Center(
          child: cartao(
            aberto: (context, fechar) => Center(
              child: TextButton(onPressed: fechar, child: const Text('Voltar')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Voltar'), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('movimento reduzido: nenhum retângulo intermediário', (
    tester,
  ) async {
    noAparelho(tester);
    await tester.pumpWidget(app(Center(child: cartao()), reduzir: true));
    await tester.tap(find.text('Abrir'));
    await tester.pump();
    for (var ms = 0; ms <= 120; ms += 10) {
      if (find.byKey(MotionKeys.cartaoQueAbre).evaluate().isNotEmpty) {
        final r = tester.getRect(find.byKey(MotionKeys.cartaoQueAbre).last);
        expect(
          r.width == 100 || r.width == tela.width,
          isTrue,
          reason: 'largura ${r.width} em $ms ms',
        );
      }
      if (find.byKey(destino).evaluate().isNotEmpty) {
        expect(tester.getRect(find.byKey(destino)), Offset.zero & tela);
      }
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(tester.getRect(find.byKey(destino)), Offset.zero & tela);
  });

  testWidgets('duas origens da venda chegam à mesma cascata, depois do '
      'transform', (tester) async {
    noAparelho(tester);
    Widget apresentacao(BuildContext context, VoidCallback fechar) =>
        const EntradaDaTela(
          id: 'PropV2CursoApresentacao',
          child: EntradaEmCascata(
            itens: [
              ItemDaCascata.titulo(Text('Pilares')),
              ItemDaCascata.texto(Text('O curso')),
              ItemDaCascata.botao(Text('Ver planos')),
            ],
          ),
        );

    Future<List<int>> ordem(String origem) async {
      await tester.pumpWidget(
        app(
          Column(
            children: [
              cartao(venda: true, rotulo: 'Demo', aberto: apresentacao),
              cartao(venda: true, rotulo: 'Anúncio', aberto: apresentacao),
            ],
          ),
        ),
      );
      await tester.tap(find.text(origem));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 560));
      await tester.pump();
      expect(
        opacidade(tester, find.byKey(MotionKeys.itemDaCascata(0)).last),
        lessThan(1),
        reason: 'a cascata começa depois do transform',
      );
      final pronto = List<int?>.filled(3, null);
      for (var ms = 0; ms <= 1200; ms += 10) {
        for (var i = 0; i < 3; i++) {
          final item = find.byKey(MotionKeys.itemDaCascata(i)).last;
          if (pronto[i] == null && opacidade(tester, item) >= 1) {
            pronto[i] = ms;
          }
        }
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpWidget(const SizedBox());
      return pronto.cast<int>();
    }

    final daDemo = await ordem('Demo');
    final doAnuncio = await ordem('Anúncio');
    expect(daDemo, doAnuncio);
    expect(daDemo[0], lessThan(daDemo[1]));
    expect(daDemo[1], lessThan(daDemo[2]));
  });
}
