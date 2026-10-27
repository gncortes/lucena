import 'package:flutter/widgets.dart';

/// Chaves do balão de fala único (`SpeechBalloon`, T84).
abstract final class SpeechKeys {
  /// O X do balão aberto por cima do topo.
  static const close = Key('speech.close');

  /// O texto cortado que termina em "… Ver mais".
  static const cut = Key('speech.cut');
}
