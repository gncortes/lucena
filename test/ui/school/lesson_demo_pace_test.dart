import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_part_widgets.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<
    ({
      LessonCubit lesson,
      SpeechCubit speech,
      SettingsCubit settings,
      FakeNow now,
    })
  >
  pumpDemo(
    WidgetTester tester, {
    bool sound = true,
    bool voiceEnabled = true,
  }) async {
    final now = FakeNow(DateTime.utc(2026, 10, 13));
    final voice = FakeVoiceRepository(
      settings: VoiceSettings(enabled: voiceEnabled),
    );
    final speech = SpeechCubit(voice);
    addTearDown(speech.close);
    await speech.load();
    final lesson = LessonCubit(
      lessons: FakeLessonRepository(
        course: const Course(
          modules: [
            CourseModule(
              id: 'pieces',
              lessons: [
                Lesson(
                  id: 'pieces.demo',
                  steps: [
                    DemoStep(
                      id: 'demo',
                      fen: FakeEndgameLessonRepository.lucenaFen,
                      line: [
                        DemoMove(uci: 'c1c4'),
                        DemoMove(uci: 'a2a1'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        texts: LessonTexts.fromJson({
          'pieces.demo.title': 'Demonstration',
          'pieces.demo.demo': 'Watch this demonstration.',
          'pieces.demo.demo.m1': 'The rook moves.',
          'pieces.demo.demo.m2': 'Black replies.',
        }),
      ),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      now: now,
    );
    addTearDown(lesson.close);
    await lesson.load('pieces.demo', 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(AppSettings(sound: sound)),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        speechCubit: speech,
        child: BlocProvider.value(value: lesson, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Roda antes do fechamento da voz: tira a tela e a fala presa.
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    return (lesson: lesson, speech: speech, settings: settings, now: now);
  }

  /// Deixa passar [seconds] em tiques de 250 ms (relógio do app e do teste).
  Future<void> wait(
    WidgetTester tester,
    FakeNow now,
    int seconds,
    bool Function() until,
  ) async {
    for (var i = 0; i < seconds * 4 && !until(); i++) {
      now.advance(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('demo: som do app desligado e uma fala que nunca termina '
      '(botão de áudio) não trava o lance', (tester) async {
    final t = await pumpDemo(tester, sound: false);
    await t.speech.say(
      'Watch this demonstration.',
      speakerId: 'master',
      language: 'en',
    );
    expect(t.speech.state.speaking, 'Watch this demonstration.');
    await wait(tester, t.now, 9, () => t.lesson.state.demoMove > 0);
    expect(t.lesson.state.demoMove, 1);
  });

  testWidgets('demo: voz do Viktor desligada e uma fala que nunca termina '
      'não trava o lance', (tester) async {
    final t = await pumpDemo(tester, voiceEnabled: false);
    await t.speech.say(
      'Watch this demonstration.',
      speakerId: 'master',
      language: 'en',
    );
    expect(t.speech.state.speaking, 'Watch this demonstration.');
    await wait(tester, t.now, 9, () => t.lesson.state.demoMove > 0);
    expect(t.lesson.state.demoMove, 1);
  });

  testWidgets('demo sem voz (som desligado desde o começo): o lance sai pelo '
      'tempo de leitura, no máximo em 8 s', (tester) async {
    final t = await pumpDemo(tester, sound: false);
    expect(t.speech.state.speaking, isNull);
    await wait(tester, t.now, 9, () => t.lesson.state.demoMove > 0);
    expect(t.lesson.state.demoMove, 1);
  });

  testWidgets('anel do ⏭: tracejado falando, arco contando, sem anel pausada', (
    tester,
  ) async {
    final t = await pumpDemo(tester);
    double? progress() {
      final ring = tester.widget<CustomPaint>(find.byKey(LessonKeys.demoRing));
      final painter = ring.painter! as dynamic;
      return painter.speaking as bool ? null : painter.progress as double;
    }

    Future<void> tick(int n) async {
      for (var i = 0; i < n; i++) {
        t.now.advance(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    await tick(2);
    // Voz falando: trilho tracejado, sem arco.
    expect(progress(), isNull);
    // Sem voz: o arco cresce com o tempo de leitura.
    await t.speech.stop();
    await t.settings.setSound(enabled: false);
    await tick(2);
    final first = progress()!;
    await tick(2);
    expect(progress()!, greaterThan(first));
    // Pausada: sem anel.
    t.lesson.demoTogglePause();
    await tick(2);
    expect(find.byKey(LessonKeys.demoRing), findsNothing);
  });

  test(
    'DemoPace: a espera sem voz tem teto de 8 s e respeita a velocidade',
    () {
      expect(DemoPace.waitMs(length: 10, spoke: false, speed: 1), 3100);
      expect(DemoPace.waitMs(length: 500, spoke: false, speed: 1), 8000);
      expect(DemoPace.waitMs(length: 10, spoke: false, speed: 2), 1550);
      expect(DemoPace.waitMs(length: 10, spoke: true, speed: 1), 600);
    },
  );
}
