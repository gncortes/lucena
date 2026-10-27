import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';

/// Achar o lance com rei: `a1a7` (o preto só tem `h8g8`) e depois `a7a8#`.
Map<String, dynamic> _findJson() => {
  'licao': 'mates.test',
  'parte': 'licao',
  'etapas': [
    {
      'id': 'pratica',
      'exemplos': [
        {
          'id': 'm1',
          'fen': '7k/8/6K1/8/8/8/8/R7 w - - 0 1',
          'vira': false,
          'objetivo': 'ganhar',
          'pratica': {
            'tipo': 'lance',
            't': 'm1.t',
            'maquina': 'b',
            'linha': [
              {
                'certos': ['a1a7'],
                'resposta': 'h8g8',
              },
              {
                'certos': ['a7a8'],
              },
            ],
            'erros': {'a1a8': 'm1.cedo'},
            'fim': 'm1.fim',
          },
          'entrada': <dynamic>[],
          'linha': <dynamic>[],
          'fim': 'proximo',
        },
      ],
    },
  ],
};

/// Prática do tipo lance com os dois reis e sem adversário (peão, T71): a
/// vez fica com o aluno e os erros com fala valem só no primeiro lance.
Map<String, dynamic> _pawnJson() {
  Map<String, dynamic> practice(
    String id,
    String fen,
    String piece,
    List<String> line,
    Map<String, String> errors,
  ) => {
    'id': id,
    'fen': fen,
    'vira': false,
    'objetivo': 'tarefa',
    'pratica': {
      'tipo': 'lance',
      'pecas': [piece],
      'linha': [
        for (final uci in line)
          {
            'certos': [uci],
          },
      ],
      'erros': errors,
      't': '$id.t',
      'fim': '$id.fim',
    },
    'entrada': <dynamic>[],
    'linha': <dynamic>[],
    'fim': 'proximo',
  };
  return {
    'licao': 'pieces.pawn',
    'parte': 'licao',
    'etapas': [
      {
        'id': 'pratica',
        'exemplos': [
          practice(
            'caminho',
            '8/2p5/3pn2k/4P3/8/8/8/K7 w - - 0 1',
            'e5',
            ['e5d6', 'd6d7', 'd7d8q'],
            {'d6c7': 'caminho.err'},
          ),
          practice(
            'promove',
            'rr5k/1P6/8/8/8/8/8/7K w - - 0 1',
            'b7',
            ['b7a8q'],
            {'b7a8r': 'promove.err'},
          ),
        ],
      },
    ],
  };
}

/// Toque nas casas (notation.coordinates, T71): só os reis, de enfeite.
Map<String, dynamic> _touchJson({bool coordinates = false}) => {
  'licao': 'notation.coordinates',
  'parte': 'licao',
  'etapas': [
    {
      'id': 'pratica',
      'exemplos': [
        {
          'id': 'casas',
          'fen': '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
          'vira': false,
          'objetivo': 'tarefa',
          'pratica': {
            'tipo': 'toque',
            't': 'casas.t',
            'fim': 'casas.fim',
            'alvos': ['e4', 'a1', 'e1'],
            'coordenadas': coordinates,
          },
          'entrada': <dynamic>[],
          'linha': <dynamic>[],
          'fim': 'proximo',
        },
      ],
    },
  ],
};

const _touchTexts = {
  'ini.toque.pedido': 'Clique na casa {casa}.',
  'ini.toque.errado': 'Essa é a casa {clicada}. Procure a casa {casa}.',
};

class _Rig {
  _Rig._(this.cubit, this.source, this.undo);

  final LessonScriptCubit cubit;
  final FakeLessonSource source;

  /// A espera antes de a peça voltar (lance fora, erro): o teste a solta.
  final List<Completer<void>> undo;

  LessonScriptState get s => cubit.state;

  Future<void> times(int n) async {
    for (var i = 0; i < n; i++) {
      await cubit.onAction(ScriptAction.continuar);
    }
  }

  /// Solta a espera e deixa o cubit seguir.
  Future<void> release() async {
    undo.removeAt(0).complete();
    await Future<void>.delayed(Duration.zero);
  }

  static Future<_Rig> open(
    Map<String, dynamic> json, {
    int stage = 0,
    Map<String, String> texts = const {},
  }) async {
    final source = FakeLessonSource();
    final undo = <Completer<void>>[];
    final script = LessonScript.fromJson(json);
    final cubit = LessonScriptCubit(
      lessonId: script.lessonId,
      partId: script.partId,
      scriptPath: 'roteiro.json',
      language: 'pt',
      // Sem falas: o balão mostra a chave.
      scripts: FakeLessonScriptRepository(script, texts),
      kpk: FakeKpkRepository(FakeKpkOracle()),
      source: source,
      initialStage: stage,
      delay: (duration) {
        if (duration != LessonScriptCubit.undoDelay) return Future.value();
        final wait = Completer<void>();
        undo.add(wait);
        return wait.future;
      },
    );
    addTearDown(cubit.close);
    await cubit.start();
    return _Rig._(cubit, source, undo);
  }
}

