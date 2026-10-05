import 'dart:math' as math;

import '../models/character.dart';
import 'game_events.dart';

/// A emoção do personagem, da média dos últimos lances. Assim "estava
/// ganhando e foi perdendo" é diferente de "sempre esteve mal".
abstract final class EmotionRules {
  /// Quantas avaliações recentes entram na conta.
  static const window = 6;

  /// Um salto de avaliação deste tamanho num lance surpreende.
  static const surprise = 400;

  /// A emoção para a [memory] atual.
  static Emotion of(TalkMemory memory) {
    final all = memory.scores;
    if (all.isEmpty) return Emotion.calm;
    final s = all.length > window ? all.sublist(all.length - window) : all;

    final confidence =
        s.map((v) => _tanh(v / 400)).reduce((a, b) => a + b) / s.length;
    final trend = _tanh((s.last - s.first) / 300);
    var steps = 0.0;
    for (var i = 1; i < s.length; i++) {
      steps += (s[i] - s[i - 1]).abs();
    }
    final tension = s.length < 2
        ? 0.0
        : (steps / (s.length - 1) / 300).clamp(0.0, 1.0);
    final lastStep = s.length < 2 ? 0 : (s.last - s[s.length - 2]).abs();

    if (lastStep >= surprise) return Emotion.surprised;
    if (trend <= -0.5 && confidence > -0.2) return Emotion.frustrated;
    if (confidence >= 0.6) {
      return tension < 0.4 ? Emotion.confident : Emotion.happy;
    }
    if (confidence >= 0.25) return Emotion.playful;
    if (confidence <= -0.6) {
      return trend >= 0 ? Emotion.sad : Emotion.nervous;
    }
    if (confidence <= -0.25) return Emotion.nervous;
    if (tension >= 0.4) return Emotion.focused;
    return Emotion.calm;
  }

  static double _tanh(double x) {
    if (x > 20) return 1;
    if (x < -20) return -1;
    final e = math.exp(2 * x);
    return (e - 1) / (e + 1);
  }
}
