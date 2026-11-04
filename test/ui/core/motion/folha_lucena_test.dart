import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/folha_lucena.dart';

/// H-ANI-06: a folha sobe em 400 ms sobre o véu preto de 32%.
void main() {
  Widget app({bool reduzir = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(412, 917),
        disableAnimations: reduzir,
      ),
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => FolhaLucena.mostrar<void>(
                context,
                builder: (_) =>
                    const SizedBox(height: 300, child: Text('Aviso')),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<double> topoFinal(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final topo = tester.getTopLeft(find.byKey(MotionKeys.folha)).dy;
    Navigator.of(tester.element(find.byKey(MotionKeys.folha))).pop();
    await tester.pumpAndSettle();
    return topo;
  }

  testWidgets('sobe em 400 ms: no meio está abaixo, no fim na posição final', (
    tester,
  ) async {
    final fim = await topoFinal(tester);
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.getTopLeft(find.byKey(MotionKeys.folha)).dy,
      greaterThan(fim),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.byKey(MotionKeys.folha)).dy, fim);
  });

  testWidgets('o véu é preto a 32%', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final veus = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .map((b) => b.color)
        .whereType<Color>();
    expect(veus, contains(Colors.black.withValues(alpha: .32)));
  });

  testWidgets('fechar: em 400 ms a folha saiu da árvore', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byKey(MotionKeys.folha))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(MotionKeys.folha), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 201));
    expect(find.byKey(MotionKeys.folha), findsNothing);
  });

  testWidgets('movimento reduzido: já na posição final no primeiro quadro', (
    tester,
  ) async {
    final fim = await topoFinal(tester);
    await tester.pumpWidget(app(reduzir: true));
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(MotionKeys.folha)).dy, fim);
  });
}
