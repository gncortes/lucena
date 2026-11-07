import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';

/// Lê o conteúdo real da Escola (`assets/lessons`), sem o bundle.
class _Files extends AssetService {
  @override
  Future<String> loadString(String path) => File(path).readAsString();
}

/// T85-D3 (Escola), H-ESC-09 a 13: a lição da Escola com as falas e os
/// roteiros reais (A torre, Mate de torre).
void main() {
  if (!(Directory('assets/lessons/roteiros').existsSync())) {
    test(
      'private content required for full Escola scenarios',
      () {},
      skip: true,
    );
    return;
  }
  Future<({LessonScriptCubit cubit, FakeLessonSource source})> open(
    String lesson, {
    int stage = 0,
  }) async {
    final source = FakeLessonSource(endgame: false);
    final cubit = LessonScriptCubit(
      lessonId: lesson,
      partId: 'licao',
      scriptPath: AssetLessonScriptRepository.scriptPath(lesson),
      language: 'pt',
      scripts: AssetLessonScriptRepository(_Files()),
      kpk: FakeKpkRepository(FakeKpkOracle()),
      source: source,
      initialStage: stage,
      delay: (_) async {},
    );
    addTearDown(cubit.close);
    await cubit.start();
    return (cubit: cubit, source: source);
  }

  group('H-ESC-09 teoria: A torre', () {
    test('abre na teoria, com o Viktor falando e a barra no começo', () async {
      final r = await open('pieces.rook');
      final s = r.cubit.state;
      expect(s.stageId, 'ideia');
      expect(s.fen, '8/8/8/8/3R4/8/8/8 w - - 0 1');
      expect(s.speech.join(' '), contains('Vamos começar pela torre.'));
      expect(s.primary, ScriptAction.continuar);
      expect(r.cubit.progressSteps, 7);
      expect(r.cubit.progressValue, 0.5);
    });

    test('Continuar avança a teoria e a barra anda', () async {
      final r = await open('pieces.rook');
      final before = r.cubit.state.speech.join(' ');
      await r.cubit.onAction(ScriptAction.continuar);
      expect(r.cubit.state.speech.join(' '), isNot(before));
      expect(r.cubit.state.phase, isNot(ScriptPhase.pergunta));
    });
  });

  group('H-ESC-10 tarefa de movimento: estrelas', () {
    test('o pedido diz toque, com as estrelas em a6, f6 e f2', () async {
      final r = await open('pieces.rook', stage: 2);
      final s = r.cubit.state;
      expect(s.stageId, 'pratica');
      expect(s.fen, '8/8/8/8/8/8/8/R7 w - - 0 1');
      expect(s.stars.toSet(), {'a6', 'f6', 'f2'});
      expect(s.primary, isNull);
      // A lâmpada (dica) está ligada na tarefa.
      expect(r.cubit.canHint, isTrue);
      expect(s.speech.join(' '), isNot(contains('lique')));
    });

    test('as três estrelas pegas avançam sem botão', () async {
      final r = await open('pieces.rook', stage: 2);
      await r.cubit.onMove('a1a6');
      expect(r.cubit.state.stars.toSet(), {'f6', 'f2'});
      expect(r.cubit.state.stageId, 'pratica');
      await r.cubit.onMove('a6f6');
      await r.cubit.onMove('f6f2');
      expect(r.cubit.state.stars, isEmpty);
      expect(r.cubit.state.tone, ScriptTone.good);
    });

    test('lance fora da estrela não tira nenhuma', () async {
      final r = await open('pieces.rook', stage: 2);
      await r.cubit.onMove('a1a3');
      expect(r.cubit.state.stars.toSet(), {'a6', 'f6', 'f2'});
    });
  });

  group('H-ESC-11 a 13 desafio de mate: Mate de torre', () {
    Future<({LessonScriptCubit cubit, FakeLessonSource source})>
    question() async {
      final r = await open('technique.rookMate');
      for (
        var i = 0;
        i < 12 && r.cubit.state.phase != ScriptPhase.pergunta;
        i++
      ) {
        await r.cubit.onAction(ScriptAction.continuar);
      }
      expect(r.cubit.state.phase, ScriptPhase.pergunta);
      return r;
    }

    test('a pergunta é a posição do mate, com a torre em h1', () async {
      final r = await question();
      expect(r.cubit.state.fen, '3k4/8/3K4/8/8/8/8/7R w - - 0 1');
      expect(r.cubit.state.speech.join(' '), contains('Dê o xeque-mate'));
      expect(r.cubit.state.speech.join(' '), isNot(contains('lique')));
    });

    test('Th8 acerta: a torre vai a h8 e a notação traz o mate', () async {
      final r = await question();
      await r.cubit.onMove('h1h8');
      final s = r.cubit.state;
      expect(s.speech.join(' '), contains('Xeque-mate!'));
      expect(s.lastMove, 'h1h8');
      expect(s.moves.map((m) => m.san), contains('Rh8#'));
      expect(s.primary, ScriptAction.continuar);
    });

    test('Th7 erra: explica por que não é mate e volta à pergunta', () async {
      final r = await question();
      await r.cubit.onMove('h1h7');
      final said = <String>[...r.cubit.state.speech];
      expect(said.join(' '), contains('não dá xeque'));
      for (
        var i = 0;
        i < 6 && r.cubit.state.phase != ScriptPhase.pergunta;
        i++
      ) {
        await r.cubit.onAction(ScriptAction.continuar);
      }
      expect(r.cubit.state.phase, ScriptPhase.pergunta);
      expect(r.cubit.state.fen, '3k4/8/3K4/8/8/8/8/7R w - - 0 1');
    });

    test(
      'na prática, o erro tem só Ver a solução e Tentar novamente',
      () async {
        final r = await open('technique.rookMate', stage: 2);
        expect(r.cubit.state.fen, '4k3/8/5K2/8/8/8/8/R7 w - - 0 1');
        await r.cubit.onMove('a1a8');
        final s = r.cubit.state;
        expect(s.tone, ScriptTone.bad);
        expect(s.primary, ScriptAction.tentarDeNovo);
        expect(s.secondary, ScriptAction.verResposta);
        await r.cubit.onAction(ScriptAction.tentarDeNovo);
        expect(r.cubit.state.fen, '4k3/8/5K2/8/8/8/8/R7 w - - 0 1');
        expect(r.cubit.state.movable, isNotNull);
      },
    );
  });
}
