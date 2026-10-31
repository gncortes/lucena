import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';

void main() {
  test(
    'Canvas excerpt fits by source word metrics and preserves full input',
    () {
      const source =
          'O cavalo de c6 não pode sair: atrás dele, na mesma diagonal, '
          'está o rei. Quando a peça de trás é o rei, a cravada é absoluta e o lance '
          'do cavalo nem é legal. Quando é a dama ou uma torre, a peça cravada pode sair, '
          'mas entrega material. Por isso a peça cravada vira alvo: ataque-a de novo, '
          'de preferência com um peão.';
      final fit = CanvasSpeechLayout.fit(text: source, width: 340, lines: 4);
      expect(fit.truncated, isTrue);
      expect(fit.fontSize, 13);
      expect(fit.text.endsWith('torre, a peça'), isTrue);
      expect(source.endsWith('de preferência com um peão.'), isTrue);
    },
  );

  test('short excerpt retains authored markup and font size', () {
    const source = 'Toque em [c6].';
    final fit = CanvasSpeechLayout.fit(text: source, width: 340, lines: 4);
    expect(fit.text, source);
    expect(fit.fontSize, 15);
    expect(fit.truncated, isFalse);
  });
}
