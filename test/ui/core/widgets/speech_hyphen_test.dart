import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';

import '../../../../testing/test_app.dart';

void main() {
  test('só o hífen entre letras vira o não separável', () {
    expect(SpeechText.noBreak('casas-chave'), 'casas‑chave');
    expect(SpeechText.noBreak('rei-dama e f5-f6'), 'rei‑dama e f5-f6');
    expect(SpeechText.noBreak('Ré - Rei'), 'Ré - Rei');
  });

  testWidgets('"casas-chave" não quebra no hífen', (tester) async {
    const style = TextStyle(fontSize: 10);
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              // "aa casas-" cabe (90) e "aa casas-chave" não (140): com o
              // hífen comum, "chave" desceria sozinha.
              width: 120,
              child: SpeechText(text: 'aa casas-chave', style: style),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(SpeechText),
        matching: find.byType(RichText),
      ),
    );
    final shown = rich.text.toPlainText();
    expect(shown, 'aa casas‑chave');
    final painter = TextPainter(
      text: rich.text,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    addTearDown(painter.dispose);
    // A palavra composta desce inteira para a segunda linha.
    final casas = painter.getOffsetForCaret(
      const TextPosition(offset: 3),
      Rect.zero,
    );
    expect(casas.dx, closeTo(0, 1));
    expect(casas.dy, greaterThan(0));
  });
}
