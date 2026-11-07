import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/tabuleiro_hero.dart';

/// H-ANI-02: o tabuleiro voa do cartão de 120 px até a tela de 360 px em
/// 450 ms, em linha reta, e volta no pop.
void main() {
  const tabuleiroA = ValueKey('tabuleiro A');
  const tabuleiroB = ValueKey('tabuleiro B');
  final navegador = GlobalKey<NavigatorState>();

  Widget tabuleiro(Key key, double lado) => TabuleiroHero(
    id: 'x',
    raio: lado < 200 ? 12 : 0,
    child: ColoredBox(
      key: key,
      color: Colors.brown,
      child: SizedBox.square(dimension: lado),
    ),
  );

  Widget telaB({Offset canto = const Offset(26, 200), double lado = 360}) =>
      Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: canto.dx,
              top: canto.dy,
              child: tabuleiro(tabuleiroB, lado),
            ),
          ],
        ),
      );

  Widget app({bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(
      size: const Size(412, 917),
      disableAnimations: reduzir,
    ),
    child: MaterialApp(
      navigatorKey: navegador,
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(left: 16, top: 600, child: tabuleiro(tabuleiroA, 120)),
          ],
        ),
      ),
    ),
  );

  void empurrar(Widget Function() tela) {
    final contexto = navegador.currentContext!;
    navegador.currentState!.push(
      RotaComTabuleiro.de(contexto, builder: (_) => tela()),
    );
  }

  Rect voo(WidgetTester tester) =>
      tester.getRect(find.byKey(MotionKeys.tabuleiroEmVoo));

  testWidgets('voa de 120 a 360 px em 450 ms, em linha reta', (tester) async {
    await tester.pumpWidget(app());
    final a = tester.getRect(find.byKey(tabuleiroA));
    empurrar(telaB);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    final meio = voo(tester);
    expect(meio.width, allOf(greaterThan(120), lessThan(360)));
    expect(meio.height, meio.width);
    // Os dois tabuleiros reais ficam escondidos durante o voo.
    expect(find.byKey(MotionKeys.tabuleiroEmVoo), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 225));
    // O Flutter tira o voo da sobreposição no quadro seguinte ao fim.
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(MotionKeys.tabuleiroEmVoo), findsNothing);
    expect(find.byKey(tabuleiroA), findsNothing);
    expect(find.byKey(tabuleiroB), findsOneWidget);
    final b = tester.getRect(find.byKey(tabuleiroB));
    expect(b.size, const Size.square(360));
    // Centro na reta de A até B: produto vetorial nulo.
    final ab = b.center - a.center;
    final am = meio.center - a.center;
    expect((ab.dx * am.dy - ab.dy * am.dx).abs() / ab.distance, lessThan(.5));
  });

  testWidgets('o canto vai do raio do cartão ao da tela', (tester) async {
    await tester.pumpWidget(app());
    empurrar(telaB);
    await tester.pump();
    BorderRadius raio() =>
        tester
                .widget<ClipRRect>(
                  find.descendant(
                    of: find.byKey(MotionKeys.tabuleiroEmVoo),
                    matching: find.byType(ClipRRect),
                  ),
                )
                .borderRadius
            as BorderRadius;
    await tester.pump(const Duration(milliseconds: 10));
    expect(raio().topLeft.x, closeTo(12, .5));
    await tester.pump(const Duration(milliseconds: 215));
    expect(raio().topLeft.x, allOf(greaterThan(0), lessThan(12)));
    await tester.pumpAndSettle();
  });

  testWidgets('movimento reduzido: sem voo, troca em 100 ms', (tester) async {
    await tester.pumpWidget(app(reduzir: true));
    empurrar(telaB);
    await tester.pump();
    for (var ms = 0; ms < 100; ms += 20) {
      expect(find.byKey(MotionKeys.tabuleiroEmVoo), findsNothing);
      for (final chave in [tabuleiroA, tabuleiroB]) {
        final lados = tester
            .widgetList(find.byKey(chave))
            .map((_) => tester.getSize(find.byKey(chave)).width);
        for (final lado in lados) {
          expect(lado, anyOf(120, 360));
        }
      }
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byKey(tabuleiroA), findsNothing);
    expect(tester.getSize(find.byKey(tabuleiroB)).width, 360);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('tabuleiro no mesmo lugar não voa: o retângulo não muda', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final a = tester.getRect(find.byKey(tabuleiroA));
    empurrar(() => telaB(canto: a.topLeft, lado: 120));
    await tester.pump();
    for (var ms = 0; ms <= 450; ms += 50) {
      if (find.byKey(MotionKeys.tabuleiroEmVoo).evaluate().isNotEmpty) {
        expect(voo(tester), a);
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(tabuleiroB)), a);
  });

  testWidgets('pop: o tabuleiro volta ao cartão', (tester) async {
    await tester.pumpWidget(app());
    final a = tester.getRect(find.byKey(tabuleiroA));
    empurrar(telaB);
    await tester.pumpAndSettle();
    navegador.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    expect(voo(tester).width, allOf(greaterThan(120), lessThan(360)));
    await tester.pumpAndSettle();
    expect(find.byKey(tabuleiroB), findsNothing);
    expect(tester.getRect(find.byKey(tabuleiroA)), a);
  });
}
