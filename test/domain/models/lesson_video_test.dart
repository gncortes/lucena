import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_video.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';

import '../../../testing/lesson_video_fixture.dart';

void main() {
  group('formato', () {
    test('lê falas, ramos, pergunta e palavras do JSON', () {
      final video = sampleLessonVideo();
      expect(video.lines, hasLength(4));
      expect(video.branches.keys, contains('ideia.ex1.err.e2e3'));
      final gate = video.lines[1].gate!;
      expect(gate.right, ['e2e4']);
      expect(gate.legacy, isFalse);
      expect(gate.exitFor('e2e4'), isNull);
      expect(gate.exitFor('e2e3')!.after, GateAfter.retry);
      expect(gate.exitFor('e1d1')!.after, GateAfter.resume);
      expect(gate.exitFor('e1f1')!.branch, 'ideia.ex1.fora');
      expect(gate.exitFor('e1f1')!.after, GateAfter.retry);
      expect(video.lines.first.words, hasLength(5));
      expect(video.hasAudio, isTrue);
    });

    test('recusa formato desconhecido', () {
      expect(
        () => LessonVideo.fromJson({...lessonVideoJson, 'formato': 99}),
        throwsFormatException,
      );
    });

    test('lê os nomes marcados da fala', () {
      final line = VideoLine.fromJson({
        'id': 'a',
        't': 'k',
        'texto': 'Como Kasparov jogou.',
        'tabuleiro': {'fen': '8/8/8/8/8/8/8/8 w - - 0 1'},
        'links': [
          [5, 13, 'garry-kasparov'],
        ],
      });
      expect(line.links.single.text, 'Kasparov');
      expect(line.links.single.key, 'garry-kasparov');
      expect(line.audio, isNull);
      expect(line.voice, Duration.zero);
    });
  });

  test('a etapa fica só com as falas, os capítulos e os ramos dela', () {
    VideoLine line(String id) => VideoLine(
      id: id,
      textKey: id,
      text: id,
      voice: Duration.zero,
      board: const VideoBoard(fen: '8/8/8/8/8/8/8/8 w - - 0 1'),
    );
    final video = LessonVideo(
      lessonId: 'l',
      partId: 'p',
      language: 'pt',
      chapters: const [
        VideoChapter(id: 'ideia.ex1', stage: 'ideia', firstLine: 0),
        VideoChapter(id: 'demos.ex1', stage: 'demos', firstLine: 2),
        VideoChapter(id: 'demos.ex2', stage: 'demos', firstLine: 3),
      ],
      lines: [
        line('ideia.ex1.e.1'),
        line('ideia.ex1.e.2'),
        line('demos.ex1.e.1'),
        line('demos.ex2.e.1'),
      ],
      branches: {
        'ideia.ex1.revela': [line('ideia.ex1.revela.1')],
        'demos.ex2.revela': [line('demos.ex2.revela.1')],
      },
    );
    final demos = video.stage('demos');
    expect(demos.lines.map((l) => l.id), ['demos.ex1.e.1', 'demos.ex2.e.1']);
    expect(demos.chapters.map((c) => c.firstLine), [0, 1]);
    expect(demos.branches.keys, ['demos.ex2.revela']);
    expect(video.stage('ideia').lines, hasLength(2));
    expect(video.hasAudio, isFalse);
  });

  test('o áudio da fala lê a duração e o tempo das palavras', () {
    final clip = VoiceClip.fromJson({
      'ms': 1200,
      'palavras': [
        {'texto': 'Olá', 'ini': 0, 'fim': 400},
      ],
    });
    expect(clip.length, const Duration(milliseconds: 1200));
    expect(clip.words.single.text, 'Olá');
    expect(clip.words.single.to, const Duration(milliseconds: 400));
  });

  group('ajustes', () {
    test('a velocidade cicla 0,75 → 1 → 1,25 → 1,5 → 2 → 0,75', () {
      var settings = const VideoSettings(rate: 0.75);
      final seen = <double>[settings.rate];
      for (var i = 0; i < 5; i++) {
        settings = settings.copyWith(rate: settings.nextRate);
        seen.add(settings.rate);
      }
      expect(seen, [0.75, 1.0, 1.25, 1.5, 2.0, 0.75]);
    });

    test('velocidade fora da lista vira a mais próxima', () {
      expect(VideoSettings.fromJson({'velocidade': 3}).rate, 2.0);
      expect(VideoSettings.fromJson({'velocidade': 1.3}).rate, 1.25);
    });

    test('ida e volta em JSON', () {
      const settings = VideoSettings(captions: false, rate: 1.5);
      expect(VideoSettings.fromJson(settings.toJson()), settings);
      expect(VideoSettings.fromJson(const {}), const VideoSettings());
    });
  });

  test('o progresso guarda fala, fração e perguntas respondidas', () {
    const progress = VideoProgress(
      line: 'ideia.ex1.p',
      fraction: 0.25,
      resolved: {'ideia.ex1.p', 'demos.ex2.p'},
    );
    expect(VideoProgress.fromJson(progress.toJson()), progress);
    expect(VideoProgress.fromJson({'fala': 'x', 'fracao': 4}).fraction, 1.0);
  });
}
