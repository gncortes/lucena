import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/judge_move.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/script_fixture.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';

/// Objetivo `casa`: a prática da Oposição distante (Rf3, peão b3, Re8; as
/// brancas jogam) com `objetivo: casa`. Rf3-e4 mantém o ganho; Rf3-e3 o perde.
const _fen = '4k3/8/8/8/8/1P3K2/8/8 w - - 0 1';

Map<String, dynamic> _example(List<String> squares) => {
  'id': 'chegada',
  'fen': _fen,
  'vira': false,
  'objetivo': 'casa',
  'casas': squares,
  'fim': 'proximo',
  'pratica': {
    't': 'enunciado',
    'maquina': 'b',
    'limite': 40,
    'fim': 'fala.fim',
  },
};

Map<String, dynamic> _json(List<String> squares) => {
  'licao': 'pawns.test',
  'parte': 'casa',
  'etapas': [
    {
      'id': 'pratica',
      'exemplos': [_example(squares)],
    },
  ],
};

KpkTableOracle _oracle() =>
    KpkTableOracle(io.File('assets/tablebase/kpk.bin').readAsBytesSync());

Map<String, String> _texts() {
  return {
    ...scriptTexts(),
    'enunciado': 'Chegue à casa.',
    'fala.fim': 'Fim da casa.',
    'fala.erro.1': 'Aqui esse lance falha.',
    'fala.erro.2': 'Porque o rei perde a oposição.',
  };
}

LessonScriptCubit _cubit(
  List<String> squares, {
  Map<String, dynamic>? errosPos,
}) {
  final json = _json(squares);
  if (errosPos != null) {
    final example = ((json['etapas'] as List).first as Map)['exemplos'] as List;
    ((example.first as Map)['pratica'] as Map)['errosPos'] = errosPos;
  }
  final script = LessonScript.fromJson(json);
  final cubit = LessonScriptCubit(
    lessonId: script.lessonId,
    partId: script.partId,
    scriptPath: 'roteiro.json',
    language: 'pt',
    scripts: FakeLessonScriptRepository(script, _texts()),
    kpk: FakeKpkRepository(_oracle()),
    source: FakeLessonSource(),
    initialStage: 0,
    delay: (_) async {},
  );
  addTearDown(cubit.close);
  return cubit;
}

void main() {
  test('parse: objetivo casa lê as casas como Square e quer ganhar', () {
    final example = ScriptExample.fromJson(_example(['c6', 'd6', 'e6']));
    expect(example.goal, ScriptGoal.casa);
    expect(example.goal.wantsWin, isTrue);
    expect(example.squares.map((s) => s.name), ['c6', 'd6', 'e6']);
    final plain = ScriptExample.fromJson({
      ..._example(const []),
      'objetivo': 'ganhar',
    });
    expect(plain.squares, isEmpty);
  });

  test('kingOnSquare: só o rei do aluno numa das casas', () {
    final example = ScriptExample.fromJson(_example(['e4']));
    final arrived = GameRules.fromFen('4k3/8/8/8/4K3/1P6/8/8 b - - 1 1')!;
    expect(example.kingOnSquare(arrived), isTrue);
    expect(example.kingOnSquare(GameRules.fromFen(_fen)!), isFalse);
    // O rei adversário na casa não conta.
    final other = GameRules.fromFen('8/8/8/8/4k3/1P6/8/7K w - - 0 1')!;
    expect(example.kingOnSquare(other), isFalse);
  });

  test(
    'ao chegar à casa com o ganho mantido, o exemplo termina com sucesso',
    () async {
      final cubit = _cubit(['e4']);
      await cubit.start();
      expect(cubit.state.phase, ScriptPhase.praticaVez);

      await cubit.onMove('f3e4');
      final s = cubit.state;
      expect(s.phase, ScriptPhase.praticaFim);
      expect(s.tone, ScriptTone.good);
      expect(s.fen, startsWith('4k3/8/8/8/4K3/1P6/8/8 b'));
      expect(s.machineThinking, isFalse);
      expect(s.speech.first, _texts()['gen.pratica.sucesso.ganhar']);
      expect(s.speech.last, 'Fim da casa.');
      expect(s.primary, ScriptAction.proximaParte);
    },
  );

  test('lance que não chega à casa segue a partida', () async {
    final cubit = _cubit(['a8']);
    await cubit.start();
    await cubit.onMove('f3e4');
    expect(cubit.state.phase, ScriptPhase.praticaVez);
  });

  test('lance que chega à casa mas perde o ganho não termina: erro', () async {
    final cubit = _cubit(['e3']);
    await cubit.start();
    await cubit.onMove('f3e3');
    final s = cubit.state;
    expect(s.phase, ScriptPhase.praticaFim);
    expect(s.tone, ScriptTone.bad);
    expect(s.primary, ScriptAction.tentarDeNovo);
  });

  test(
    'errosPos: o erro da 2ª vez usa a fala da posição (contadores à parte)',
    () async {
      // Descobre a posição da 2ª vez e um lance que perde o ganho nela.
      final probe = _cubit(['a8']);
      await probe.start();
      await probe.onMove('f3e4');
      final fen = probe.state.fen;
      expect(probe.state.phase, ScriptPhase.praticaVez);
      final position = GameRules.fromFen(fen)!;
      final oracle = _oracle();
      String? bad;
      for (final MapEntry(:key, :value) in position.legalMoves.entries) {
        for (final to in value.squares) {
          final move = NormalMove(from: key, to: to);
          if (JudgeMove.judge(oracle, position, move, wantsWin: true) ==
              MoveVerdict.loses) {
            bad ??= move.uci;
          }
        }
      }
      expect(bad, isNotNull);

      // A chave do roteiro traz outros contadores: só os 4 campos contam.
      final other = '${fen.split(' ').take(4).join(' ')} 17 42';
      final cubit = _cubit(
        ['a8'],
        errosPos: {
          other: {bad!: 'fala.erro'},
        },
      );
      await cubit.start();
      await cubit.onMove('f3e4');
      expect(cubit.state.fen, fen);
      await cubit.onMove(bad);
      final s = cubit.state;
      expect(s.phase, ScriptPhase.praticaFim);
      expect(s.tone, ScriptTone.bad);
      expect(s.speech.single, _texts()['fala.erro.2']);
    },
  );
}
