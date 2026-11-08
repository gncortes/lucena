import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/voice/widgets/voice_pickers.dart';
import 'package:patrol/patrol.dart';

import '../../testing/e2e_dependencies.dart';
import 'settings_robot.dart';

/// A voz: o passo do tour, a escolha das vozes, o botão de áudio do balão e
/// a tela da voz nas configurações. O sintetizador é o falso dos cenários.
class VoiceRobot {
  const VoiceRobot(this.$);

  final PatrolIntegrationTester $;

  /// Escolhe uma voz da lista (e ela fala uma amostra).
  Future<void> choose(String voiceId) async {
    await $(_voiceKey(voiceId)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// "Sem voz", no tour.
  Future<void> chooseNone() async {
    await $(_inTour ? TourKeys.voiceNone : VoiceKeys.none).scrollTo().tap();
    await $.pumpAndSettle();
  }

  bool get _inTour => find.byKey(TourKeys.screen).evaluate().isNotEmpty;

  /// O tour tem a grade própria, com as vozes numeradas na ordem do idioma.
  Key _voiceKey(String voiceId) {
    if (!_inTour) return VoiceKeys.voice(voiceId);
    final language = voiceLanguage(
      $.tester.element(find.byKey(TourKeys.screen)),
    );
    final voices = TtsVoice.forLanguage(e2eTts.installed, language);
    final index = voices.indexWhere((v) => v.id == voiceId);
    expect(index, isNonNegative, reason: 'voz $voiceId fora de $language');
    return TourKeys.voiceCard(index + 1);
  }

  /// O botão de áudio do balão.
  Future<void> tapSpeak() async {
    await $(VoiceKeys.speakButton).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// Em Configurações, abre a tela da voz.
  Future<void> openSettings() async {
    await SettingsRobot($).openSound();
    await $(VoiceKeys.settingsTile).scrollTo().tap();
    await $(VoiceKeys.settingsSection).waitUntilVisible();
  }

  /// Liga ou desliga a voz na tela dela.
  Future<void> toggleEnabled() async {
    await $(VoiceKeys.enabledSwitch).tap();
    await $.pumpAndSettle();
  }

  void expectEnabled({required bool enabled}) => expect(
    $.tester.widget<SwitchListTile>(find.byKey(VoiceKeys.enabledSwitch)).value,
    enabled,
  );

  /// A voz marcada na lista.
  void expectChosen(String voiceId) => expect(
    $.tester.widget<VoiceCard>(find.byKey(VoiceKeys.voice(voiceId))).selected,
    isTrue,
  );

  /// A última fala mandada ao sintetizador, com a voz.
  (String, String) get lastSpoken {
    final (text, voice) = e2eTts.spoken.last;
    return (text, voice.voice.id);
  }

  int get spokenCount => e2eTts.spoken.length;
  int get stops => e2eTts.stops;
}
