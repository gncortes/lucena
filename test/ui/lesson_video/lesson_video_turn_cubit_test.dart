import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/video_turn.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';

import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/script_fixture.dart';

/// O roteiro de teste com as perguntas no juiz `lista` (sem jogo livre): as
/// que o vídeo julga. As do fixture original são legado (Notas do L2).
Map<String, dynamic> _listaJson() {
  final json = scriptJson();
  void walk(Object? node) {
    if (node is Map) {
      final q = node['pergunta'];
      if (q is Map) {
        q
          ..['juiz'] = 'lista'
          ..remove('livre');
      }
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  walk(json);
  return json;
}

void main() {
  // Pergunta 1 do roteiro de teste: certo d3e4, erro d3d4 (2 falas).
  // Pergunta 2: certo e8e7, alternativa e8f7, erro e8f8.
  late FakeNow now;

  setUp(() => now = FakeNow(DateTime(2026, 11, 23, 10)));

  Future<LessonVideoCubit> atFirstGate() async {
    final cubit = LessonVideoCubit(
      scripts: FakeLessonScriptRepository(
        LessonScript.fromJson(_listaJson()),
        scriptTexts(),
      ),
      now: now,
      lessonId: 'pawns.test',
      partId: 'distant',
      scriptPath: 'roteiro.json',
      autoplay: false,
      ticker: (_, _) => null,
    );
    addTearDown(cubit.close);
    await cubit.start();
    cubit.seek(cubit.state.gates.first);
    return cubit;
  }

  /// Avança o relógio até o ramo acabar.
  void finishBranch(LessonVideoCubit cubit) {
    for (var i = 0; i < 200 && (cubit.state.turn?.inBranch ?? false); i++) {
      now.advance(const Duration(seconds: 1));
      cubit.tick();
    }
  }

  test(
    'Vídeo 25: na pergunta o vídeo espera e o tabuleiro aceita lance',
    () async {
      final cubit = await atFirstGate();
      final s = cubit.state;
      expect(s.waiting, isTrue);
      expect(s.playing, isFalse);
      expect(s.turn?.awaitingMove, isTrue);
      cubit.play();
      expect(
        cubit.state.playing,
        isFalse,
        reason: 'play não passa da pergunta',
      );
    },
  );

  test('Vídeo 4: arrastar além da pergunta sem resposta para nela', () async {
    final cubit = await atFirstGate();
    final gate = cubit.state.gates.first;
    cubit.seek(gate + const Duration(seconds: 30));
    expect(cubit.state.position, gate);
    expect(cubit.state.waiting, isTrue);
  });

  test(
    'Vídeo 26: erro toca a dica (tabuleiro parado), ✗ e volta a esperar',
    () async {
      final cubit = await atFirstGate();
      final gate = cubit.state.position;
      cubit.onMove('d3d4');
      expect(cubit.state.turn?.inBranch, isTrue);
      expect(cubit.state.turn?.awaitingMove, isFalse);
      expect(cubit.state.turn?.wrongSquare, 'd4');
      cubit.onMove('d3e4');
      expect(cubit.state.turn?.inBranch, isTrue, reason: 'sem lance no ramo');
      finishBranch(cubit);
      final s = cubit.state;
      expect(s.waiting, isTrue);
      expect(s.position, gate);
      expect(s.turn?.last, TurnResult.wrong);
      expect(s.turn?.awaitingMove, isTrue);
      expect(s.turn?.canReveal, isFalse);
    },
  );

  test('Vídeo 27: "Ver a resposta" a partir do 2º erro, e segue', () async {
    final cubit = await atFirstGate();
    cubit.reveal();
    expect(cubit.state.turn?.inBranch, isNot(true));
    cubit.onMove('d3d4');
    finishBranch(cubit);
    cubit.onMove('d3c2');
    finishBranch(cubit);
    expect(cubit.state.turn?.canReveal, isTrue);
    final gate = cubit.state.position;
    cubit.reveal();
    finishBranch(cubit);
    expect(cubit.state.waiting, isFalse);
    expect(cubit.state.playing, isTrue);
    expect(cubit.state.position, greaterThanOrEqualTo(gate));
    expect(cubit.state.turn, isNull);
  });

  test('Vídeo 28: acerto segue sozinho e não repergunta', () async {
    final cubit = await atFirstGate();
    final gate = cubit.state.position;
    cubit.onMove('d3e4');
    finishBranch(cubit);
    expect(cubit.state.playing, isTrue);
    expect(cubit.state.waiting, isFalse);
    expect(cubit.state.turn?.last, TurnResult.right, reason: '✓ na tela');
    now.advance(LessonVideoCubit.sealHold);
    cubit.tick();
    expect(cubit.state.turn, isNull);
    cubit
      ..pause()
      ..seek(gate)
      ..seek(gate + const Duration(seconds: 1));
    expect(cubit.state.position, greaterThan(gate));
  });

  test(
    'Vídeo 29: alternativa boa fala e volta à linha depois das do certo',
    () async {
      final cubit = await atFirstGate();
      cubit.onMove('d3e4');
      finishBranch(cubit);
      final second = cubit.state.gates[1];
      cubit
        ..pause()
        ..seek(second);
      expect(cubit.state.waiting, isTrue);
      cubit.onMove('e8f7');
      expect(cubit.state.turn?.inBranch, isTrue);
      finishBranch(cubit);
      expect(cubit.state.playing, isTrue);
      expect(cubit.state.position, greaterThan(second));
    },
  );

  test('legado (juiz ≠ lista): o vídeo pausa e não julga o lance', () async {
    final cubit = LessonVideoCubit(
      scripts: FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
      now: now,
      lessonId: 'pawns.test',
      partId: 'distant',
      scriptPath: 'roteiro.json',
      autoplay: false,
      ticker: (_, _) => null,
    );
    addTearDown(cubit.close);
    await cubit.start();
    cubit
      ..seek(cubit.state.gates.first)
      ..onMove('d3e4');
    expect(cubit.state.waiting, isTrue);
    expect(cubit.state.turn?.legacy, isTrue);
    expect(cubit.state.turn?.awaitingMove, isFalse);
  });

  test('Vídeo 30: lance fora da lista volta a esperar', () async {
    final cubit = await atFirstGate();
    final gate = cubit.state.position;
    cubit.onMove('d3c2');
    finishBranch(cubit);
    expect(cubit.state.waiting, isTrue);
    expect(cubit.state.position, gate);
    expect(cubit.state.turn?.last, TurnResult.outside);
  });
}
