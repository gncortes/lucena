import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/numero_que_conta.dart';

/// H-ANI-18: o número conta até o valor, em pt-BR e sem mudar de largura.
void main() {
  Widget tela(int valor, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: NumeroQueConta(valor: valor)),
    ),
  );

  String texto(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(MotionKeys.numeroQueConta),
          matching: find.byType(Text),
        ),
      )
      .data!;

  testWidgets('conta de 0 até 850 em 650 ms', (tester) async {
    await tester.pumpWidget(tela(850));
    await tester.pump(const Duration(milliseconds: 325));
    final meio = int.parse(texto(tester).replaceAll('.', ''));
    expect(meio, allOf(greaterThan(0), lessThan(850)));
    await tester.pump(const Duration(milliseconds: 325));
    expect(texto(tester), '850');
  });

  testWidgets('milhar em pt-BR', (tester) async {
    await tester.pumpWidget(tela(1267));
    await tester.pumpAndSettle();
    expect(find.text('1.267'), findsOneWidget);
  });

  testWidgets('a largura é a mesma em todos os quadros', (tester) async {
    await tester.pumpWidget(tela(850));
    final larguras = <double>{};
    for (var i = 0; i < 8; i++) {
      larguras.add(tester.getSize(find.byKey(MotionKeys.numeroQueConta)).width);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(larguras, hasLength(1));
  });

  testWidgets('mudança real: conta do valor anterior', (tester) async {
    await tester.pumpWidget(tela(850));
    await tester.pumpAndSettle();
    await tester.pumpWidget(tela(900));
    expect(texto(tester), '850');
    await tester.pump(const Duration(milliseconds: 650));
    expect(texto(tester), '900');
  });

  testWidgets('o leitor de tela lê só o valor final', (tester) async {
    await tester.pumpWidget(tela(850));
    expect(find.bySemanticsLabel('850'), findsOneWidget);
  });

  testWidgets('movimento reduzido: 850 no primeiro quadro', (tester) async {
    await tester.pumpWidget(tela(850, reduzir: true));
    expect(texto(tester), '850');
  });

  testWidgets('rating sem separador de milhar: 1200, não 1.200', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: NumeroQueConta(valor: 1200, agrupar: false),
        ),
      ),
    );
    expect(texto(tester), '1200');
  });
}
