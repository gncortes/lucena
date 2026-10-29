import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/script_fixture.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';

/// Posição final da demonstração do erro do atacante (depois de 2.Re3 Re5).
const _finalFen = '8/8/8/3k4/8/3K4/5P2/8 w - - 4 3';

Future<LessonScriptCubit> _open(Map<String, dynamic> json) async {
  final script = LessonScript.fromJson(json);
  final cubit = LessonScriptCubit(
    lessonId: script.lessonId,
    partId: script.partId,
    scriptPath: 'roteiro.json',
    language: 'pt',
    scripts: FakeLessonScriptRepository(script, const {}),
    kpk: FakeKpkRepository(FakeKpkOracle()),
    source: FakeLessonSource(),
    initialStage: 0,
    delay: (_) async {},
  );
  addTearDown(cubit.close);
  await cubit.start();
  return cubit;
}

Future<void> _untilEnd(LessonScriptCubit cubit) async {
  for (var i = 0; i < 20 && cubit.state.phase != ScriptPhase.fimEtapa; i++) {
    await cubit.onAction(ScriptAction.continuar);
  }
  expect(cubit.state.phase, ScriptPhase.fimEtapa);
}

void main() {
  group('fim da demonstração sintética', () {
    test(
      'o passo da ponte fica na posição final, com o último lance',
      () async {
        final cubit = await _open(demoToPractice());
        await _untilEnd(cubit);
        final s = cubit.state;
        expect(s.speech.last, 'demo.ponte');
        expect(s.fen, _finalFen);
        expect(s.lastMove, 'd6d5');
        expect(s.currentMoveId, s.moves.last.id);
        expect(s.moves.map((m) => m.san), ['Kd2', 'Kd6', 'Kd3', 'Kd5']);
      },
    );

    test('depois do último lance nenhuma posição volta à de Rd2', () async {
      final cubit = await _open(demoToPractice());
      final fens = <String>[];
      for (
        var i = 0;
        i < 20 && cubit.state.phase != ScriptPhase.fimEtapa;
        i++
      ) {
        await cubit.onAction(ScriptAction.continuar);
        fens.add(cubit.state.fen);
      }
      expect(fens.sublist(fens.indexOf(_finalFen)), everyElement(_finalFen));
    });

    test('voltar (◀) mostra o estado do passo anterior', () async {
      final cubit = await _open(demoToPractice());
      await _untilEnd(cubit);
      cubit.back();
      expect(cubit.state.phase, isNot(ScriptPhase.fimEtapa));
      expect(cubit.state.canBack, isTrue);
      cubit.back();
      cubit.back();
      // Mais atrás, a posição já é a de um passo anterior da linha.
      expect(cubit.state.fen, isNot(_finalFen));
    });

    test('a prática abre na posição dela', () async {
      final cubit = await _open(demoToPractice());
      await _untilEnd(cubit);
      await cubit.onAction(ScriptAction.proximaEtapa);
      expect(cubit.state.stageId, 'pratica');
      expect(cubit.state.fen, startsWith('4k3/8/8/8/8/1P3K2/8/8'));
    });
  });
}
