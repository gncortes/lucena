import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/cartao_pressionavel.dart';
import 'package:lucena/ui/core/widgets/lucena_card.dart';

/// H-ANI-20: o cartão afunda um pouco no toque.
void main() {
  var toques = 0;

  Widget app(Widget filho, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      home: Scaffold(body: Center(child: filho)),
    ),
  );

  final cartao = CartaoPressionavel(
    child: SizedBox(
      width: 200,
      height: 100,
      child: InkWell(onTap: () => toques++, child: const Text('Cartão')),
    ),
  );

  double escala(WidgetTester tester) {
    final t = find.descendant(
      of: find.byKey(MotionKeys.cartaoPressionado),
      matching: find.byType(Transform),
    );
    if (t.evaluate().isEmpty) return 1;
    return tester.widget<Transform>(t.first).transform.storage[0];
  }

  testWidgets('desce a 0,97 em 100 ms e volta em 200 ms', (tester) async {
    toques = 0;
    await tester.pumpWidget(app(cartao));
    final dedo = await tester.startGesture(
      tester.getCenter(find.text('Cartão')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(escala(tester), allOf(greaterThan(.97), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(escala(tester), closeTo(.97, .0001));
    await dedo.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(escala(tester), allOf(greaterThan(.97), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(escala(tester), 1);
    expect(toques, 1);
  });

  testWidgets('cancelar o gesto também volta a 1', (tester) async {
    await tester.pumpWidget(app(cartao));
    final dedo = await tester.startGesture(
      tester.getCenter(find.text('Cartão')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(escala(tester), closeTo(.97, .0001));
    await dedo.cancel();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(escala(tester), 1);
  });

  testWidgets('movimento reduzido: escala 1 com o dedo no cartão', (
    tester,
  ) async {
    await tester.pumpWidget(app(cartao, reduzir: true));
    final dedo = await tester.startGesture(
      tester.getCenter(find.text('Cartão')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(escala(tester), 1);
    await dedo.up();
    await tester.pump();
  });

  testWidgets('o LucenaCard com toque afunda; sem toque, não', (tester) async {
    await tester.pumpWidget(
      app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LucenaCard(onTap: () {}, child: const Text('Com toque')),
            const LucenaCard(child: Text('Sem toque')),
          ],
        ),
      ),
    );
    expect(find.byKey(MotionKeys.cartaoPressionado), findsOneWidget);
    final dedo = await tester.startGesture(
      tester.getCenter(find.text('Com toque')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(escala(tester), closeTo(.97, .0001));
    await dedo.up();
    await tester.pumpAndSettle();
  });
}