Set<String> _names(Iterable<Square> squares) => {
  for (final square in squares) square.name,
};

void main() {
  group('prática do tipo lance (com rei)', () {
    test('lance errado volta com a fala dele', () async {
      final r = await _Rig.open(_findJson());
      expect(r.s.phase, ScriptPhase.praticaVez);
      unawaited(r.cubit.onMove('a1a8'));
      await Future<void>.delayed(Duration.zero);
      expect(r.s.speech, ['m1.cedo']);
      expect(r.s.tone, ScriptTone.bad);
      await r.release();
      expect(r.s.fen, '7k/8/6K1/8/8/8/8/R7 w - - 0 1');
      expect(r.s.movable, isNotNull);
    });

    test('o certo segue com a resposta; o último acaba', () async {
      final r = await _Rig.open(_findJson());
      await r.cubit.onMove('a1a7');
      expect(r.s.lastMove, 'h8g8');
      expect(r.s.phase, ScriptPhase.praticaVez);
      expect(r.s.movable, isNotNull);
      await r.cubit.onMove('a7a8');
      expect(r.s.phase, ScriptPhase.praticaFim);
      expect(r.s.speech, ['ini.lance.certo', 'm1.fim']);
      expect(r.s.moves.map((m) => m.san), ['Ra7', 'Kg8', 'Ra8#']);
    });
  });

  group('prática do tipo lance sem adversário (peão)', () {
    test('a vez fica com o aluno até o fim da linha', () async {
      final r = await _Rig.open(_pawnJson());
      expect(r.s.phase, ScriptPhase.praticaVez);
      expect(_names(r.s.dests!.keys), {'e5'});
      await r.cubit.onMove('e5d6');
      expect(r.s.fen.split(' ')[1], 'w');
      expect(_names(r.s.dests!.keys), {'d6'});
      await r.cubit.onMove('d6d7');
      await r.cubit.onMove('d7d8');
      expect(r.s.phase, ScriptPhase.praticaFim);
      expect(r.s.moves.map((m) => m.san), ['exd6', 'd7', 'd8=Q']);
    });

    test('o erro com fala vale só no primeiro lance', () async {
      final r = await _Rig.open(_pawnJson());
      await r.cubit.onMove('e5d6');
      unawaited(r.cubit.onMove('d6c7'));
      await Future<void>.delayed(Duration.zero);
      expect(r.s.speech, ['ini.lance.errado']);
      expect(r.s.tone, ScriptTone.bad);
      await r.release();
      expect(r.s.fen, startsWith('8/2p5/3Pn2k/'));
    });

    test('promover a outra peça é o erro dela; a dama é o certo', () async {
      final r = await _Rig.open(_pawnJson(), stage: 0);
      await r.cubit.onMove('e5d6');
      await r.cubit.onMove('d6d7');
      await r.cubit.onMove('d7d8q');
      await r.cubit.onAction(ScriptAction.continuar);
      expect(r.s.exampleIndex, 1);
      unawaited(r.cubit.onMove('b7a8r'));
      await Future<void>.delayed(Duration.zero);
      expect(r.s.speech, ['promove.err']);
      await r.release();
      await r.cubit.onMove('b7a8q');
      expect(r.s.phase, ScriptPhase.praticaFim);
      expect(r.s.moves.last.san, 'bxa8=Q');
    });

    test('erro com fala em duas partes (.1 e .2) diz as duas', () async {
      final r = await _Rig.open(
        _pawnJson(),
        texts: const {'promove.err.1': 'perde', 'promove.err.2': 'porque'},
      );
      await r.cubit.onMove('e5d6');
      await r.cubit.onMove('d6d7');
      await r.cubit.onMove('d7d8q');
      await r.cubit.onAction(ScriptAction.continuar);
      unawaited(r.cubit.onMove('b7a8r'));
      await Future<void>.delayed(Duration.zero);
      expect(r.s.speech, ['perde', 'porque']);
      await r.release();
    });
  });

  test('tarefa com resposta (perpétuo): a resposta é das pretas, com o '
      'número do lance do aluno, e a linha segue até o fim', () async {
    final r = await _Rig.open({
      'licao': 'rules.test',
      'parte': 'licao',
      'etapas': [
        {
          'id': 'pratica',
          'exemplos': [
            {
              'id': 'perpetuo',
              'fen': '1k6/1p6/8/8/8/7r/PPP3q1/1K1Q4 w - - 0 1',
              'vira': false,
              'objetivo': 'tarefa',
              'pratica': {
                'tipo': 'lance',
                'pecas': ['d1'],
                'linha': [
                  {
                    'certos': ['d1d8'],
                    'resposta': 'b8a7',
                  },
                  {
                    'certos': ['d8a5'],
                    'resposta': 'a7b8',
                  },
                  {
                    'certos': ['a5d8'],
                  },
                ],
                't': 'p.t',
                'fim': 'p.fim',
                'erros': <String, dynamic>{},
              },
              'entrada': <dynamic>[],
              'linha': <dynamic>[],
              'fim': 'etapa',
            },
          ],
        },
      ],
    });
    await r.cubit.onMove('d1d8');
    expect(r.s.lastMove, 'b8a7');
    await r.cubit.onMove('d8a5');
    expect(r.s.lastMove, 'a7b8');
    await r.cubit.onMove('a5d8');
    expect(r.s.phase, ScriptPhase.praticaFim);
    expect(r.s.moves.map((m) => (m.number, m.side, m.san)), [
      (1, Side.white, 'Qd8+'),
      (1, Side.black, 'Ka7'),
      (2, Side.white, 'Qa5+'),
      (2, Side.black, 'Kb8'),
      (3, Side.white, 'Qd8+'),
    ]);
  });

  test('tarefa com a captura de volta das pretas na lista', () async {
    const start = '4k3/8/4p3/8/8/8/8/3RK3 w - - 0 1';
    final r = await _Rig.open({
      'licao': 'rules.test',
      'parte': 'licao',
      'etapas': [
        {
          'id': 'ideia',
          'exemplos': [
            {
              'id': 'x1',
              'fen': start,
              'vira': false,
              'objetivo': 'tarefa',
              'entrada': [
                {'fen': start, 't': 'a'},
                {
                  'fen': '4k3/8/4p3/3R4/8/8/8/4K3 w - - 1 1',
                  'lance': 'd1d5',
                  't': 'b',
                },
                {
                  'fen': '4k3/8/8/3p4/8/8/8/4K3 w - - 0 1',
                  'lance': 'e6d5',
                  't': 'c',
                },
              ],
              'linha': <dynamic>[],
              'fim': 'etapa',
            },
          ],
        },
      ],
    });
    await r.times(2);
    expect(r.s.lastMove, 'e6d5');
    expect(r.s.moves.map((m) => (m.number, m.side, m.san)), [
      (1, Side.white, 'Rd5'),
      (1, Side.black, 'exd5'),
    ]);
  });

  group('prática do tipo toque (coordenadas)', () {
    Future<_Rig> touch({bool coordinates = false}) async {
      final r = await _Rig.open(
        _touchJson(coordinates: coordinates),
        texts: _touchTexts,
      );
      for (var i = 0; i < 5 && r.s.phase != ScriptPhase.praticaVez; i++) {
        await r.times(1);
      }
      expect(r.s.phase, ScriptPhase.praticaVez);
      return r;
    }

    test(
      'abre com o enunciado e o primeiro pedido; nenhuma peça anda',
      () async {
        final r = await touch();
        expect(r.s.speech, ['casas.t', 'Clique na casa e4.']);
        expect(r.s.touching, isTrue);
        expect(r.s.touched, isEmpty);
        expect(r.s.coordinates, isFalse);
        expect(r.s.movable, isNull);
        expect(r.s.dests, isNull);
        await r.cubit.onMove('e1e2');
        expect(r.s.fen, '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
      },
    );

    test('casa errada marca em vermelho e o pedido continua', () async {
      final r = await touch();
      await r.cubit.onSquare('d4');
      expect(r.s.touchMiss, 'd4');
      expect(r.s.tone, ScriptTone.bad);
      expect(r.s.speech, ['Essa é a casa d4. Procure a casa e4.']);
      expect(r.s.touched, isEmpty);
      await r.cubit.onSquare('e4');
      expect(r.s.touchMiss, isNull);
      expect(r.s.touched, ['e4']);
      expect(r.s.tone, ScriptTone.good);
      expect(r.s.speech, ['Clique na casa a1.']);
    });

    test('a última casa (ocupada também conta) conclui a prática', () async {
      final r = await touch(coordinates: true);
      expect(r.s.coordinates, isTrue);
      await r.cubit.onSquare('e4');
      await r.cubit.onSquare('a1');
      await r.cubit.onSquare('e1');
      expect(r.s.touched, ['e4', 'a1', 'e1']);
      expect(r.s.phase, ScriptPhase.praticaFim);
      expect(r.s.touching, isFalse);
      expect(r.s.speech, ['ini.toque.sucesso', 'casas.fim']);
      expect(r.s.primary, ScriptAction.proximaParte);
      // Depois do fim, o toque não conta mais.
      await r.cubit.onSquare('h8');
      expect(r.s.touchMiss, isNull);
    });

    test('fora da prática de toque, onSquare não faz nada', () async {
      final r = await _Rig.open(_findJson());
      await r.cubit.onSquare('a6');
      expect(r.s.touching, isFalse);
      expect(r.s.coordinates, isTrue);
      expect(r.s.touched, isEmpty);
    });
  });
}
