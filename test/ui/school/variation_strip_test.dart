import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/widgets/lesson_part_widgets.dart';

import '../../../testing/test_app.dart';

void main() {
  testWidgets('a faixa usa a notação da fala, sem "1..." no meio da linha', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(
          body: VariationStrip(
            moves: ['1.Rf4', '1...Re6', '2.Re4', '2...Rd6', '3.Rf5'],
            current: 2,
            text: '',
          ),
        ),
      ),
    );
    final text = tester
        .widget<Text>(find.byKey(LessonKeys.variationStripCurrent))
        .textSpan!
        .toPlainText()
        .replaceAll(RegExp('[\u2066\u2069]'), '');
    expect(text, '1.Rf4 Re6 2.Re4 Rd6 3.Rf5');
  });

  testWidgets('a linha que abre pelas pretas mantém o "1..."', (tester) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(
          body: VariationStrip(
            moves: ['1...Re6', '2.Re4'],
            current: 1,
            text: '',
          ),
        ),
      ),
    );
    final text = tester
        .widget<Text>(find.byKey(LessonKeys.variationStripCurrent))
        .textSpan!
        .toPlainText()
        .replaceAll(RegExp('[\u2066\u2069]'), '');
    expect(text, '1...Re6 2.Re4');
  });

  testWidgets('o rótulo de acessibilidade não leva os isolantes de direção', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(
          body: VariationStrip(
            moves: ['1.Rf4', '1...Re6', '2.Re4'],
            current: 1,
            text: '',
          ),
        ),
      ),
    );
    final label = tester
        .getSemantics(find.byKey(LessonKeys.variationStripCurrent))
        .label;
    expect(label, isNot(contains('\u2066')));
    expect(label, isNot(contains('\u2069')));
    expect(label, contains('Re6'));
    handle.dispose();
  });

  testWidgets('o trecho não repete a notação do lance que abre o texto', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(
          body: VariationStrip(
            moves: ['1.Rf4', '1...Re6', '2.Re4'],
            current: 2,
            text: '1...Re6. O rei preto vai para a frente do peão.',
          ),
        ),
      ),
    );
    expect(find.text('O rei preto vai para a frente do peão.'), findsOneWidget);
    expect(find.textContaining('1...Re6.'), findsNothing);
    expect(VariationStrip.withoutLeadingMove('2.Re4 Rd6 segue.'), 'Rd6 segue.');
    expect(
      VariationStrip.withoutLeadingMove('O rei vai a e6.'),
      'O rei vai a e6.',
    );
  });
}
