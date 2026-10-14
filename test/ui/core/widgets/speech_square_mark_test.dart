import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('a casa entre colchetes vira negrito, sem os colchetes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(
          body: SpeechText(
            text: 'O rei vai para [c6]. Sua vez.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('[', findRichText: true), findsNothing);
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(SpeechText),
        matching: find.byType(RichText),
      ),
    );
    final spans = <TextSpan>[];
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    final square = spans.singleWhere((span) => span.text == 'c6');
    expect(square.style?.fontWeight, FontWeight.w700);
    expect(
      SpeechText.plain('Vá a [c6].', mainLine: '', showAnswer: ''),
      'Vá a c6.',
    );
  });
}
