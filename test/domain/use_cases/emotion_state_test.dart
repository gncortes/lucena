import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/use_cases/emotion_state.dart';
import 'package:lucena/domain/use_cases/game_events.dart';

void main() {
  Emotion of(List<int> scores) => EmotionRules.of(TalkMemory(scores: scores));

  test('sem avaliações, calmo', () {
    expect(EmotionRules.of(TalkMemory.empty), Emotion.calm);
  });

  test('estava ganhando e foi perdendo é diferente de sempre mal', () {
    final sliding = of([300, 250, 150, 50, -50, -150]);
    final alwaysWorse = of([-200, -200, -200, -200, -200, -200]);
    expect(sliding, Emotion.frustrated);
    expect(alwaysWorse, Emotion.nervous);
    expect(sliding, isNot(alwaysWorse));
  });

  test('perdido e parado é triste; perdido e piorando, nervoso', () {
    expect(of([-800, -800, -800, -800]), Emotion.sad);
    expect(of([-500, -600, -700, -800]), Emotion.nervous);
  });

  test('ganhando com calma é confiante; ganhando aos saltos, feliz', () {
    expect(of([600, 600, 600, 600]), Emotion.confident);
    expect(of([400, 750, 400, 750, 400, 750]), Emotion.happy);
  });

  test('um pouco melhor, brincalhão', () {
    expect(of([150, 150, 150]), Emotion.playful);
  });

  test('salto grande no último lance surpreende', () {
    expect(of([0, 0, 500]), Emotion.surprised);
  });

  test('igual e agitado é concentrado; igual e parado, calmo', () {
    expect(of([-150, 150, -150, 150, -150, 150]), Emotion.focused);
    expect(of([0, 10, 0]), Emotion.calm);
  });

  test('só os últimos 6 lances contam', () {
    expect(
      of([-900, -900, -900, 600, 600, 600, 600, 600, 600]),
      Emotion.confident,
    );
  });
}
