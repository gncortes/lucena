import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/cartao_de_plano.dart';

/// H-ANI-26: a seleção passa de um plano ao outro e o botão troca de texto.
void main() {
  const vitalicio = Key('vitalicio');
  const mensal = Key('mensal');

  Widget tela({bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: Scaffold(body: _Escolha()),
    ),
  );

  Color borda(WidgetTester tester, Key plano) =>
      (tester
                  .widget<Material>(
                    find.descendant(
                      of: find.byKey(plano),
                      matching: find.byKey(MotionKeys.contornoDoPlano),
                    ),
                  )
                  .shape!
              as RoundedRectangleBorder)
          .side
          .color;

  double ponto(WidgetTester tester, Key plano) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byKey(plano),
          matching: find.byKey(MotionKeys.pontoDoPlano),
        ),
      )
      .transform
      .storage[0];

  testWidgets('toca no mensal: as bordas cruzam em 250 ms e o botão troca', (
    tester,
  ) async {
    await tester.pumpWidget(tela());
    final context = tester.element(find.byKey(vitalicio));
    final marcada = Theme.of(context).colorScheme.primary;
    final neutraV = borda(tester, mensal);
    expect(borda(tester, vitalicio), marcada);
    expect(find.text('Comprar por R\$ 99,90'), findsOneWidget);

    await tester.tap(find.byKey(mensal));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    expect(borda(tester, mensal), allOf(isNot(neutraV), isNot(marcada)));
    expect(borda(tester, vitalicio), allOf(isNot(neutraV), isNot(marcada)));
    expect(ponto(tester, mensal), allOf(greaterThan(0), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 125));
    expect(borda(tester, mensal), marcada);
    expect(borda(tester, vitalicio), neutraV);
    expect(ponto(tester, vitalicio), 0);
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.text('Assinar por R\$ 19,90/mês'), findsOneWidget);
    expect(find.text('Comprar por R\$ 99,90'), findsNothing);
  });

  testWidgets('movimento reduzido: o estado final no primeiro quadro', (
    tester,
  ) async {
    await tester.pumpWidget(tela(reduzir: true));
    final neutra = borda(tester, mensal);
    await tester.tap(find.byKey(mensal));
    await tester.pump();
    expect(borda(tester, vitalicio), neutra);
    expect(ponto(tester, mensal), 1);
    expect(find.text('Assinar por R\$ 19,90/mês'), findsOneWidget);
    expect(find.text('Comprar por R\$ 99,90'), findsNothing);
  });
}

class _Escolha extends StatefulWidget {
  @override
  State<_Escolha> createState() => _EscolhaState();
}

class _EscolhaState extends State<_Escolha> {
  var _mensal = false;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CartaoDePlano(
        key: const Key('vitalicio'),
        selecionado: !_mensal,
        aoTocar: () => setState(() => _mensal = false),
        child: const Text('Vitalício'),
      ),
      CartaoDePlano(
        key: const Key('mensal'),
        selecionado: _mensal,
        aoTocar: () => setState(() => _mensal = true),
        child: const Text('Mensal'),
      ),
      FilledButton(
        onPressed: () {},
        child: RotuloQueCruza(
          _mensal ? 'Assinar por R\$ 19,90/mês' : 'Comprar por R\$ 99,90',
        ),
      ),
    ],
  );
}
