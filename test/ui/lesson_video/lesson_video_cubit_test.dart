import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_video/video_interruptions_repository.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';

import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_video_repository.dart';
import '../../../testing/fakes/fake_video_interruptions_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/script_fixture.dart';

/// Um repositório que não abre o roteiro.
class _BrokenScripts implements LessonScriptRepository {
  @override
  Future<LessonScript> script(String path) async =>
      throw StateError('sem roteiro');

  @override
  Future<ScriptTexts> texts(String lessonId, String language) async =>
      ScriptTexts.empty;
}

void main() {
  late FakeNow now;
  late FakeLessonVideoRepository videos;
  late FakeVideoInterruptionsRepository interruptions;

  setUp(() {
    now = FakeNow(DateTime(2026, 11, 23, 10));
    videos = FakeLessonVideoRepository();
    interruptions = FakeVideoInterruptionsRepository();
  });

  LessonVideoCubit build({
    String stage = 'ideia',
    bool autoplay = true,
    LessonScriptRepository? scripts,
  }) {
    final cubit = LessonVideoCubit(
      scripts:
          scripts ?? FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
      videos: videos,
      interruptions: interruptions,
      now: now,
      lessonId: 'pawns.test',
      partId: 'distant',
      scriptPath: 'roteiro.json',
      stage: stage,
      autoplay: autoplay,
      ticker: (_, _) => null,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('start carrega o roteiro e fica pronto, no 0:00', () async {
    final cubit = build(autoplay: false);
    expect(cubit.state.status, LessonVideoStatus.loading);
    await cubit.start();
    final s = cubit.state;
    expect(s.status, LessonVideoStatus.ready);
    expect(s.frame, isNotNull);
    expect(s.position, Duration.zero);
    expect(s.total, greaterThan(Duration.zero));
    expect(s.playing, isFalse);
    expect(s.chapters, isNotEmpty);
  });

  test('autoplay toca e o tique avança a posição com o Now', () async {
    final cubit = build();
    await cubit.start();
    expect(cubit.state.playing, isTrue);
    expect(cubit.state.position, Duration.zero);
    now.advance(const Duration(milliseconds: 700));
    cubit.tick();
    expect(cubit.state.position, const Duration(milliseconds: 700));
    now.advance(const Duration(milliseconds: 300));
    cubit.tick();
    expect(cubit.state.position, const Duration(seconds: 1));
  });

  test('pausa congela a posição', () async {
    final cubit = build();
    await cubit.start();
    now.advance(const Duration(milliseconds: 500));
    cubit.pause();
    expect(cubit.state.playing, isFalse);
    expect(cubit.state.position, const Duration(milliseconds: 500));
    now.advance(const Duration(seconds: 3));
    cubit.tick();
    expect(cubit.state.position, const Duration(milliseconds: 500));
    cubit.toggle();
    expect(cubit.state.playing, isTrue);
    now.advance(const Duration(milliseconds: 200));
    cubit.tick();
    expect(cubit.state.position, const Duration(milliseconds: 700));
  });

  test('seek não passa da primeira pergunta sem resposta', () async {
    final cubit = build(autoplay: false);
    await cubit.start();
    final s = cubit.state;
    expect(s.gates, isNotEmpty, reason: 'a fixture da Teoria tem pergunta');
    expect(s.reachable, lessThan(s.total));
    cubit.seek(s.total);
    expect(cubit.state.position, s.reachable);
    cubit.seek(const Duration(milliseconds: 300));
    expect(cubit.state.position, const Duration(milliseconds: 300));
  });

  test('skip ±10 s anda dez segundos dentro do alcance', () async {
    final cubit = build(stage: 'demos', autoplay: false);
    await cubit.start();
    final reachable = cubit.state.reachable;
    Duration clamp(Duration d) =>
        d < Duration.zero ? Duration.zero : (d > reachable ? reachable : d);

    cubit.seek(const Duration(seconds: 1));
    cubit.skip(LessonVideoCubit.skipStep);
    expect(cubit.state.position, clamp(const Duration(seconds: 11)));
    final at = cubit.state.position;
    cubit.skip(-LessonVideoCubit.skipStep);
    expect(cubit.state.position, clamp(at - const Duration(seconds: 10)));
    expect(cubit.state.position, greaterThanOrEqualTo(Duration.zero));
  });

  test('cycleRate passa por 0,75–2 e volta, dentro do total', () async {
    final cubit = build(stage: 'demos', autoplay: false);
    await cubit.start();
    final total1x = cubit.state.total;
    cubit.seek(total1x ~/ 2);
    final seen = <double>[];
    for (var i = 0; i < VideoSettings.rates.length; i++) {
      cubit.cycleRate();
      seen.add(cubit.state.rate);
      expect(cubit.state.position, lessThanOrEqualTo(cubit.state.total));
      expect(cubit.state.position, greaterThanOrEqualTo(Duration.zero));
    }
    expect(seen, [1.25, 1.5, 2.0, 0.75, 1.0]);
    expect(seen.toSet(), VideoSettings.rates.toSet());
    expect(cubit.state.total, total1x);
  });

  test('para na pergunta: waiting, sem tocar, e play não sai dali', () async {
    final cubit = build();
    await cubit.start();
    final gate = cubit.state.reachable;
    now.advance(gate + const Duration(seconds: 5));
    cubit.tick();
    expect(cubit.state.position, gate);
    expect(cubit.state.waiting, isTrue);
    expect(cubit.state.playing, isFalse);
    expect(cubit.state.ended, isFalse);
    cubit.play();
    expect(cubit.state.playing, isFalse);
  });

  test('chega ao fim (ended) e restart volta ao 0:00 tocando', () async {
    final cubit = build(stage: 'demos');
    await cubit.start();
    final total = cubit.state.total;
    now.advance(total + const Duration(seconds: 2));
    cubit.tick();
    expect(cubit.state.ended, isTrue);
    expect(cubit.state.playing, isFalse);
    expect(cubit.state.position, total);

    cubit.restart();
    expect(cubit.state.position, Duration.zero);
    expect(cubit.state.playing, isTrue);
    expect(cubit.state.ended, isFalse);
    now.advance(const Duration(milliseconds: 400));
    cubit.tick();
    expect(cubit.state.position, const Duration(milliseconds: 400));
  });

  test('repositório que lança deixa a aula em failed', () async {
    final cubit = build(scripts: _BrokenScripts());
    await cubit.start();
    expect(cubit.state.status, LessonVideoStatus.failed);
  });

  group('retomada e interrupções (L3)', () {
    const key = 'pawns.test.distant.demos';

    test(
      'pausa no meio salva a fala; reabrir fica pausado com aviso',
      () async {
        final cubit = build(stage: 'demos');
        await cubit.start();
        now.advance(const Duration(seconds: 12));
        cubit.pause();
        await Future<void>.delayed(Duration.zero);
        expect(videos.saved[key], isNotNull);

        final again = build(stage: 'demos');
        await again.start();
        expect(again.state.notice, isTrue);
        expect(again.state.playing, isFalse);
        expect(again.state.position, greaterThan(Duration.zero));
        expect(
          again.state.position,
          lessThanOrEqualTo(const Duration(seconds: 12)),
        );

        again.play();
        expect(again.state.notice, isFalse);
        expect(again.state.playing, isTrue);
      },
    );

    test(
      '"Recomeçar do início" volta a 0:00 tocando e esquece o salvo',
      () async {
        final cubit = build(stage: 'demos');
        await cubit.start();
        now.advance(const Duration(seconds: 12));
        cubit.pause();
        final again = build(stage: 'demos');
        await again.start();
        again.restart();
        await Future<void>.delayed(Duration.zero);
        expect(again.state.position, Duration.zero);
        expect(again.state.playing, isTrue);
        expect(again.state.notice, isFalse);
        expect(videos.saved[key], isNull);
      },
    );

    test(
      'chegar ao fim da etapa esquece o progresso (reabre em 0:00)',
      () async {
        final cubit = build(stage: 'demos');
        await cubit.start();
        now.advance(const Duration(seconds: 5));
        cubit.pause();
        await Future<void>.delayed(Duration.zero);
        expect(videos.saved[key], isNotNull);
        cubit.play();
        now.advance(cubit.state.total);
        cubit.tick();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.ended, isTrue);
        expect(videos.saved[key], isNull);
      },
    );

    for (final event in VideoInterruption.values) {
      test(
        'interrupção ${event.name} pausa, salva e não volta tocando',
        () async {
          final cubit = build(stage: 'demos');
          await cubit.start();
          now.advance(const Duration(seconds: 8));
          interruptions.emit(event);
          await Future<void>.delayed(Duration.zero);
          expect(cubit.state.playing, isFalse);
          expect(videos.saved[key], isNotNull);
          now.advance(const Duration(seconds: 30));
          cubit.tick();
          expect(cubit.state.playing, isFalse);
        },
      );
    }

    test('close cancela a assinatura das interrupções', () async {
      final cubit = build(stage: 'demos');
      await cubit.start();
      expect(interruptions.hasListener, isTrue);
      await cubit.close();
      expect(interruptions.hasListener, isFalse);
    });

    test('velocidade e legenda salvas voltam ao abrir', () async {
      final cubit = build(autoplay: false);
      await cubit.start();
      cubit
        ..cycleRate()
        ..toggleCaptions();
      await Future<void>.delayed(Duration.zero);
      expect(videos.current.rate, 1.25);
      expect(videos.current.captions, isFalse);

      final again = build(autoplay: false);
      await again.start();
      expect(again.state.rate, 1.25);
      expect(again.state.captions, isFalse);
    });
  });
}
