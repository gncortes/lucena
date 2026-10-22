import 'package:flutter/widgets.dart';

import '../../../domain/models/voice.dart';

/// Keys da voz: o botão de áudio do balão, o passo de voz do tour e a seção
/// das configurações.
abstract final class VoiceKeys {
  /// O botão de áudio do balão de fala: ouvir ou parar; onde o personagem
  /// fala sozinho, liga e desliga a voz dele.
  static const speakButton = Key('voice.speak');

  /// O botão de velocidade do balão (cada toque, a próxima).
  static const speedButton = Key('voice.speed');

  /// Uma voz da lista (tocar escolhe e deixa ouvir).
  static Key voice(String id) => Key('voice.option.$id');

  /// Um tom da voz.
  static Key tone(VoiceTone tone) => Key('voice.tone.${tone.name}');

  /// "Sem voz", no tour.
  static const none = Key('voice.none');

  /// "Manter assim", no passo das vozes dos adversários.
  static const keep = Key('voice.keep');

  /// A linha da voz nas configurações, que abre a tela dela.
  static const settingsTile = Key('voice.settingsTile');

  /// A tela da voz nas configurações.
  static const settingsSection = Key('voice.settings');
  static const enabledSwitch = Key('voice.settings.enabled');
  static Key speed(double speed) => Key('voice.settings.speed.$speed');
  static const unavailable = Key('voice.settings.unavailable');
  static const betterVoices = Key('voice.settings.better');

  /// Abre as configurações de voz do aparelho.
  static const openSystem = Key('voice.openSystem');
}
