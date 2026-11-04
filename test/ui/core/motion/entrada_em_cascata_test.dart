import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entrada_em_cascata.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/numero_que_conta.dart';

import 'entrada_helpers.dart';

/// H-ANI-16: título, 2 parágrafos, número, selo e botão entram em ordem
/// estrita em até 1,2 s, só na primeira entrada da tela.
void main() {
  const botao = ValueKey('botao');
  var toques = 0;

  final itens = [
    const ItemDaCascata.titulo(Text('Título')),
    const ItemDaCascata.texto(Text('Parágrafo 1')),
    const ItemDaCascata.texto(Text('Parágrafo 2')),
    const ItemDaCascata.numero(NumeroQueConta(valor: 105)),
    const ItemDaCascata.selo(Icon(Icons.verified)),
    ItemDaCascata.botao(
      FilledButton(
        key: botao,
        onPressed: () => toques++,
        child: const Text('Ok'),
      ),
    ),
  ];

  Widget tela({
    bool reduzir = false,
    EntradasVistas? vistas,
    bool mostrar = true,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      home: EntradasVistasEscopo(
        vistas: vistas ?? EntradasVistas(),
        child: Scaffold(
          body: mostrar
              ? EntradaDaTela(
                  id: 'PropV1TreinoAjuda',
                  child: EntradaEmCascata(itens: itens),
                )
              : const SizedBox(),
        ),
      ),
    ),
  );

  Finder item(int i) => find.byKey(MotionKeys.itemDaCascata(i));

  String numero(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(MotionKeys.numeroQueConta),
          matching: find.byType(Text),
        ),
      )
      .data!;

  testWidgets('cada item fica pronto antes do seguinte; tudo em 1,2 s', (
    tester,
  ) async {
    await tester.pumpWidget(tela());
    final pronto = List<int?>.filled(itens.length, null);
    for (var ms = 0; ms <= 1200; ms += 10) {
      for (var i = 0; i < itens.length; i++) {
        if (pronto[i] == null && opacidade(tester, item(i)) >= 1) {
          pronto[i] = ms;
        }
      }
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(pronto, everyElement(isNotNull));
    for (var i = 1; i < itens.length; i++) {
      expect(pronto[i]!, greaterThan(pronto[i - 1]!), reason: 'item $i');
    }
    for (var i = 0; i < itens.length; i++) {
      expect(opacidade(tester, item(i)), 1);
      expect(subida(tester, item(i)), 0);
    }
    expect(numero(tester), '105');
  });

  testWidgets('o título sobe 14 px e o texto 10 px; o selo escala de 0,6', (
    tester,
  ) async {
    await tester.pumpWidget(tela());
    expect(subida(tester, item(0)), closeTo(14, .01));
    expect(subida(tester, item(1)), closeTo(10, .01));
    expect(escala(tester, item(4)), closeTo(.6, .01));
    expect(opacidade(tester, item(5)), 0);
    await tester.pumpAndSettle();
  });

  testWidgets('o número só começa a contar na vez dele', (tester) async {
    await tester.pumpWidget(tela());
    final inicio = EntradaEmCascata.horarios(
      itens.map((i) => i.tipo).toList(),
    )[3].inicio;
    await tester.pump(inicio - const Duration(milliseconds: 10));
    expect(numero(tester), '0');
    await tester.pump(const Duration(milliseconds: 320));
    expect(int.parse(numero(tester)), greaterThan(0));
    await tester.pumpAndSettle();
    expect(numero(tester), '105');
  });

  testWidgets('o botão aceita toque em 50 ms', (tester) async {
    toques = 0;
    await tester.pumpWidget(tela());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(botao), warnIfMissed: false);
    expect(toques, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('voltar à tela na sessão: tudo pronto no primeiro quadro', (
    tester,
  ) async {
    final vistas = EntradasVistas();
    await tester.pumpWidget(tela(vistas: vistas));
    await tester.pumpAndSettle();
    await tester.pumpWidget(tela(vistas: vistas, mostrar: false));
    await tester.pumpWidget(tela(vistas: vistas));
    for (var i = 0; i < itens.length; i++) {
      expect(opacidade(tester, item(i)), 1);
      expect(subida(tester, item(i)), 0);
    }
    expect(numero(tester), '105');
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('movimento reduzido: tudo pronto e o número em 105', (
    tester,
  ) async {
    await tester.pumpWidget(tela(reduzir: true));
    for (var i = 0; i < itens.length; i++) {
      expect(opacidade(tester, item(i)), 1);
      expect(subida(tester, item(i)), 0);
    }
    expect(numero(tester), '105');
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('o intervalo encolhe com muitos itens e o total fica em 1,2 s', () {
    final poucos = EntradaEmCascata.horarios([
      TipoNaCascata.titulo,
      TipoNaCascata.texto,
      TipoNaCascata.botao,
    ]);
    expect(poucos[1].inicio, const Duration(milliseconds: 70));
    final muitos = EntradaEmCascata.horarios([
      TipoNaCascata.titulo,
      for (var i = 0; i < 20; i++) TipoNaCascata.texto,
      TipoNaCascata.botao,
    ]);
    expect(
      muitos.last.inicio + muitos.last.duracao,
      lessThanOrEqualTo(const Duration(milliseconds: 1200)),
    );
    expect(muitos[1].inicio, lessThan(const Duration(milliseconds: 70)));
  });
}
