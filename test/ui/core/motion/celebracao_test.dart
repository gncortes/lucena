import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/celebracao.dart';

/// H-ANI-15: o diploma escala e o confete cai.
void main() {
  Widget tela({
    TamanhoDaCelebracao tamanho = TamanhoDaCelebracao.grande,
    bool reduzir = false,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      home: Scaffold(
        body: Celebracao(
          tamanho: tamanho,
          child: const SizedBox(
            width: 200,
            height: 120,
            child: Text('Diploma'),
          ),
        ),
      ),
    ),
  );

  double escala(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(MotionKeys.diplomaDaCelebracao))
      .transform
      .storage[0];

  PintorDoConfete confete(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(find.byKey(MotionKeys.confeteDaCelebracao))
              .painter!
          as PintorDoConfete;

  testWidgets('o diploma passa de 1 e assenta em 520 ms; o confete sai', (
    tester,
  ) async {
    await tester.pumpWidget(tela());
    expect(escala(tester), closeTo(.88, .001));
    expect(confete(tester).particulas, hasLength(40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(escala(tester), greaterThan(1));
    await tester.pump(const Duration(milliseconds: 220));
    expect(escala(tester), 1);
    expect(find.byKey(MotionKeys.confeteDaCelebracao), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 880));
    expect(find.byKey(MotionKeys.confeteDaCelebracao), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a pequena tem menos partículas', (tester) async {
    await tester.pumpWidget(tela(tamanho: TamanhoDaCelebracao.pequena));
    expect(confete(tester).particulas.length, lessThan(40));
    await tester.pumpAndSettle();
  });

  testWidgets('movimento reduzido: sem confete; fade de 100 ms', (
    tester,
  ) async {
    await tester.pumpWidget(tela(reduzir: true));
    expect(find.byKey(MotionKeys.confeteDaCelebracao), findsNothing);
    expect(escala(tester), 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester
          .widget<FadeTransition>(find.byKey(MotionKeys.fadeDaCelebracao))
          .opacity
          .value,
      1,
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
