import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';

import '../../../testing/fakes/fake_lesson_script_repository.dart';
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

  setUp(() => now = FakeNow(DateTime(2026, 11, 23, 10)));

  LessonVideoCubit build({
    String stage = 'ideia',
    bool autoplay = true,
    LessonScriptRepository? scripts,
  }) {
    final cubit = LessonVideoCubit(
      scripts:
          scripts ?? FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
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
}
