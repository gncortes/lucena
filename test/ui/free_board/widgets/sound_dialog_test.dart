import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/game_sound_keys.dart';
import 'package:lucena/ui/free_board/widgets/sound_dialog.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_voice_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  Future<(FakeSettingsRepository, FakeVoiceRepository)> open(
    WidgetTester tester, {
    bool compact = false,
  }) async {
    if (compact) {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    final settingsRepo = FakeSettingsRepository();
    final settings = SettingsCubit(settingsRepo, languages: const []);
    final voiceRepo = FakeVoiceRepository(
      settings: const VoiceSettings(enabled: true),
    );
    final speech = SpeechCubit(voiceRepo);
    addTearDown(settings.close);
    addTearDown(speech.close);
    await settings.load();
    await speech.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        speechCubit: speech,
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGameSoundDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return (settingsRepo, voiceRepo);
  }

  testWidgets('X fica fora do diálogo e fecha sem gravar preferências', (
    tester,
  ) async {
    final (settings, _) = await open(tester, compact: true);
    final close = tester.getRect(find.byKey(GameSoundKeys.close));
    final dialog = tester.getRect(find.byKey(GameSoundKeys.dialog));
    expect(close.size, const Size(44, 44));
    expect(close.bottom, lessThan(dialog.top));
    await tester.tap(find.byKey(GameSoundKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(GameSoundKeys.dialog), findsNothing);
    expect(settings.saved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('som e falas persistem; velocidade some com som desligado', (
    tester,
  ) async {
    final (settings, voice) = await open(tester);
    expect(find.byKey(GameSoundKeys.speeds), findsOneWidget);
    await tester.tap(find.byKey(GameSoundKeys.speed(1.5)));
    await tester.pumpAndSettle();
    expect(voice.settings.speed, 1.5);
    await tester.tap(find.byKey(GameSoundKeys.sound));
    await tester.pumpAndSettle();
    expect(settings.settings.sound, isFalse);
    expect(voice.settings.charactersMuted, isTrue);
    expect(find.byKey(GameSoundKeys.speeds), findsNothing);
    await tester.tap(find.byKey(GameSoundKeys.comments));
    await tester.pumpAndSettle();
    expect(settings.settings.characterTalk, isFalse);
    expect(voice.settings.charactersMuted, isTrue);
    await tester.tap(find.byKey(GameSoundKeys.sound));
    await tester.pumpAndSettle();
    expect(settings.settings.sound, isTrue);
    expect(voice.settings.charactersMuted, isTrue);
    expect(find.byKey(GameSoundKeys.speeds), findsNothing);
  });
}
