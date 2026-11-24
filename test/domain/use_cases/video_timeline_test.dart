import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/lesson_video.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';
import 'package:lucena/domain/use_cases/video_timeline.dart';

import '../../../testing/lesson_video_fixture.dart';

Duration ms(int value) => Duration(milliseconds: value);

void main() {
  const start = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
  const afterE4 = '4k3/8/8/8/4P3/8/8/4K3 b - - 0 1';
  late LessonVideo video;
  late VideoTimeline timeline;

  setUp(() {
    video = sampleLessonVideo();
    timeline = VideoTimeline.layout(video.lines);
  });

  group('layout', () {
    test('soma voz, pausa e o tempo do lance', () {
      expect(timeline.lines.map((l) => l.start), [
        ms(0),
        ms(2500),
        ms(5000),
        ms(8000),
      ]);
      expect(timeline.lines[2].voiceStart, ms(5400));
      expect(timeline.total, ms(9000));
    });

    test('na velocidade 2x a voz dura a metade', () {
      final fast = VideoTimeline.layout(video.lines, rate: 2);
      expect(fast.lines[0].voiceEnd, ms(1000));
      expect(fast.total, ms(1000 + 500 + 1000 + 500 + 400 + 1000 + 600 + 500));
    });

    test('sem som, cada fala dura o tempo de leitura', () {
      final silent = VideoTimeline.layout(video.lines, pace: VideoPace.reading);
      final first = silent.lines.first;
      expect(
        first.voiceLength,
        VideoTimeline.readingTime(video.lines.first.text),
      );
      // As palavras escalam junto: a marca da palavra 3 entra mais tarde.
      expect(first.wordAt(3), greaterThan(ms(1200)));
    });

    test('o tempo de leitura tem teto de 8 s', () {
      expect(VideoTimeline.readingTime('x' * 500), const Duration(seconds: 8));
      expect(VideoTimeline.readingTime('curta'), ms(3750));
    });
  });

  group('estado(t)', () {
    test('o mesmo t dá o mesmo quadro, em qualquer ordem de busca', () {
      final a = timeline.frameAt(ms(6000));
      timeline.frameAt(ms(100));
      final b = timeline.frameAt(ms(6000));
      expect(a.fen, b.fen);
      expect(a.lineIndex, b.lineIndex);
      expect(a.word, b.word);
    });

    test('o tabuleiro em t é o do último keyframe', () {
      expect(timeline.frameAt(ms(4999)).fen, start);
      final moved = timeline.frameAt(ms(5000));
      expect(moved.fen, afterE4);
      expect(moved.lastMove, 'e2e4');
      expect(moved.animating, isTrue);
      expect(timeline.frameAt(ms(5400)).animating, isFalse);
    });

    test('voltar no tempo desfaz o lance', () {
      timeline.frameAt(ms(7000));
      expect(timeline.frameAt(ms(1000)).fen, start);
      expect(timeline.frameAt(ms(1000)).lastMove, isNull);
    });

    test('a marca aparece quando o Viktor diz a casa', () {
      expect(timeline.frameAt(ms(100)).marks, ['e2']);
      expect(timeline.frameAt(ms(1200)).marks, ['e4', 'e2']);
    });

    test('a legenda acompanha a palavra dita', () {
      expect(timeline.frameAt(ms(100)).word, 0);
      expect(timeline.frameAt(ms(1300)).word, 3);
      expect(timeline.frameAt(ms(2200)).word, isNull);
      expect(timeline.frameAt(ms(2200)).speaking, isFalse);
      expect(timeline.frameAt(ms(1300)).caption, 'Olhe a casa e4 agora.');
    });

    test('a legenda recebe o instante de cada palavra e a fala anterior', () {
      final first = timeline.frameAt(ms(100));
      expect(first.wordTimes, hasLength(first.words.length));
      expect(first.wordTimes[3].from, timeline.lines[0].wordAt(3));
      expect(first.previousCaption, isNull);
      final second = timeline.frameAt(timeline.lines[1].start);
      expect(second.previousCaption, 'Olhe a casa e4 agora.');
      expect(second.previousWords, timeline.lines[0].line.words);
    });

    test('setas valem durante a fala delas', () {
      expect(timeline.frameAt(ms(3000)).arrows, [
        const ScriptArrow('e2', 'e4', 'g'),
      ]);
      expect(timeline.frameAt(ms(6000)).arrows, isEmpty);
    });

    test('t fora da linha é limitado às pontas', () {
      expect(timeline.frameAt(ms(-500)).t, Duration.zero);
      expect(timeline.frameAt(ms(99999)).t, ms(9000));
    });
  });

  group('ponto de interação', () {
    test('a busca para na pergunta sem resposta', () {
      expect(timeline.reachable(ms(7000), {}), ms(4500));
      expect(timeline.frameAt(ms(4500)).atGate, isTrue);
    });

    test('respondida, a busca passa', () {
      final resolved = {'ideia.ex1.p'};
      expect(timeline.reachable(ms(7000), resolved), ms(7000));
      expect(timeline.frameAt(ms(4500), resolved: resolved).atGate, isFalse);
    });

    test('antes da pergunta, a busca é livre', () {
      expect(timeline.reachable(ms(3000), {}), ms(3000));
    });
  });

  group('ramo', () {
    test('o ramo começa na posição da pergunta e joga o lance errado', () {
      final branch = VideoTimeline.layout(
        video.branches['ideia.ex1.err.e2e3']!,
        startFen: start,
      );
      expect(branch.frameAt(Duration.zero).lastMove, 'e2e3');
      // Sem áudio, a fala do ramo dura o tempo de leitura.
      expect(
        branch.total,
        ms(400) + VideoTimeline.readingTime('Só uma casa: devagar.') + ms(500),
      );
    });
  });

  group('sequência de lances', () {
    test('cada lance da sequência vira um keyframe com a posição dele', () {
      final line = VideoLine.fromJson({
        'id': 'seq',
        't': 'k',
        'texto': 'Dois lances.',
        'audio': 'a.opus',
        'ms': 1000,
        'tabuleiro': {
          'fen': '4k3/8/8/8/4P3/8/8/4K3 w - - 0 1',
          'lance': 'e2e3',
          'seq': ['e8d8', 'e3e4', 'd8e8'],
        },
      });
      final seq = VideoTimeline.layout([line], startFen: start);
      final fens = seq.keys.map((k) => k.fen).toList();
      expect(fens, hasLength(5));
      expect(fens.last, '4k3/8/8/8/4P3/8/8/4K3 w - - 0 1');
      expect(seq.frameAt(ms(450)).lastMove, 'e8d8');
      expect(seq.lines.single.voiceStart, ms(400 + 300 * 3));
    });

    test('lance que não se joga corta para a posição da fala', () {
      final line = VideoLine.fromJson({
        'id': 'ruim',
        't': 'k',
        'texto': 'x',
        'ms': 1000,
        'tabuleiro': {
          'fen': '8/8/8/8/3K4/8/8/8 w - - 0 1',
          'lance': 'a1a2',
          'seq': ['a2a3'],
        },
      });
      final bad = VideoTimeline.layout([
        line,
      ], startFen: '8/8/8/8/8/8/8/8 w - - 0 1');
      expect(bad.frameAt(ms(5000)).fen, '8/8/8/8/3K4/8/8/8 w - - 0 1');
    });
  });

  group('alternativa boa', () {
    test('retoma depois das falas que são só do lance certo', () {
      expect(video.lines[1].gate!.rightLines, 1);
      expect(timeline.resumeAfterAlternative(1), ms(8000));
    });
  });

  // Gaps do fluxo `docs/fluxos/aula-video.md` (domínio; nome = gap).
  group('gaps', () {
    test('Vídeo 4: arrastar além da pergunta sem resposta para no instante '
        'dela', () {
      final gate = timeline.lines[1].voiceEnd;
      expect(timeline.reachable(timeline.total, {}), gate);
      expect(timeline.reachable(gate + ms(1), {}), gate);
      expect(timeline.reachable(gate - ms(1), {}), gate - ms(1));
      // Respondida, a barra é livre até o fim.
      expect(
        timeline.reachable(timeline.total, {'ideia.ex1.p'}),
        timeline.total,
      );
      // Abaixo de zero, o começo.
      expect(timeline.reachable(ms(-10000), {}), Duration.zero);
    });

    test('Vídeo 6: −10 s no meio do lance mostra o quadro de t e o lance '
        'anima de novo quando t passa por ele', () {
      // Tocando, o lance e2e4 começa em 5000 e anima por 400 ms.
      final middle = timeline.frameAt(ms(5200));
      expect(middle.fen, afterE4);
      expect(middle.animating, isTrue);
      // −10 s a partir do meio do lance: volta ao começo, antes do lance.
      final back = timeline.frameAt(ms(5200) - const Duration(seconds: 10));
      expect(back.t, Duration.zero);
      expect(back.fen, start);
      expect(back.lastMove, isNull);
      expect(back.animating, isFalse);
      // Busca para o meio do lance de novo: o quadro é o mesmo de antes.
      final again = timeline.frameAt(ms(5200));
      expect(again.fen, middle.fen);
      expect(again.lastMove, 'e2e4');
      expect(again.animating, isTrue);
      // Depois do lance, a peça já está parada.
      expect(timeline.frameAt(ms(5400)).animating, isFalse);
    });

    test('Vídeo 8: trocar a velocidade no meio da fala mantém a fala e a '
        'fração', () {
      final t = timeline.lines[2].start + ms(1500);
      final anchor = timeline.anchorAt(t)!;
      expect(anchor.id, 'ideia.ex1.certo.1');
      for (final rate in VideoSettings.rates) {
        final other = VideoTimeline.layout(video.lines, rate: rate);
        final moved = other.timeOf(anchor.id, anchor.fraction)!;
        final back = other.anchorAt(moved)!;
        expect(back.id, anchor.id, reason: 'velocidade $rate');
        expect(back.fraction, closeTo(anchor.fraction, 1e-6));
      }
      // E também ao desligar a voz (modo leitura).
      final silent = VideoTimeline.layout(video.lines, pace: VideoPace.reading);
      final moved = silent.timeOf(anchor.id, anchor.fraction)!;
      expect(silent.anchorAt(moved)!.id, anchor.id);
      expect(silent.anchorAt(moved)!.fraction, closeTo(anchor.fraction, 1e-6));
      expect(timeline.timeOf('nao.existe', 0), isNull);
    });

    test('Vídeo 9: sem voz ou sem áudio, a fala dura o tempo de leitura, '
        'com teto de 8 s', () {
      final long = 'palavra ' * 200;
      final lines = [
        VideoLine.fromJson({
          'id': 'com.audio',
          't': 'k1',
          'texto': long,
          'audio': 'a.opus',
          'ms': 30000,
          'tabuleiro': {'fen': start},
        }),
        VideoLine.fromJson({
          'id': 'sem.audio',
          't': 'k2',
          'texto': long,
          'ms': 30000,
          'tabuleiro': {'fen': start},
        }),
      ];
      // Com voz: só a fala sem arquivo cai no tempo de leitura.
      final voice = VideoTimeline.layout(lines);
      expect(voice.lines[0].voiceLength, const Duration(seconds: 30));
      expect(voice.lines[1].voiceLength, VideoTimeline.maxReading);
      // Voz desligada: as duas, com teto de 8 s.
      final reading = VideoTimeline.layout(lines, pace: VideoPace.reading);
      expect(reading.lines[0].voiceLength, VideoTimeline.maxReading);
      expect(reading.lines[1].voiceLength, VideoTimeline.maxReading);
      // Sem som não há voz no ar para o áudio tocar.
      expect(reading.hasVoice, isFalse);
      expect(voice.hasVoice, isTrue);
    });
  });
}
