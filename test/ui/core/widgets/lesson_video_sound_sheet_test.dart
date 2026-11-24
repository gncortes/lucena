import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/lesson_sound_keys.dart';
import 'package:lucena/ui/core/widgets/sound_sheet.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_voice_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../../testing/fakes/fake_lesson_voice_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_voice_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeVoiceRepository voiceRepo;
  late FakeLessonVoiceRepository lessonVoice;

  Future<void> open(WidgetTester tester, SoundSheetScope scope) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: const [],
    );
    voiceRepo = FakeVoiceRepository(
      settings: const VoiceSettings(enabled: true),
    );
    final speech = SpeechCubit(voiceRepo);
    lessonVoice = FakeLessonVoiceRepository();
    final video = LessonVoiceCubit(lessonVoice, chapterId: 'c1');
    await settings.load();
    await speech.load();
    await video.load();
    addTearDown(settings.close);
    addTearDown(speech.close);
    addTearDown(video.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        speechCubit: speech,
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSoundSheet(
                context,
                scope: scope,
                videoVoice: scope == SoundSheetScope.lessonVideo ? video : null,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('Vídeo 8: Som e voz da aula em vídeo não tem a velocidade', (
    tester,
  ) async {
    await open(tester, SoundSheetScope.lessonVideo);
    expect(find.byKey(LessonSoundKeys.dialog), findsOneWidget);
    expect(find.byKey(LessonSoundKeys.teacherVoice), findsOneWidget);
    expect(find.byKey(LessonSoundKeys.speeds), findsNothing);
  });

  testWidgets('a aula de hoje continua com a velocidade', (tester) async {
    await open(tester, SoundSheetScope.lesson);
    expect(find.byKey(LessonSoundKeys.speeds), findsOneWidget);
  });

  testWidgets('Vídeo 9: desligar a voz grava a preferência da aula em vídeo', (
    tester,
  ) async {
    await open(tester, SoundSheetScope.lessonVideo);
    await tester.tap(find.byKey(LessonSoundKeys.teacherVoice));
    await tester.pumpAndSettle();
    expect(lessonVoice.on, isFalse);
    // A voz falada (TTS) das outras aulas fica como estava.
    expect(voiceRepo.settings.enabled, isTrue);
    final toggle = tester.widget<Switch>(
      find.byKey(LessonSoundKeys.teacherVoice),
    );
    expect(toggle.value, isFalse);
  });
}
