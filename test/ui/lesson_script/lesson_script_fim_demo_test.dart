import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';

/// Posição final da demonstração do erro do atacante (depois de 2.Re3 Re5).
const _finalFen = '8/8/8/4k3/8/4K3/6P1/8 w - - 4 3';

const _roteiro = 'assets/lessons/roteiros/pawns.distantOpposition.json';

/// A Oposição distante só com o exemplo `erroAtacante` (fim da demo) e a
/// prática (o que vem depois da etapa).
Map<String, dynamic> demoToPractice() {
  final json =
      jsonDecode(io.File(_roteiro).readAsStringSync()) as Map<String, dynamic>;
  final stages = (json['etapas'] as List).cast<Map<String, dynamic>>();
  final demos = stages.firstWhere((s) => s['id'] == 'demos');
  demos['exemplos'] = [
    for (final e in (demos['exemplos'] as List).cast<Map<String, dynamic>>())
      if (e['id'] == 'erroAtacante') e,
  ];
  return {
    ...json,
    'etapas': [demos, stages.firstWhere((s) => s['id'] == 'pratica')],
  };
}

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
  group('fim da demonstração (Oposição distante)', () {
    test(
      'o passo da ponte fica na posição final, com o último lance',
      () async {
        final cubit = await _open(demoToPractice());
        await _untilEnd(cubit);
        final s = cubit.state;
        expect(s.speech.last, 'rot.demos.erroAtacante.ponte');
        expect(s.fen, _finalFen);
        expect(s.lastMove, 'e6e5');
        expect(s.currentMoveId, s.moves.last.id);
        expect(s.moves.map((m) => m.san), ['Ke2', 'Ke6', 'Ke3', 'Ke5']);
      },
    );

    test('depois do último lance nenhuma posição volta à de Re2', () async {
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

  test('em todo roteiro, passo de ponte não troca a posição nem salta', () {
    var found = 0;
    void walk(String file, Object? node) {
      if (node is Map) {
        for (final list in node.values.whereType<List>()) {
          final maps = list.whereType<Map>().toList();
          for (var i = 1; i < maps.length; i++) {
            final t = maps[i]['t'];
            if (t is! String || !t.endsWith('.ponte')) continue;
            found++;
            expect(maps[i]['fen'], maps[i - 1]['fen'], reason: '$file $t');
            expect(maps[i]['salto'], isNull, reason: '$file $t');
            expect(maps[i - 1]['salto'], isNull, reason: '$file $t');
          }
        }
        for (final v in node.values) {
          walk(file, v);
        }
      } else if (node is List) {
        for (final v in node) {
          walk(file, v);
        }
      }
    }

    final dir = io.Directory('assets/lessons/roteiros');
    for (final f in dir.listSync().whereType<io.File>()) {
      walk(f.path, jsonDecode(f.readAsStringSync()));
    }
    expect(found, greaterThan(0));
  });
}
