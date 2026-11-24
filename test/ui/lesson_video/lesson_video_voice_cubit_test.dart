import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/voice_audio_service.dart';
import 'package:lucena/domain/models/lesson_video.dart';
import 'package:lucena/domain/models/lesson_voice.dart';
import 'package:lucena/domain/use_cases/lesson_video_converter.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';

import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_video_repository.dart';
import '../../../testing/fakes/fake_lesson_voice_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_video_interruptions_repository.dart';
import '../../../testing/fakes/fake_voice_audio_service.dart';
import '../../../testing/script_fixture.dart';

/// A voz gravada (L4) na aula em vídeo: decisões 3 e 4 de FRENTES-24-11
/// (voz começa ligada; volume zero não desliga; baixada por capítulo).
void main() {
  const chapter = 'pawns.test';
  const clipLength = Duration(seconds: 2);
  late FakeNow now;
  late FakeVoiceAudioService audio;

  /// Os tempos de toda fala do roteiro de teste (2 s cada).
  Map<String, VoiceClip> allClips() => {
    for (final text in scriptTexts().values)
      LessonVideoConverter.audioKey(
        'pt',
        LessonVideoConverter.defaultVoice,
        text,
      ): const VoiceClip(
        length: clipLength,
      ),
  };

  setUp(() {
    now = FakeNow(DateTime(2026, 11, 24, 10));
    audio = FakeVoiceAudioService();
  });

  Future<LessonVideoCubit> open(FakeLessonVoiceRepository voice) async {
    final cubit = LessonVideoCubit(
      scripts: FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
      videos: FakeLessonVideoRepository(),
      interruptions: FakeVideoInterruptionsRepository(),
      now: now,
      lessonId: chapter,
      partId: 'distant',
      scriptPath: 'roteiro.json',
      autoplay: false,
      ticker: (_, _) => null,
      voice: voice,
      audio: () async => audio,
    );
    addTearDown(cubit.close);
    await cubit.start();
    return cubit;
  }

  test(
    'Vídeo 9: com a voz baixada, a aula segue o áudio e toca a fala',
    () async {
      final cubit = await open(
        FakeLessonVoiceRepository(
          states: {chapter: const VoicePackReady()},
          clips: allClips(),
        ),
      );
      expect(cubit.state.voice, VideoVoice.ready);
      cubit.play();
      // Chega ao trecho falado da primeira fala.
      for (var i = 0; i < 20 && audio.plays.isEmpty; i++) {
        now.advance(const Duration(milliseconds: 200));
        cubit.tick();
      }
      expect(audio.plays, isNotEmpty);
      expect(audio.plays.first.path, startsWith('/fake/audio/pt/viktor/'));
      expect(audio.plays.first.rate, 1);

      cubit.pause();
      expect(audio.playing, isFalse, reason: 'pausar cala a voz');
    },
  );

  test('Vídeo 10: sem o pacote, leitura com "Sem áudio." e baixar acerta o '
      'ritmo pela voz', () async {
    final voice = FakeLessonVoiceRepository(clips: allClips());
    final cubit = await open(voice);
    expect(cubit.state.voice, VideoVoice.missing);
    final readingTotal = cubit.state.total;

    await cubit.downloadVoice();
    expect(voice.downloads, [chapter]);
    expect(cubit.state.voice, VideoVoice.ready);
    expect(cubit.state.total, isNot(readingTotal));
  });

  test(
    'Vídeo 11: baixar a voz falhou → "Tentar de novo" baixa de novo',
    () async {
      final voice = FakeLessonVoiceRepository(clips: allClips())
        ..nextDownload = const VoicePackFailed(VoicePackFailure.network);
      final cubit = await open(voice);
      await cubit.downloadVoice();
      expect(cubit.state.voice, VideoVoice.failed);

      voice.nextDownload = const VoicePackReady();
      await cubit.downloadVoice();
      expect(voice.downloads, [chapter, chapter]);
      expect(cubit.state.voice, VideoVoice.ready);
    },
  );

  test('voz desligada: leitura sem aviso e sem tocar áudio', () async {
    final cubit = await open(
      FakeLessonVoiceRepository(
        states: {chapter: const VoicePackReady()},
        clips: allClips(),
        on: false,
      ),
    );
    expect(cubit.state.voice, VideoVoice.off);
    cubit.play();
    for (var i = 0; i < 20; i++) {
      now.advance(const Duration(milliseconds: 200));
      cubit.tick();
    }
    expect(audio.plays, isEmpty);
  });

  test('Vídeo 14: ligação ou fone desconectado pausa a aula', () async {
    final cubit = await open(
      FakeLessonVoiceRepository(
        states: {chapter: const VoicePackReady()},
        clips: allClips(),
      ),
    );
    cubit.play();
    for (var i = 0; i < 20 && !audio.playing; i++) {
      now.advance(const Duration(milliseconds: 200));
      cubit.tick();
    }
    audio.interrupt(VoiceInterruption.unplugged);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.playing, isFalse);
  });

  test('seek no meio da fala toca do ponto certo', () async {
    final cubit = await open(
      FakeLessonVoiceRepository(
        states: {chapter: const VoicePackReady()},
        clips: allClips(),
      ),
    );
    cubit.play();
    for (var i = 0; i < 20 && audio.plays.isEmpty; i++) {
      now.advance(const Duration(milliseconds: 200));
      cubit.tick();
    }
    final first = audio.plays.length;
    cubit.seek(cubit.state.position + const Duration(milliseconds: 500));
    expect(audio.plays.length, first + 1);
    expect(audio.plays.last.from, greaterThan(audio.plays.first.from));
  });
}
