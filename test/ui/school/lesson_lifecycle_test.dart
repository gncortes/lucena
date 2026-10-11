import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/data/repositories/voice/voice_repository.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
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
  testWidgets(
    'T65: demo e voz retomam mesmo lance/fala; pausa manual permanece',
    (tester) async {
      final now = FakeNow(DateTime.utc(2026, 10, 11));
      final voice = FakeVoiceRepository(
        settings: const VoiceSettings(enabled: true),
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
        FakeSettingsRepository(const AppSettings()),
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
      expect(speech.state.speaking, 'Watch this demonstration.');
      voice.emit(const TtsProgress(6, 10));
      await tester.pump();
      final fen = lesson.state.fen;
      now.advance(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 250));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now.advance(const Duration(minutes: 2));
      await tester.pump(const Duration(seconds: 10));
      expect(lesson.state.demoMove, 0);
      expect(lesson.state.fen, fen);
      expect(lesson.state.speech, 'Watch this demonstration.');
      expect(speech.state.speaking, lesson.state.speech);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(voice.spoken.last.$1, 'this demonstration.');
      expect(lesson.state.demoMove, 0);
      voice.emit(const TtsFinished());
      await tester.pump(const Duration(milliseconds: 250));
      now.advance(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 250));
      expect(lesson.state.demoMove, 1);
      expect(lesson.state.speech, 'The rook moves.');
      lesson.demoTogglePause();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      now.advance(const Duration(minutes: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      now.advance(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 2));
      expect(lesson.state.demoMove, 1);
      expect(lesson.state.demoPlaying, isFalse);
    },
  );
}
