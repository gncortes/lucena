import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_video/video_interruptions_repository.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';
import 'package:lucena/domain/use_cases/lesson_video_converter.dart';
import 'package:lucena/domain/use_cases/video_timeline.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';

import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_video_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_video_interruptions_repository.dart';
import '../../../testing/script_fixture.dart';

/// Testes que quebram antes (RED) do `LessonVideoCubit` da aula em vídeo.
///
/// Gaps de `docs/fluxos/aula-video.md` ("Matriz de gaps", Vídeo N), lote de
/// cada um em `docs/tasks/T-aula-video-contrato.md` ("Testes que quebram
/// antes" e "Lotes"). O nome do teste é o gap; o `skip` diz o lote que o
/// resolve e sai quando o lote entra (o corpo vira o teste de verdade).
/// Vídeo 4, 6, 8 e 9 no domínio já estão em `video_timeline_test.dart`.
void main() {
  late FakeNow now;
  late FakeLessonVideoRepository videos;
  late FakeVideoInterruptionsRepository interruptions;

  setUp(() {
    now = FakeNow(DateTime(2026, 11, 23, 10));
    videos = FakeLessonVideoRepository();
    interruptions = FakeVideoInterruptionsRepository();
  });

  LessonVideoCubit build({String stage = 'ideia', bool autoplay = true}) {
    final cubit = LessonVideoCubit(
      scripts: FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
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

  /// A mesma linha do tempo que o cubit monta (modo leitura), para conferir
  /// quadro, fala e fração de fora.
  VideoTimeline reference(String stage, {double rate = 1}) =>
      VideoTimeline.layout(
        LessonVideoConverter.convert(
          scriptFixture(),
          ScriptTexts(scriptTexts()),
          language: 'pt',
        ).stage(stage).lines,
        pace: VideoPace.reading,
        rate: rate,
      );

  /// O primeiro lance animado (não salto) da etapa.
  BoardKey firstMove(VideoTimeline t) =>
      t.keys.firstWhere((k) => k.move != null && !k.jump);

  List<String> gateIds(VideoTimeline t) => [
    for (final g in t.gates) t.lines[g.line].line.id,
  ];

  group('gaps', () {
    test(
      'Vídeo 3: arrastar a barra para trás e para a frente → tabuleiro e '
      'legenda acompanham sem animar lance; ao soltar, toca dali se tocava',
      () async {
        final ref = reference('demos');
        final cubit = build(stage: 'demos');
        await cubit.start();
        final total = cubit.state.total;
        now.advance(total * 0.6);
        cubit.tick();
        expect(cubit.state.playing, isTrue);

        // O arrastar da barra é seek(): para trás e para a frente, fora da
        // janela de um lance.
        final move = firstMove(ref).at;
        for (final t in [
          const Duration(seconds: 1),
          move - const Duration(milliseconds: 500),
          move + const Duration(seconds: 2),
          total - const Duration(milliseconds: 500),
        ]) {
          cubit.seek(t);
          final s = cubit.state;
          final expected = ref.frameAt(t);
          expect(s.position, t);
          expect(s.frame!.fen, expected.fen, reason: 'tabuleiro em $t');
          expect(s.frame!.caption, expected.caption, reason: 'legenda em $t');
          expect(s.frame!.animating, isFalse, reason: 'sem animar em $t');
          expect(s.playing, isTrue, reason: 'tocava: continua tocando');
        }

        // Pausado, o arrastar não faz tocar.
        cubit
          ..pause()
          ..seek(const Duration(seconds: 2));
        expect(cubit.state.playing, isFalse);
        expect(cubit.state.position, const Duration(seconds: 2));
      },
    );

    test(
      'Vídeo 3: arrastar a barra para dentro dos 400 ms de um lance → o '
      'tabuleiro vai à posição sem animar o lance',
      () async {
        final ref = reference('demos');
        final cubit = build(stage: 'demos', autoplay: false);
        await cubit.start();
        final move = firstMove(ref).at;
        cubit.seek(move + const Duration(milliseconds: 100));
        expect(cubit.state.frame!.fen, ref.frameAt(move).fen);
        expect(cubit.state.frame!.animating, isFalse);
      },
      skip:
          'L1: seek() que cai até 400 ms depois de um lance devolve '
          'frame.animating = true (frameAt puro), e a tela anima o lance ao '
          'arrastar',
    );

    test('Vídeo 4: arrastar além da pergunta sem resposta → para no instante '
        'da pergunta (reachable)', () {
      // Arrange: pergunta sem resposta em 40 s. Act: seek(55 s).
      // Assert: posição = 40 s e estado "sua vez" esperando.
    }, skip: 'L2: sua vez e limite da barra no cubit');

    test(
      'Vídeo 6: −10 s no meio da animação de um lance → corta a animação e '
      'mostra o quadro de t; o lance anima de novo quando t passa por ele',
      () async {
        final ref = reference('demos');
        final cubit = build(stage: 'demos', autoplay: false);
        await cubit.start();
        final move = firstMove(ref).at;
        cubit.seek(move + const Duration(milliseconds: 200));
        expect(cubit.state.frame!.animating, isTrue, reason: 'pré-condição');

        cubit.skip(-LessonVideoCubit.skipStep);
        final back = cubit.state.position;
        final expected =
            move +
            const Duration(milliseconds: 200) -
            LessonVideoCubit.skipStep;
        expect(back, expected < Duration.zero ? Duration.zero : expected);
        expect(cubit.state.frame!.animating, isFalse);
        expect(cubit.state.frame!.fen, ref.frameAt(back).fen);

        cubit.play();
        now.advance(move + const Duration(milliseconds: 100) - back);
        cubit.tick();
        expect(cubit.state.frame!.animating, isTrue);
        expect(cubit.state.frame!.lastMove, firstMove(ref).move);
      },
    );

    test('Vídeo 7: −10 s antes de 0:00 / +10 s além do fim ou da pergunta → '
        'para em 0:00, no fim da etapa (rodapé) ou na pergunta', () async {
      final demos = build(stage: 'demos', autoplay: false);
      await demos.start();
      demos
        ..seek(const Duration(seconds: 4))
        ..skip(-LessonVideoCubit.skipStep);
      expect(demos.state.position, Duration.zero);

      final total = demos.state.total;
      demos
        ..seek(total - const Duration(seconds: 5))
        ..skip(LessonVideoCubit.skipStep);
      expect(demos.state.position, total);
      expect(demos.state.ended, isTrue, reason: 'fim da etapa = rodapé');

      final ideia = build(autoplay: false);
      await ideia.start();
      final gate = ideia.state.gates.first;
      ideia
        ..seek(gate - const Duration(seconds: 3))
        ..skip(LessonVideoCubit.skipStep);
      expect(ideia.state.position, gate);
      expect(ideia.state.waiting, isTrue);
      expect(ideia.state.ended, isFalse);
    });

    test('Vídeo 8: mudar a velocidade no meio da fala → mantém fala e fração; '
        'ciclo 0,75→1→1,25→1,5→2→0,75; preferência salva', () async {
      videos = FakeLessonVideoRepository(
        current: const VideoSettings(rate: 0.75),
      );
      final cubit = build(autoplay: false);
      await cubit.start();
      expect(cubit.state.rate, 0.75);
      final line = reference('ideia', rate: 0.75).lines[2].line.id;
      cubit.seek(reference('ideia', rate: 0.75).timeOf(line, 0.4)!);

      final seen = <double>[];
      for (var i = 0; i < 5; i++) {
        cubit.cycleRate();
        final rate = cubit.state.rate;
        seen.add(rate);
        final anchor = reference(
          'ideia',
          rate: rate,
        ).anchorAt(cubit.state.position)!;
        expect(anchor.id, line, reason: 'fala na velocidade $rate');
        expect(anchor.fraction, closeTo(0.4, 0.01), reason: 'fração em $rate');
      }
      expect(seen, [1.0, 1.25, 1.5, 2.0, 0.75]);
      await Future<void>.delayed(Duration.zero);
      expect(videos.current.rate, 0.75);
    });

    test('Vídeo 14: sair para outro app no meio e voltar → pausa ao sair e '
        'volta pausado no mesmo instante', () async {
      final cubit = build(stage: 'demos');
      await cubit.start();
      now.advance(const Duration(seconds: 6));
      cubit.tick();
      expect(cubit.state.playing, isTrue);

      interruptions.emit(VideoInterruption.background);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.playing, isFalse);
      expect(cubit.state.position, const Duration(seconds: 6));

      // Volta ao app: nenhum evento toca de novo; o tempo passa parado.
      now.advance(const Duration(minutes: 2));
      cubit.tick();
      expect(cubit.state.playing, isFalse);
      expect(cubit.state.position, const Duration(seconds: 6));
    });

    test(
      'Vídeo 15: fechar à força e reabrir → pausado no começo da fala salva, '
      'com aviso "Você parou aqui"',
      () async {
        final ref = reference('ideia');
        final line = ref.lines[3];
        videos.saved['pawns.test.distant.ideia'] = VideoProgress(
          line: line.line.id,
          fraction: 0.5,
        );
        final cubit = build();
        await cubit.start();
        expect(cubit.state.playing, isFalse);
        expect(cubit.state.notice, isTrue);
        expect(cubit.state.position, ref.reachable(line.start, const {}));
        expect(cubit.state.position, greaterThan(Duration.zero));
      },
    );

    test('Vídeo 16: seta voltar no meio → salva fala, fração e respondidas; '
        'reabrir = Vídeo 15', () async {
      final ref = reference('ideia');
      final answered = gateIds(ref).first;
      const key = 'pawns.test.distant.ideia';
      videos.saved[key] = VideoProgress(
        line: ref.lines.first.line.id,
        fraction: 0,
        resolved: {answered},
      );
      final cubit = build(autoplay: false);
      await cubit.start();
      final line = ref.lines[1].line.id;
      cubit.seek(ref.timeOf(line, 0.6)!);

      await cubit.close();
      await Future<void>.delayed(Duration.zero);
      final saved = videos.saved[key]!;
      expect(saved.line, line);
      expect(saved.fraction, closeTo(0.6, 0.01));
      expect(saved.resolved, contains(answered));
    });

    test('Vídeo 26: sua vez, erro → ✗ na casa, a peça volta, dica falada; '
        'continua esperando', () {
      // Arrange: sua vez esperando. Act: lance errado.
      // Assert: marca de erro na casa, posição da pergunta, fala da dica,
      // estado ainda esperando.
    }, skip: 'L2: sua vez (erro com dica) no cubit');

    test('Vídeo 27: sua vez, erra de novo / não sabe → "Ver a resposta" a '
        'partir do 2º erro', () {
      // Act: dois lances errados. Assert: revelar disponível só depois do
      // 2º erro; revelar joga o lance certo e segue.
    }, skip: 'L2: sua vez (revelar resposta; pergunta 5 ao Gabriel)');

    test('Vídeo 28: sua vez, acerto → ✓ e o vídeo segue sozinho', () {
      // Act: lance certo. Assert: marca de acerto e estado volta a tocar
      // a partir da fala seguinte à pergunta.
    }, skip: 'L2: sua vez (acerto) no cubit');

    test('Vídeo 29: sua vez, alternativa boa → fala curta própria e volta à '
        'linha principal', () {
      // Act: lance alternativo aceito. Assert: toca a fala da alternativa e
      // retoma depois das falas que são só do lance certo.
    }, skip: 'L2: sua vez (alternativa) no cubit');

    test('Vídeo 30: sua vez, peça fora de pecas ou lance fora da lista → ramo '
        'fora (fala) e volta a esperar', () {
      // Act: lance com peça fora de `pecas`. Assert: fala do ramo `fora`,
      // peça volta e estado esperando.
    }, skip: 'L2: sua vez (ramo fora) no cubit');

    test('Vídeo 31: sua vez e 2º plano / fechar à força → volta na pergunta '
        'esperando; resposta já dada não repergunta', () async {
      final ref = reference('ideia');
      final ids = gateIds(ref);
      expect(ids, hasLength(2), reason: 'a Teoria da fixture tem 2 perguntas');
      final gates = ref.gates.toList();
      final second = ref.lines[gates[1].line];
      videos.saved['pawns.test.distant.ideia'] = VideoProgress(
        line: second.line.id,
        fraction: 0.3,
        resolved: {ids.first},
      );
      final cubit = build();
      await cubit.start();
      // Reabre pausado no começo da fala da 2ª pergunta (a regra do
      // VideoResume: a fala inteira), já depois da 1ª.
      expect(cubit.state.playing, isFalse);
      expect(cubit.state.notice, isTrue);
      expect(cubit.state.position, second.start);
      expect(cubit.state.position, greaterThan(gates[0].at));
      expect(cubit.state.reachable, gates[1].at);

      cubit.play();
      now.advance(gates[1].at - second.start + const Duration(seconds: 5));
      cubit.tick();
      expect(cubit.state.position, gates[1].at);
      expect(cubit.state.waiting, isTrue);
    });

    test('Vídeo 39: ligação, fone desconectado ou outro app toca som → pausa e '
        'não volta sozinho', () async {
      for (final event in [
        VideoInterruption.inactive,
        VideoInterruption.audioFocus,
        VideoInterruption.noisy,
      ]) {
        final cubit = build(stage: 'demos');
        await cubit.start();
        now.advance(const Duration(seconds: 3));
        interruptions.emit(event);
        await Future<void>.delayed(Duration.zero);
        final at = cubit.state.position;
        expect(cubit.state.playing, isFalse, reason: event.name);
        now.advance(const Duration(seconds: 30));
        cubit.tick();
        expect(cubit.state.playing, isFalse, reason: event.name);
        expect(cubit.state.position, at, reason: event.name);
        await cubit.close();
      }
    });
  });
}
