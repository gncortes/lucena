import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/game_sound_keys.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/widgets/sound_off_icon.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';

import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';
import 'package:lucena/ui/free_board/widgets/character_bar.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_voice_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  Future<(SpeechCubit, FakeVoiceRepository)> pump(
    WidgetTester tester, {
    VoiceSettings settings = const VoiceSettings(enabled: true),
    List<TtsVoice>? voices,
  }) async {
    final appSettings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(appSettings.close);
    await appSettings.load();
    final voice = FakeVoiceRepository(settings: settings, voices: voices);
    final speech = SpeechCubit(voice);
    addTearDown(speech.close);
    await speech.load();
    await tester.pumpWidget(
      TestApp(
        speechCubit: speech,
        settingsCubit: appSettings,
        child: Scaffold(
          appBar: AppBar(actions: const [CharacterSoundButton()]),
        ),
      ),
    );
    await tester.pump();
    return (speech, voice);
  }

  testWidgets('abrir som não cala; switch persiste e X externo fecha', (
    tester,
  ) async {
    final (speech, voice) = await pump(tester);
    await speech.sayIfEnabled('Oi!', speakerId: 'grandpa', language: 'en');
    await tester.tap(find.byKey(FreeBoardKeys.soundButton));
    await tester.pumpAndSettle();
    expect(find.byKey(GameSoundKeys.dialog), findsOneWidget);
    expect(voice.settings.charactersMuted, isFalse);
    expect(
      tester.getRect(find.byKey(GameSoundKeys.close)).bottom,
      lessThan(tester.getRect(find.byKey(GameSoundKeys.dialog)).top),
    );
    await tester.tap(find.byKey(GameSoundKeys.sound));
    await tester.pumpAndSettle();
    expect(voice.settings.charactersMuted, isTrue);
    expect(voice.stops, greaterThanOrEqualTo(1));
    expect(voice.settings.enabled, isTrue);
    await tester.tap(find.byKey(GameSoundKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(GameSoundKeys.dialog), findsNothing);
    expect(find.byType(SoundOffIcon), findsOneWidget);
  });

  testWidgets('velocidade muda pelo diálogo e aparece no botão', (
    tester,
  ) async {
    final (_, voice) = await pump(tester);
    await tester.tap(find.byKey(FreeBoardKeys.soundButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(GameSoundKeys.speed(1.5)));
    await tester.pumpAndSettle();
    expect(voice.settings.speed, 1.5);
    await tester.tap(find.byKey(GameSoundKeys.close));
    await tester.pumpAndSettle();
    expect(find.text('1.5×'), findsOneWidget);
  });

  testWidgets('sem TTS botão mantém som e falas, sem velocidade', (
    tester,
  ) async {
    await pump(tester, voices: const []);
    expect(find.byKey(FreeBoardKeys.soundButton), findsOneWidget);
    await tester.tap(find.byKey(FreeBoardKeys.soundButton));
    await tester.pumpAndSettle();
    expect(find.byKey(GameSoundKeys.sound), findsOneWidget);
    expect(find.byKey(GameSoundKeys.comments), findsOneWidget);
    expect(find.byKey(GameSoundKeys.speeds), findsNothing);
  });

  testWidgets('botão Som cabe com texto ampliado sem overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);
    expect(find.byKey(FreeBoardKeys.soundButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calado, a fala nova do personagem só aparece no balão', (
    tester,
  ) async {
    Future<FakeVoiceRepository> open(VoiceSettings settings) async {
      final voice = FakeVoiceRepository(settings: settings);
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await speech.load();
      await tester.pumpWidget(
        TestApp(
          speechCubit: speech,
          child: const Scaffold(
            body: CharacterBar(
              talk: TalkState(
                character: FakeCharacterRepository.viktor,
                line: CharacterLine(
                  id: 'oi',
                  category: LineCategory.gameStart,
                  intensity: 1,
                  emotion: Emotion.calm,
                  text: 'Vamos jogar!',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return voice;
    }

    final muted = await open(
      const VoiceSettings(enabled: true, charactersMuted: true),
    );
    expect(find.byKey(FreeBoardKeys.speechBubble), findsOneWidget);
    expect(muted.spoken, isEmpty);

    await tester.pumpWidget(const SizedBox());
    final heard = await open(const VoiceSettings(enabled: true));
    expect(heard.spoken, hasLength(1));
  });

  testWidgets('som global desligado preserva balão e impede voz automática', (
    tester,
  ) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings(sound: false)),
      languages: const [],
    );
    final voice = FakeVoiceRepository(
      settings: const VoiceSettings(enabled: true),
    );
    final speech = SpeechCubit(voice);
    addTearDown(settings.close);
    addTearDown(speech.close);
    await settings.load();
    await speech.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        speechCubit: speech,
        child: const Scaffold(
          body: CharacterBar(
            talk: TalkState(
              character: FakeCharacterRepository.viktor,
              line: CharacterLine(
                id: 'global-off',
                category: LineCategory.gameStart,
                intensity: 1,
                emotion: Emotion.calm,
                text: 'Hello!',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.speechBubble), findsOneWidget);
    expect(voice.spoken, isEmpty);
  });
}
