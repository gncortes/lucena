import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
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
  }) async {
    final voice = FakeVoiceRepository(settings: settings);
    final speech = SpeechCubit(voice);
    addTearDown(speech.close);
    await speech.load();
    await tester.pumpWidget(
      TestApp(
        speechCubit: speech,
        child: Scaffold(
          appBar: AppBar(actions: const [CharacterSoundButton()]),
        ),
      ),
    );
    await tester.pump();
    return (speech, voice);
  }

  bool heard(WidgetTester tester) => tester
      .widget<IconButton>(find.byKey(FreeBoardKeys.soundButton))
      .isSelected!;

  testWidgets('o botão cala o personagem no meio da fala, e fica gravado', (
    tester,
  ) async {
    final (speech, voice) = await pump(tester);
    await speech.sayIfEnabled('Oi!', speakerId: 'grandpa', language: 'en');
    expect(heard(tester), isTrue);

    await tester.tap(find.byKey(FreeBoardKeys.soundButton));
    await tester.pump();
    expect(heard(tester), isFalse);
    expect(voice.stops, 1);
    expect(voice.settings.charactersMuted, isTrue);
    // A voz continua ligada: o professor das aulas segue falando.
    expect(voice.settings.enabled, isTrue);
  });

  testWidgets('calado (ou com a voz desligada), o botão volta a ouvir', (
    tester,
  ) async {
    final (_, voice) = await pump(tester, settings: const VoiceSettings());
    expect(heard(tester), isFalse);

    await tester.tap(find.byKey(FreeBoardKeys.soundButton));
    await tester.pump();
    expect(heard(tester), isTrue);
    expect(voice.settings.enabled, isTrue);
    expect(voice.settings.charactersMuted, isFalse);
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
}
