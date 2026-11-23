import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';
import 'package:lucena/domain/use_cases/video_resume.dart';
import 'package:lucena/domain/use_cases/video_timeline.dart';

import '../../../testing/lesson_video_fixture.dart';

Duration ms(int value) => Duration(milliseconds: value);

void main() {
  // Linha principal do fixture: e.1 0–2500, p 2500–5000 (pergunta em 4500),
  // certo.1 5000–8000, l.1 8000–9000.
  late VideoTimeline timeline;

  setUp(() => timeline = VideoTimeline.layout(sampleLessonVideo().lines));

  group('pointFrom', () {
    test('nada salvo: 0:00, sem aviso', () {
      expect(VideoResume.pointFrom(timeline, null), const VideoResumePoint());
    });

    test('Vídeo 15: fechar à força e reabrir = começo da fala salva, com '
        'aviso', () {
      final point = VideoResume.pointFrom(
        timeline,
        const VideoProgress(
          line: 'ideia.ex1.certo.1',
          fraction: 0.6,
          resolved: {'ideia.ex1.p'},
        ),
      );
      expect(point.at, ms(5000));
      expect(point.notice, isTrue);
      expect(point.resolved, {'ideia.ex1.p'});
    });

    test('Vídeo 31: pergunta sem resposta volta esperando na pergunta', () {
      final point = VideoResume.pointFrom(
        timeline,
        const VideoProgress(line: 'ideia.ex1.certo.1', fraction: 0.2),
      );
      expect(point.at, ms(4500));
      expect(timeline.frameAt(point.at).atGate, isTrue);
    });

    test('Vídeo 31: resposta já dada não repergunta', () {
      final point = VideoResume.pointFrom(
        timeline,
        const VideoProgress(
          line: 'ideia.ex1.p',
          fraction: 0.9,
          resolved: {'ideia.ex1.p'},
        ),
      );
      expect(point.at, ms(2500));
      expect(
        timeline.frameAt(ms(4500), resolved: point.resolved).atGate,
        isFalse,
      );
    });

    test('salvo na primeira fala: 0:00 e sem aviso', () {
      final point = VideoResume.pointFrom(
        timeline,
        const VideoProgress(line: 'ideia.ex1.e.1', fraction: 0.5),
      );
      expect(point.at, Duration.zero);
      expect(point.notice, isFalse);
    });

    test('fala que saiu do roteiro: recomeça do início', () {
      final point = VideoResume.pointFrom(
        timeline,
        const VideoProgress(line: 'fala.removida', fraction: 0.5),
      );
      expect(point, const VideoResumePoint());
    });

    test('resposta de pergunta que não existe mais é descartada', () {
      final point = VideoResume.pointFrom(
        timeline,
        const VideoProgress(
          line: 'ideia.ex1.l.1',
          resolved: {'ideia.ex1.p', 'pergunta.removida'},
        ),
      );
      expect(point.resolved, {'ideia.ex1.p'});
      expect(point.at, ms(8000));
    });
  });

  group('progressAt', () {
    test('Vídeo 16: sair no meio guarda fala, fração e respondidas', () {
      final saved = VideoResume.progressAt(timeline, ms(6500), {'ideia.ex1.p'});
      expect(saved?.line, 'ideia.ex1.certo.1');
      expect(saved?.fraction, closeTo(0.5, 0.001));
      expect(saved?.resolved, {'ideia.ex1.p'});
    });

    test('em 0:00 sem resposta não há o que guardar', () {
      expect(VideoResume.progressAt(timeline, Duration.zero, {}), isNull);
    });

    test('no fim não guarda (a etapa concluída reabre em 0:00)', () {
      expect(VideoResume.progressAt(timeline, timeline.total, {}), isNull);
    });

    test('ida e volta: o que se guarda reabre no começo da mesma fala', () {
      final saved = VideoResume.progressAt(timeline, ms(8600), {'ideia.ex1.p'});
      final point = VideoResume.pointFrom(timeline, saved);
      expect(point.at, ms(8000));
      expect(point.notice, isTrue);
    });

    test('Vídeo 8: a fala salva vale em outra velocidade', () {
      final saved = VideoResume.progressAt(timeline, ms(6500), {'ideia.ex1.p'});
      final fast = VideoTimeline.layout(sampleLessonVideo().lines, rate: 2);
      final point = VideoResume.pointFrom(fast, saved);
      expect(fast.anchorAt(point.at)?.id, 'ideia.ex1.certo.1');
      expect(fast.anchorAt(point.at)?.fraction, 0);
    });
  });
}
