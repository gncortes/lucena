import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/ui/voice/widgets/voice_settings_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeVoiceRepository voice;

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('pt'),
  }) async {
    voice = FakeVoiceRepository();
    final speech = SpeechCubit(voice, characters: FakeCharacterRepository());
    addTearDown(speech.close);
    await speech.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        speechCubit: speech,
        child: const VoiceSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ligar a voz, a velocidade e a voz do professor são gravadas', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(VoiceKeys.enabledSwitch));
    await tester.pumpAndSettle();
    expect(voice.settings.enabled, isTrue);

    await tester.tap(find.byKey(VoiceKeys.speed(1.2)));
    await tester.pumpAndSettle();
    expect(voice.settings.speed, 1.2);

    await tester.scrollUntilVisible(
      find.byKey(VoiceKeys.voice('pt-br-b')),
      100,
    );
    await tester.tap(find.byKey(VoiceKeys.voice('pt-br-b')));
    await tester.pumpAndSettle();
    expect(voice.settings.teacherVoice, 'pt-br-b');

    await tester.scrollUntilVisible(find.byKey(VoiceKeys.betterVoices), 100);
    expect(find.byKey(VoiceKeys.betterVoices), findsOneWidget);
  });

  testWidgets('sem voz no idioma: só o porquê', (tester) async {
    await pump(tester, locale: const Locale('ja'));
    expect(find.byKey(VoiceKeys.unavailable), findsOneWidget);
    expect(find.byKey(VoiceKeys.enabledSwitch), findsNothing);
    expect(voice.settings, const VoiceSettings());
  });
}
