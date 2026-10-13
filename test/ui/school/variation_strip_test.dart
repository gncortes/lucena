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

  Future<void> pumpPanel(WidgetTester tester, Size size, String text) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: Column(
            children: [
              // O tabuleiro.
              SizedBox.square(dimension: size.width),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: VariationStrip(
                    moves: const ['1.Re4', '1...Rf7', '2.Rf5', '2...Rg7'],
                    current: 2,
                    text: text,
                  ),
                ),
              ),
              VariationControls(
                canPrevious: true,
                canNext: true,
                onExit: () {},
                onBack: () {},
                onForward: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  for (final size in const [Size(412, 917), Size(360, 640)]) {
    testWidgets('texto médio aparece inteiro, sem corte, em $size', (
      tester,
    ) async {
      final text = List.filled(
        4,
        'O rei branco fica na frente do peão e a torre corta o rei preto.',
      ).join(' ');
      await pumpPanel(tester, size, text);
      final shown = tester.widget<Text>(find.text(text));
      expect(shown.maxLines, isNull);
      expect(shown.overflow, isNot(TextOverflow.ellipsis));
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(LessonKeys.variationStripScroll),
          matching: find.byType(Scrollable),
        ),
      );
      if (size.height > 800) {
        expect(scroll.position.maxScrollExtent, 0);
      }
      expect(find.byKey(LessonKeys.variationForward), findsOneWidget);
    });
  }

  testWidgets('texto longo rola e os controles continuam visíveis', (
    tester,
  ) async {
    final text = List.filled(
      40,
      'O rei branco fica na frente do peão e a torre corta o rei preto.',
    ).join(' ');
    await pumpPanel(tester, const Size(360, 640), text);
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(LessonKeys.variationStripScroll),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    final controls = tester.getRect(find.byKey(LessonKeys.variationForward));
    await tester.drag(
      find.byKey(LessonKeys.variationStripScroll),
      const Offset(0, -200),
    );
    await tester.pump();
    expect(scroll.position.pixels, greaterThan(0));
    expect(tester.getRect(find.byKey(LessonKeys.variationForward)), controls);
    expect(controls.bottom, lessThanOrEqualTo(640));
  });
}
