import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/lesson_sound_keys.dart';
import 'package:lucena/ui/core/widgets/lesson_sound_dialog.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_voice_repository.dart';
import '../../../../testing/goldens/golden_harness.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeSettingsRepository settingsRepo;
  late FakeVoiceRepository voiceRepo;
  late SettingsCubit settings;
  late SpeechCubit speech;

  Future<void> open(
    WidgetTester tester, {
    AppSettings app = const AppSettings(),
    VoiceSettings voice = const VoiceSettings(enabled: true),
    List<TtsVoice>? voices,
    Locale locale = const Locale('en'),
    ThemeMode theme = ThemeMode.light,
  }) async {
    settingsRepo = FakeSettingsRepository(app);
    voiceRepo = FakeVoiceRepository(settings: voice, voices: voices);
    settings = SettingsCubit(settingsRepo, languages: const []);
    speech = SpeechCubit(voiceRepo);
    await settings.load();
    await speech.load();
    addTearDown(settings.close);
    addTearDown(speech.close);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: theme,
        settingsCubit: settings,
        speechCubit: speech,
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLessonSoundDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('X externo fecha sem alterar preferências', (tester) async {
    await open(tester);
    final close = tester.getRect(find.byKey(LessonSoundKeys.close));
    final dialog = tester.getRect(find.byKey(LessonSoundKeys.dialog));
    expect(close.size, const Size(48, 48));
    expect(close.bottom, lessThan(dialog.top));
    await tap(tester, LessonSoundKeys.close);
    expect(find.byKey(LessonSoundKeys.dialog), findsNothing);
    expect(settingsRepo.saved, isEmpty);
    expect(voiceRepo.settings, const VoiceSettings(enabled: true));
  });

  testWidgets('som interrompe Viktor e preserva voz e adversários ao reabrir', (
    tester,
  ) async {
    const voice = VoiceSettings(
      enabled: true,
      charactersMuted: true,
      speed: 1.5,
    );
    await open(tester, voice: voice);
    await speech.say(
      'Explanation',
      speakerId: SpeechCubit.teacherId,
      language: 'en',
    );
    expect(speech.state.speaking, isNotNull);
    await tap(tester, LessonSoundKeys.sound);
    expect(settingsRepo.settings.sound, isFalse);
    expect(settingsRepo.settings.characterTalk, isTrue);
    expect(speech.state.speaking, isNull);
    expect(voiceRepo.stops, 1);
    expect(voiceRepo.settings, voice);
    expect(find.byKey(LessonSoundKeys.speeds), findsNothing);
    await tap(tester, LessonSoundKeys.close);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Switch>(find.byKey(LessonSoundKeys.sound)).value,
      isFalse,
    );
    await tap(tester, LessonSoundKeys.sound);
    expect(voiceRepo.settings, voice);
    expect(find.byKey(LessonSoundKeys.speeds), findsOneWidget);
    expect(voiceRepo.spoken, hasLength(1));
  });

  testWidgets(
    'velocidade e voz persistem sem ligar som nem mutar adversários',
    (tester) async {
      await open(tester);
      await tap(tester, LessonSoundKeys.speed(1.5));
      expect(voiceRepo.settings.speed, 1.5);
      await tap(tester, LessonSoundKeys.teacherVoice);
      expect(voiceRepo.settings.enabled, isFalse);
      expect(voiceRepo.settings.charactersMuted, isFalse);
      expect(settingsRepo.settings.sound, isTrue);
      expect(find.byKey(LessonSoundKeys.speeds), findsNothing);
      await tap(tester, LessonSoundKeys.sound);
      await tap(tester, LessonSoundKeys.teacherVoice);
      expect(voiceRepo.settings.enabled, isTrue);
      expect(settingsRepo.settings.sound, isFalse);
      expect(voiceRepo.settings.speed, 1.5);
      expect(voiceRepo.spoken, isEmpty);
      expect(find.byKey(LessonSoundKeys.speeds), findsNothing);
    },
  );

  testWidgets('sem TTS preserva preferências e não mostra velocidades', (
    tester,
  ) async {
    await open(tester, voices: const []);
    expect(find.byKey(LessonSoundKeys.teacherVoice), findsOneWidget);
    expect(find.byKey(LessonSoundKeys.speeds), findsNothing);
    await tap(tester, LessonSoundKeys.sound);
    expect(voiceRepo.settings.enabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('velocidade personalizada permanece selecionada', (tester) async {
    await open(tester, voice: const VoiceSettings(enabled: true, speed: 1.25));
    expect(
      tester
          .widget<SegmentedButton<double>>(find.byKey(LessonSoundKeys.speeds))
          .selected,
      {1.25},
    );
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('linhas compactas preservam alvos e espaçamento do Canvas', (
    tester,
  ) async {
    await Goldens.loadFonts();
    await open(tester, locale: const Locale('pt'));
    final sound = tester.getRect(find.byKey(LessonSoundKeys.sound));
    final voice = tester.getRect(find.byKey(LessonSoundKeys.teacherVoice));
    final panel = tester.getRect(find.byKey(LessonSoundKeys.dialog));
    expect(sound.height, greaterThanOrEqualTo(48));
    expect(voice.height, greaterThanOrEqualTo(48));
    expect(voice.center.dy - sound.center.dy, closeTo(52, 1));
    expect(panel.width, 340);
    expect(panel.height, lessThanOrEqualTo(280));
    await tester.tap(find.text('Voz do Viktor'));
    await tester.pumpAndSettle();
    expect(voiceRepo.settings.enabled, isFalse);
  });

  testWidgets('velocidade forma uma faixa contínua com quatro alvos de 48', (
    tester,
  ) async {
    await open(tester);
    final group = find.byKey(LessonSoundKeys.speeds);
    final buttons = find.descendant(
      of: group,
      matching: find.byType(TextButton),
    );
    expect(buttons, findsNWidgets(4));
    final bounds = [for (var i = 0; i < 4; i++) tester.getRect(buttons.at(i))];
    for (var i = 0; i < 4; i++) {
      expect(bounds[i].height, greaterThanOrEqualTo(48));
      expect(bounds[i].width, closeTo(bounds.first.width, .01));
      if (i > 0) expect(bounds[i - 1].right, closeTo(bounds[i].left, .01));
    }
    final control = tester.widget<SegmentedButton<double>>(group);
    expect(control.showSelectedIcon, isFalse);
    expect(
      control.style!.backgroundColor!.resolve({WidgetState.selected}),
      Theme.of(tester.element(group)).colorScheme.secondaryContainer,
    );
  });

  for (final locale in [const Locale('pt'), const Locale('ar')]) {
    testWidgets('360×740 fonte2, escuro e $locale: controles alcançáveis', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await open(tester, locale: locale, theme: ThemeMode.dark);
      if (find.byKey(LessonSoundKeys.speeds).evaluate().isNotEmpty) {
        await tap(tester, LessonSoundKeys.speed(1.5));
        expect(voiceRepo.settings.speed, 1.5);
      }
      await tap(tester, LessonSoundKeys.teacherVoice);
      expect(voiceRepo.settings.enabled, isFalse);
      await tap(tester, LessonSoundKeys.close);
      expect(find.byKey(LessonSoundKeys.dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
