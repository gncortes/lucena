import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/script_fixture.dart';

const _lessonId = 'pawns.test';
const _partId = 'distant';

/// Um timer que só dispara quando o teste manda.
class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this.callback);

  final Duration duration;
  final void Function() callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    callback();
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() => _active = false;
}

class _Rig {
  _Rig._(this.cubit, this.source, this.oracle, this.now, this.timers);

  final LessonScriptCubit cubit;
  final FakeLessonSource source;
  final FakeKpkOracle oracle;
  final FakeNow now;
  final List<_FakeTimer> timers;

  /// Os timers da demonstração ainda armados.
  List<_FakeTimer> get pending => [
    for (final t in timers)
      if (t.isActive) t,
  ];

  /// O tempo do passo acaba: a demonstração passa sozinha.
  Future<void> elapse() async {
    final timer = pending.single;
    now.advance(timer.duration);
    timer.fire();
    await Future<void>.delayed(Duration.zero);
  }

  LessonScriptState get s => cubit.state;

  Future<void> next() => cubit.onAction(ScriptAction.continuar);

  Future<void> times(int n) async {
    for (var i = 0; i < n; i++) {
      await next();
    }
  }

  /// Joga o primeiro lance legal (em ordem de UCI) do lado que pode mover.
  Future<void> anyMove() async {
    final position = Chess.fromSetup(Setup.parseFen(s.fen));
    final ucis = <String>[];
    position.legalMoves.forEach((from, tos) {
      for (final to in tos.squares) {
        ucis.add(NormalMove(from: from, to: to).uci);
      }
    });
    ucis.sort();
    await cubit.onMove(ucis.first);
  }

  static Future<_Rig> open({
    Map<String, dynamic>? json,
    FakeKpkOracle? oracle,
    int stage = 0,
    ScriptDelay? delay,
    List<Reference> refs = const [],
  }) async {
    final source = FakeLessonSource(refs: refs);
    final kpk = oracle ?? FakeKpkOracle();
    final now = FakeNow(DateTime(2026, 10, 14, 9));
    final timers = <_FakeTimer>[];
    final cubit = LessonScriptCubit(
      lessonId: _lessonId,
      partId: _partId,
      scriptPath: 'roteiro.json',
      language: 'pt',
      scripts: FakeLessonScriptRepository(
        json == null ? scriptFixture() : LessonScript.fromJson(json),
        scriptTexts(json),
      ),
      kpk: FakeKpkRepository(kpk),
      source: source,
      initialStage: stage,
      delay: delay ?? (_) async {},
      now: now,
      timer: (duration, callback) {
        final timer = _FakeTimer(duration, callback);
        timers.add(timer);
        return timer;
      },
    );
    addTearDown(cubit.close);
    await cubit.start();
    return _Rig._(cubit, source, kpk, now, timers);
  }
}

/// Um roteiro de uma etapa só, com um exemplo de pergunta em que o aluno
/// (pretas, empatar) pode capturar o peão: `g3g2` é um lance fora do roteiro
/// que mantém o empate.
Map<String, dynamic> _captureJson() {
  const fen = '8/8/8/8/8/6k1/6P1/4K3 b - - 0 1';
  const after = '8/8/8/8/8/8/6k1/4K3 w - - 0 1';
  Map<String, dynamic> step(String f, String t, [String? move]) => {
    'fen': f,
    't': t,
    'lance': ?move,
  };
  return {
    'licao': _lessonId,
    'parte': _partId,
    'etapas': [
      {
        'id': 'ideia',
        'exemplos': [
          {
            'id': 'c1',
            'fen': fen,
            'vira': true,
            'objetivo': 'empatar',
            'entrada': <dynamic>[],
            'pergunta': {
              't': 'q',
              'certos': ['g3h3'],
              'certo': step('8/8/8/8/8/7k/6P1/4K3 w - - 1 2', 'ok', 'g3h3'),
              'revela': step('8/8/8/8/8/7k/6P1/4K3 w - - 1 2', 'rev', 'g3h3'),
              'alternativos': <String, dynamic>{},
              'erros': <String, dynamic>{},
              'livre': {
                'maquina': 'w',
                'fala': 'free',
                'fins': {'capturado': 'fin.cap'},
                'volta': 'back',
              },
            },
            'linha': [step(after, 'l1')],
            'fim': 'etapa',
          },
        ],
      },
    ],
  };
}

/// Duas práticas em que o peão coroa com `g7g8`.
Map<String, dynamic> _practiceJson({String fen = _promoteFen}) => {
  'licao': _lessonId,
  'parte': _partId,
  'etapas': [
    {
      'id': 'pratica',
      'exemplos': [
        for (final id in ['p1', 'p2'])
          {
            'id': id,
            'fen': fen,
            'vira': false,
            'objetivo': 'ganhar',
            'pratica': {
              't': '$id.t',
              'maquina': 'b',
              'limite': 40,
              if (id == 'p2') 'fim': 'p2.fim',
            },
            'entrada': <dynamic>[],
            'linha': <dynamic>[],
            'fim': 'proximo',
          },
      ],
    },
  ],
};

const _promoteFen = '4k3/6P1/8/8/8/8/8/4K3 w - - 0 1';

void main() {
  group('entrada', () {
    test(
      'abre no primeiro balão, sem ◀, e grava o ponto de retomada',
      () async {
        final r = await _Rig.open();
        expect(r.s.ready, isTrue);
        expect(r.s.phase, ScriptPhase.entrada);
        expect(r.s.speech, ['e1']);
        expect(r.s.primary, ScriptAction.continuar);
        expect(r.s.secondary, isNull);
        expect(r.s.canBack, isFalse);
        expect(r.s.movable, isNull);
        expect(r.s.fen, exampleOneFen);
        expect(r.s.orientation, Side.white);
        expect(r.s.stageIndex, 0);
        expect(r.s.stageCount, 3);
        expect(r.s.stageId, 'ideia');
        expect(r.s.exampleIndex, 0);
        expect(r.s.exampleCount, 2);
        expect(r.s.transition.kind, TransitionKind.jump);
        expect(r.source.checkpoints.single.part, _partId);
        expect(r.source.checkpoints.single.step, 0);
      },
    );

    test('Continuar passa os balões e ◀ volta um', () async {
      final r = await _Rig.open();
      await r.next();
      expect(r.s.speech, ['e2']);
      expect(r.s.marks, ['d3']);
      expect(r.s.canBack, isTrue);
      await r.next();
      expect(r.s.speech, ['e3']);
      expect(r.s.marks, ['f5']);
      r.cubit.back();
      expect(r.s.speech, ['e2']);
      expect(r.s.marks, ['d3']);
      r.cubit.back();
      expect(r.s.speech, ['e1']);
      expect(r.s.canBack, isFalse);
    });

    test('a tela junta balões curtos da mesma posição', () async {
      final r = await _Rig.open();
      r.cubit.setSpeechFits((texts) => texts.length <= 2);
      expect(r.s.speech, ['e1', 'e2']);
      await r.next();
      expect(r.s.speech, ['e3']);
      await r.next();
      expect(r.s.phase, ScriptPhase.pergunta);
      r.cubit.setSpeechFits(null);
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.entrada);
    });

    test('lance fora de hora é ignorado', () async {
      final r = await _Rig.open();
      await r.cubit.onMove('d3e4');
      expect(r.s.phase, ScriptPhase.entrada);
      expect(r.s.fen, exampleOneFen);
    });
  });

  group('pergunta', () {
    test('libera o lado do aluno e oferece Ver resposta', () async {
      final r = await _Rig.open();
      await r.times(3);
      expect(r.s.phase, ScriptPhase.pergunta);
      expect(r.s.speech, ['q']);
      expect(r.s.movable, Side.white);
      // Botão cheio no canvas (E2a).
      expect(r.s.primary, ScriptAction.verResposta);
      expect(r.s.secondary, isNull);
      expect(r.s.canBack, isTrue);
    });

    test('lance ilegal não faz nada', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3d8');
      expect(r.s.phase, ScriptPhase.pergunta);
    });

    test('Ver resposta mostra o lance certo e ◀ volta à pergunta', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onAction(ScriptAction.verResposta);
      expect(r.s.phase, ScriptPhase.linha);
      expect(r.s.speech, ['rev']);
      expect(r.s.lastMove, 'd3e4');
      expect(r.s.fen, afterKe4);
      expect(r.s.transition.kind, TransitionKind.move);
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.pergunta);
      expect(r.s.movable, Side.white);
      expect(r.s.fen, exampleOneFen);
    });

    test('lance certo: balão do certo, lance na lista e ◀ desfaz', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3e4');
      expect(r.s.phase, ScriptPhase.linha);
      expect(r.s.speech, ['ok']);
      expect(r.s.fen, afterKe4);
      expect(r.s.lastMove, 'd3e4');
      expect(r.s.transition.kind, TransitionKind.move);
      expect(r.s.transition.fromFen, exampleOneFen);
      expect(r.s.movable, isNull);
      expect([for (final m in r.s.moves) m.id], ['d3e4']);
      expect(r.s.moves.single.san, 'Ke4');
      expect(r.s.moves.single.number, 1);
      expect(r.s.moves.single.side, Side.white);
      expect(r.s.currentMoveId, 'd3e4');
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.pergunta);
      expect(r.s.transition.kind, TransitionKind.back);
      expect(r.s.transition.ucis, ['d3e4']);
      expect(r.s.fen, exampleOneFen);
    });
  });

  group('linha e fim do exemplo', () {
    test('percorre a linha, mostra o lance e vai ao próximo exemplo', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3e4');
      await r.next();
      expect(r.s.speech, ['l1']);
      expect(r.s.phase, ScriptPhase.linha);
      await r.next();
      expect(r.s.speech, ['l2']);
      expect(r.s.transition.kind, TransitionKind.move);
      expect(r.s.lastMove, 'e8f7');
      expect([for (final m in r.s.moves) m.id], ['d3e4', 'd3e4-e8f7']);
      expect(r.s.moves.last.side, Side.black);
      await r.next();
      expect(r.s.phase, ScriptPhase.fimExemplo);
      expect(r.s.speech, ['l3']);
      expect(r.s.primary, ScriptAction.continuar);
      await r.next();
      expect(r.s.exampleIndex, 1);
      expect(r.s.orientation, Side.black);
      expect(r.s.phase, ScriptPhase.entrada);
      expect(r.s.transition.kind, TransitionKind.jump);
      expect(r.s.moves, isEmpty);
    });

    test('salto "imagine g4": o lance atual é o g4, na variante', () async {
      final json = jsonDecode(
        io.File('assets/lessons/roteiros/pawns.distantOpposition.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final r = await _Rig.open(json: json);
      for (var i = 0; i < 20 && r.s.phase != ScriptPhase.pergunta; i++) {
        await r.next();
      }
      await r.cubit.onMove('d3e4');
      for (
        var i = 0;
        i < 30 && !r.s.speech.contains('rot.ideia.ex1.l14');
        i++
      ) {
        await r.next();
      }
      expect(r.s.speech, contains('rot.ideia.ex1.l14'));
      expect(r.s.currentMoveId, 'd3e4-e8f7-g3g4');
      final g4 = r.s.moves.firstWhere((m) => m.id == 'd3e4-e8f7-g3g4');
      expect(g4.variant, isTrue);
      await r.next();
      expect(r.s.currentMoveId, 'd3e4-e8f7-g3g4-f7g6');
      expect(r.s.lastMove, 'f7g6');
    });

    test('toque num lance da lista leva ao passo dele', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3e4');
      await r.times(3);
      expect(r.s.phase, ScriptPhase.fimExemplo);
      r.cubit.goToMove('d3e4');
      expect(r.s.phase, ScriptPhase.linha);
      expect(r.s.speech, ['ok']);
      expect(r.s.fen, afterKe4);
      expect(r.s.currentMoveId, 'd3e4');
      expect(r.s.transition.kind, TransitionKind.jump);
      expect(r.s.canBack, isTrue);
      r.cubit.goToMove('d3e4-e8f7');
      expect(r.s.speech, ['l2']);
      expect(r.s.currentMoveId, 'd3e4-e8f7');
      r.cubit.goToMove('nao-existe');
      expect(r.s.speech, ['l2']);
    });

    test('◀ numa linha volta um passo de cada vez', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3e4');
      await r.times(2);
      expect(r.s.speech, ['l2']);
      r.cubit.back();
      expect(r.s.speech, ['l1']);
      expect(r.s.fen, afterKe4);
      expect(r.s.transition.kind, TransitionKind.back);
      r.cubit.back();
      expect(r.s.speech, ['ok']);
    });
  });

  group('erro com refutação e jogo livre', () {
    Future<_Rig> refuted({FakeKpkOracle? oracle, ScriptDelay? delay}) async {
      final r = await _Rig.open(oracle: oracle, delay: delay);
      await r.times(3);
      await r.cubit.onMove('d3d4');
      return r;
    }

    test('mostra a refutação passo a passo e ◀ volta à pergunta', () async {
      final r = await refuted();
      expect(r.s.phase, ScriptPhase.refutacao);
      expect(r.s.speech, ['err1']);
      expect(r.s.lastMove, 'd3d4');
      expect(r.s.transition.kind, TransitionKind.move);
      await r.next();
      expect(r.s.speech, ['err2']);
      expect(r.s.lastMove, 'e8e7');
      expect(r.s.fen, afterKd4Ke7);
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.pergunta);
      expect(r.s.movable, Side.white);
      expect(r.s.fen, exampleOneFen);
    });

    test('depois da refutação segue o jogo livre, já perdido', () async {
      final r = await refuted();
      await r.times(2);
      expect(r.s.phase, ScriptPhase.livrePerdido);
      expect(r.s.speech, ['free']);
      expect(r.s.fen, afterKd4Ke7);
      expect(r.s.movable, Side.white);
      expect(r.s.primary, isNull);
      // Todo jogo livre tem Linha principal, também depois do erro previsto.
      expect(r.s.secondary, ScriptAction.linhaPrincipal);
      await r.cubit.onMove('g3g4');
      expect(r.s.secondary, ScriptAction.linhaPrincipal);
    });

    test('a máquina responde sem comentar o lance do aluno', () async {
      final r = await refuted();
      await r.times(2);
      await r.cubit.onMove('g3g4');
      expect(r.s.phase, ScriptPhase.livrePerdido);
      expect(r.s.speech, ['free']);
      expect(r.s.machineThinking, isFalse);
      expect(r.s.lastMove, isNot('g3g4'));
      expect(r.s.movable, Side.white);
      expect(r.s.fen, isNot(afterKd4Ke7));
    });

    test('enquanto a máquina pensa o tabuleiro fica bloqueado', () async {
      final gate = Completer<void>();
      final r = await refuted(delay: (_) => gate.future);
      await r.times(2);
      final move = r.cubit.onMove('g3g4');
      await Future<void>.delayed(Duration.zero);
      expect(r.s.machineThinking, isTrue);
      expect(r.s.movable, isNull);
      expect(r.s.lastMove, 'g3g4');
      gate.complete();
      await move;
      expect(r.s.machineThinking, isFalse);
      expect(r.s.movable, Side.white);
    });

    test('◀ no jogo livre volta à pergunta', () async {
      final r = await refuted();
      await r.times(2);
      await r.cubit.onMove('g3g4');
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.pergunta);
      expect(r.s.fen, exampleOneFen);
      expect(r.s.movable, Side.white);
    });

    test(
      'fim do jogo livre perdido: um botão só, Ver linha principal',
      () async {
        final r = await refuted();
        await r.times(2);
        var guard = 0;
        while (r.s.phase == ScriptPhase.livrePerdido &&
            r.s.movable != null &&
            guard++ < 200) {
          await r.anyMove();
        }
        expect(r.s.phase, ScriptPhase.livreFim);
        // Não cumpriu: o Viktor convida a ver a linha principal.
        expect(r.s.speech.last, startsWith('verLinha.ganhar'));
        expect(r.s.primary, ScriptAction.linhaPrincipal);
        expect(r.s.secondary, isNull);
        expect(r.s.movable, isNull);
        await r.cubit.onAction(ScriptAction.linhaPrincipal);
        expect(r.s.phase, ScriptPhase.linha);
        expect(r.s.transition.kind, TransitionKind.jump);
      },
    );
  });

  group('lance fora do roteiro', () {
    test(
      'que perde: refutação do gerador e depois jogo livre perdido',
      () async {
        final oracle = FakeKpkOracle(byFen: {afterKc3: KpkOutcome.draw});
        final r = await _Rig.open(oracle: oracle);
        await r.times(3);
        await r.cubit.onMove('d3c3');
        expect(r.s.phase, ScriptPhase.refutacao);
        expect(r.s.speech, ['foraPerde.ganhar']);
        expect(r.s.lastMove, 'd3c3');
        expect(r.s.fen, afterKc3);
        await r.next();
        expect(r.s.phase, ScriptPhase.livrePerdido);
        expect(r.s.speech, ['free']);
        expect(r.s.secondary, ScriptAction.linhaPrincipal);
        r.cubit.back();
        expect(r.s.phase, ScriptPhase.pergunta);
      },
    );

    test(
      'que mantém: jogo livre mantido; segue bem e depois estraga',
      () async {
        var bad = false;
        final oracle = FakeKpkOracle(rule: (_) => bad ? KpkOutcome.draw : null);
        final r = await _Rig.open(oracle: oracle);
        await r.times(3);
        await r.cubit.onMove('d3e3');
        expect(r.s.phase, ScriptPhase.livreMantido);
        expect(r.s.speech, ['foraMantem.ganhar']);
        expect(r.s.movable, Side.white);
        await r.anyMove();
        expect(r.s.phase, ScriptPhase.livreMantido);
        expect(r.s.speech, ['segueBem.ganhar']);
        bad = true;
        await r.anyMove();
        expect(r.s.phase, ScriptPhase.livrePerdido);
        expect(r.s.speech, ['estragou.ganhar']);
        bad = false;
        await r.anyMove();
        expect(r.s.phase, ScriptPhase.livrePerdido);
        expect(r.s.speech, ['estragou.ganhar']);
      },
    );

    test(
      'a fala do lance só vem com a resposta; antes, os pontinhos',
      () async {
        Completer<void>? gate;
        final r = await _Rig.open(
          delay: (_) => gate?.future ?? Future<void>.value(),
        );
        await r.times(3);
        await r.cubit.onMove('d3e3');
        expect(r.s.speech, ['foraMantem.ganhar']);
        gate = Completer<void>();
        final move = r.anyMove();
        await Future<void>.delayed(Duration.zero);
        // Pensando: a fala anterior fica (o balão mostra os pontinhos).
        expect(r.s.machineThinking, isTrue);
        expect(r.s.speech, ['foraMantem.ganhar']);
        gate.complete();
        await move;
        expect(r.s.machineThinking, isFalse);
        expect(r.s.speech, ['segueBem.ganhar']);
      },
    );

    test('Linha principal sai do jogo livre e mostra a linha', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3e3');
      expect(r.s.secondary, ScriptAction.linhaPrincipal);
      await r.anyMove();
      expect(r.s.secondary, ScriptAction.linhaPrincipal);
      await r.cubit.onAction(ScriptAction.linhaPrincipal);
      expect(r.s.phase, ScriptPhase.linha);
      expect(r.s.transition.kind, TransitionKind.jump);
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.pergunta);
      expect(r.s.fen, exampleOneFen);
    });

    test('◀ no jogo livre mantido volta à pergunta', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3e3');
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.pergunta);
    });

    test(
      'fim com o resultado mantido: volta à ideia e à linha do certo',
      () async {
        final oracle = FakeKpkOracle(
          rule: (position) =>
              position.board.occupied.size == 2 ? KpkOutcome.draw : null,
        );
        final r = await _Rig.open(json: _captureJson(), oracle: oracle);
        expect(r.s.phase, ScriptPhase.pergunta);
        expect(r.s.movable, Side.black);
        await r.cubit.onMove('g3g2');
        expect(r.s.phase, ScriptPhase.livreFim);
        expect(r.s.speech, ['fin.cap', 'voltaIdeia']);
        expect(r.s.primary, ScriptAction.linhaPrincipal);
        expect(r.s.secondary, isNull);
        expect(r.s.movable, isNull);
        await r.cubit.onAction(ScriptAction.linhaPrincipal);
        expect(r.s.phase, ScriptPhase.linha);
        expect(r.s.speech, ['ok']);
        expect(r.s.transition.kind, TransitionKind.jump);
        await r.next();
        expect(r.s.phase, ScriptPhase.fimEtapa);
      },
    );

    test('◀ no fim do jogo livre volta um quadro, à pergunta', () async {
      final oracle = FakeKpkOracle(
        rule: (position) =>
            position.board.occupied.size == 2 ? KpkOutcome.draw : null,
      );
      final r = await _Rig.open(json: _captureJson(), oracle: oracle);
      await r.cubit.onMove('g3g2');
      expect(r.s.phase, ScriptPhase.livreFim);
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.pergunta);
      expect(r.s.fen, '8/8/8/8/8/6k1/6P1/4K3 b - - 0 1');
    });

    test(
      'fim sem o resultado: Ver linha principal, sem a volta à ideia',
      () async {
        final r = await _Rig.open(json: _captureJson());
        await r.cubit.onMove('g3g2');
        // o oráculo manda ganhar: capturar o peão não mantém o empate
        expect(r.s.phase, ScriptPhase.refutacao);
        expect(r.s.speech, ['foraPerde.empatar']);
        await r.next();
        expect(r.s.phase, ScriptPhase.livreFim);
        expect(r.s.speech, ['fin.cap']);
        expect(r.s.primary, ScriptAction.linhaPrincipal);
      },
    );
  });

  group('alternativo e fim da etapa', () {
    Future<_Rig> secondExample() async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3e4');
      await r.times(4);
      return r;
    }

    test(
      'alternativo com salto de volta, depois o certo, em variante',
      () async {
        final r = await secondExample();
        expect(r.s.exampleIndex, 1);
        await r.next();
        expect(r.s.phase, ScriptPhase.pergunta);
        expect(r.s.movable, Side.black);
        await r.cubit.onMove('e8f7');
        expect(r.s.phase, ScriptPhase.linha);
        expect(r.s.speech, ['altA']);
        expect(r.s.moves.single.id, 'e8f7');
        expect(r.s.moves.single.variant, isTrue);
        await r.next();
        expect(r.s.speech, ['altBack']);
        expect(r.s.fen, exampleTwoFen);
        expect(r.s.transition.kind, TransitionKind.jump);
        await r.next();
        expect(r.s.speech, ['okB']);
        expect(r.s.lastMove, 'e8e7');
        await r.next();
        expect(r.s.phase, ScriptPhase.fimEtapa);
        expect(r.s.primary, ScriptAction.proximaEtapa);
      },
    );

    test(
      'erro do exemplo 2 leva ao jogo livre com a máquina de brancas',
      () async {
        final r = await secondExample();
        await r.next();
        await r.cubit.onMove('e8f8');
        expect(r.s.phase, ScriptPhase.refutacao);
        expect(r.s.speech, ['errB']);
        await r.next();
        expect(r.s.phase, ScriptPhase.livrePerdido);
        expect(r.s.speech, ['freeB']);
        // a máquina (brancas) jogou; agora é a vez do aluno (pretas)
        expect(r.s.movable, Side.black);
        expect(r.s.lastMove, isNotNull);
      },
    );

    test(
      'fim da etapa: Próxima etapa abre a seguinte e grava o ponto',
      () async {
        final r = await secondExample();
        await r.next();
        await r.cubit.onMove('e8e7');
        await r.next();
        expect(r.s.phase, ScriptPhase.fimEtapa);
        expect(r.s.primary, ScriptAction.proximaEtapa);
        await r.cubit.onAction(ScriptAction.proximaEtapa);
        expect(r.s.stageIndex, 1);
        expect(r.s.stageId, 'demos');
        expect(r.s.phase, ScriptPhase.entrada);
        // Na etapa 2 o ◀ fica ativo: volta ao fim da etapa 1.
        expect(r.s.canBack, isTrue);
        expect([for (final c in r.source.checkpoints) c.step], [0, 1]);
        r.cubit.back();
        expect(r.s.stageIndex, 0);
        expect(r.s.phase, ScriptPhase.fimEtapa);
        expect(r.s.demo, isNull);
      },
    );
  });

  group('etapa de demonstrações', () {
    test('sem pergunta: entrada e a linha direto, fim da etapa', () async {
      final r = await _Rig.open(stage: 1);
      expect(r.source.checkpoints.single.step, 1);
      expect(r.s.speech, ['d1a']);
      await r.next();
      expect(r.s.speech, ['d1b']);
      await r.next();
      expect(r.s.phase, ScriptPhase.fimEtapa);
      expect(r.s.speech, ['d1c']);
      expect(r.s.lastMove, 'd3e4');
      expect(r.s.primary, ScriptAction.proximaEtapa);
      expect(r.s.movable, isNull);
      expect([for (final m in r.s.moves) m.id], ['d3e4']);
    });
  });

  group('demonstração automática', () {
    test('fora da etapa 2 não tem demonstração', () async {
      final r = await _Rig.open();
      expect(r.s.demo, isNull);
      expect(r.pending, isEmpty);
    });

    test('anda sozinha pelo tempo de leitura até o fim da etapa', () async {
      final r = await _Rig.open(stage: 1);
      final first = r.s.demo!;
      expect(first.playing, isTrue);
      expect(first.ended, isFalse);
      expect(first.progress, 0);
      expect(first.remaining, LessonScriptCubit.readTime('d1a'));
      expect(first.canStepBack, isFalse);
      expect(r.pending.single.duration, LessonScriptCubit.readTime('d1a'));
      await r.elapse();
      expect(r.s.speech, ['d1b']);
      expect(r.s.demo!.tick, greaterThan(first.tick));
      await r.elapse();
      expect(r.s.phase, ScriptPhase.fimEtapa);
      expect(r.s.demo!.ended, isTrue);
      expect(r.s.demo!.playing, isFalse);
      expect(r.s.demo!.canStepBack, isTrue);
      expect(r.s.primary, ScriptAction.proximaEtapa);
      expect(r.pending, isEmpty);
    });

    test('⏸ guarda o tempo decorrido; ▶ retoma com o que falta', () async {
      final r = await _Rig.open(stage: 1);
      final total = LessonScriptCubit.readTime('d1a');
      r.now.advance(const Duration(seconds: 1));
      r.cubit.demoToggle();
      expect(r.s.demo!.playing, isFalse);
      expect(r.s.demo!.remaining, total - const Duration(seconds: 1));
      expect(r.s.demo!.progress, closeTo(1000 / total.inMilliseconds, 1e-9));
      expect(r.pending, isEmpty);
      r.now.advance(const Duration(minutes: 1));
      r.cubit.demoToggle();
      expect(r.s.demo!.playing, isTrue);
      expect(r.pending.single.duration, total - const Duration(seconds: 1));
      await r.elapse();
      expect(r.s.speech, ['d1b']);
    });

    test('⏭ com a demonstração pausada segue pausada', () async {
      final r = await _Rig.open(stage: 1);
      r.cubit.demoToggle();
      await r.next();
      expect(r.s.speech, ['d1b']);
      expect(r.s.demo!.playing, isFalse);
      expect(r.s.demo!.progress, 0);
      expect(r.pending, isEmpty);
    });

    test('⏮ desfaz o lance animando e pausa', () async {
      final r = await _Rig.open(stage: 1);
      await r.elapse();
      await r.elapse();
      r.cubit.demoStepBack();
      expect(r.s.fen, exampleOneFen);
      expect(r.s.speech, ['d1b']);
      expect(r.s.transition.kind, TransitionKind.back);
      expect(r.s.transition.ucis, ['d3e4']);
      expect(r.s.demo!.playing, isFalse);
      expect(r.s.demo!.canStepBack, isFalse);
      expect(r.pending, isEmpty);
    });

    test('↻ recomeça o exemplo andando', () async {
      final r = await _Rig.open(stage: 1);
      await r.elapse();
      await r.elapse();
      await r.cubit.demoRepeat();
      expect(r.s.speech, ['d1a']);
      expect(r.s.demo!.playing, isTrue);
      expect(r.s.demo!.ended, isFalse);
      expect(r.s.moves, isEmpty);
      expect(r.pending, hasLength(1));
    });

    test('◀ pausa; no começo da etapa 2 volta ao começo da 1', () async {
      final r = await _Rig.open(stage: 1);
      await r.elapse();
      r.cubit.back();
      expect(r.s.speech, ['d1a']);
      expect(r.s.demo!.playing, isFalse);
      expect(r.pending, isEmpty);
      r.cubit.back();
      await Future<void>.delayed(Duration.zero);
      expect(r.s.stageIndex, 0);
      expect(r.s.phase, ScriptPhase.entrada);
      expect(r.s.demo, isNull);
    });

    test('fechar cancela o timer', () async {
      final r = await _Rig.open(stage: 1);
      final timer = r.pending.single;
      await r.cubit.close();
      expect(timer.isActive, isFalse);
    });
  });

  group('prática', () {
    test('abre com a vez do aluno e sem botões', () async {
      final r = await _Rig.open(stage: 2);
      expect(r.s.phase, ScriptPhase.praticaVez);
      expect(r.s.speech, ['p.t']);
      expect(r.s.movable, Side.white);
      expect(r.s.primary, isNull);
      expect(r.s.secondary, isNull);
      expect(r.s.fen, practiceFen);
      expect(r.s.moves, isEmpty);
    });

    test('lance que mantém: "certo" e a máquina responde', () async {
      final r = await _Rig.open(stage: 2);
      await r.cubit.onMove('f3e3');
      expect(r.s.speech, ['certo']);
      expect(r.s.tone, ScriptTone.good);
      expect(r.s.movable, Side.white);
      expect(r.s.lastMove, isNot('f3e3'));
    });

    test('lance que perde: mostra, avisa e desfaz depois', () async {
      final oracle = FakeKpkOracle(
        rule: (position) => position.fen.startsWith('4k3/8/8/8/5K2/1P6/8/8')
            ? KpkOutcome.draw
            : null,
      );
      final r = await _Rig.open(stage: 2, oracle: oracle);
      final seen = <LessonScriptState>[];
      final sub = r.cubit.stream.listen(seen.add);
      await r.cubit.onMove('f3f4');
      await sub.cancel();
      final shown = seen.first;
      expect(shown.lastMove, 'f3f4');
      expect(shown.tone, ScriptTone.bad);
      expect(shown.speech, ['errado.ganhar']);
      expect(shown.movable, isNull);
      expect(r.s.fen, practiceFen);
      expect(r.s.movable, Side.white);
      expect(r.s.speech, ['errado.ganhar']);
      expect(r.s.transition.kind, TransitionKind.back);
      expect(r.s.transition.ucis, ['f3f4']);
    });

    test('começa pela máquina quando a vez é dela', () async {
      final r = await _Rig.open(stage: 2);
      // 2º exemplo: o aluno joga de pretas e a vez já é dele
      expect(r.s.movable, Side.white);
      final other = Map<String, dynamic>.from(_practiceJson());
      final example =
          (((other['etapas'] as List).first as Map)['exemplos'] as List).first
              as Map;
      example['fen'] = '4k3/6P1/8/8/8/8/8/4K3 b - - 0 1';
      final machineFirst = await _Rig.open(json: other);
      expect(machineFirst.s.phase, ScriptPhase.praticaVez);
      expect(machineFirst.s.movable, Side.white);
      expect(machineFirst.s.lastMove, isNotNull);
    });

    test(
      'objetivo cumprido: sucesso e Continuar; no último, duas saídas',
      () async {
        final r = await _Rig.open(json: _practiceJson());
        await r.cubit.onMove('g7g8');
        expect(r.s.phase, ScriptPhase.praticaFim);
        expect(r.s.speech, ['sucesso.ganhar']);
        expect(r.s.tone, ScriptTone.good);
        expect(r.s.primary, ScriptAction.continuar);
        expect(r.s.secondary, isNull);
        await r.next();
        expect(r.s.exampleIndex, 1);
        expect(r.s.phase, ScriptPhase.praticaVez);
        expect(r.s.speech, ['p2.t']);
        await r.cubit.onMove('g7g8');
        expect(r.s.phase, ScriptPhase.praticaFim);
        expect(r.s.primary, ScriptAction.proximaParte);
        expect(r.s.secondary, ScriptAction.reverIdeia);
        expect(r.s.outcome, isNull);
        await r.cubit.onAction(ScriptAction.proximaParte);
        expect(r.source.completed, ['$_lessonId/$_partId']);
        expect(r.s.outcome?.nextPart, 'next');
      },
    );

    test('troca de lado: Viktor anuncia e o tabuleiro gira antes', () async {
      final json = _practiceJson();
      final second =
          (((json['etapas'] as List).first as Map)['exemplos'] as List)[1]
              as Map<String, dynamic>;
      second['fen'] = '4k3/8/8/8/8/8/6p1/4K3 b - - 0 1';
      second['vira'] = true;
      second['pratica'] = {
        ...(second['pratica'] as Map<String, dynamic>),
        'maquina': 'w',
      };
      final r = await _Rig.open(json: json);
      await r.cubit.onMove('g7g8');
      final seen = <LessonScriptState>[];
      final sub = r.cubit.stream.listen(seen.add);
      await r.next();
      await sub.cancel();
      final notice = seen.firstWhere((s) => s.speech.join().contains('troca'));
      expect(notice.speech.single, endsWith('troca.black'));
      expect(notice.orientation, Side.black);
      expect(notice.movable, isNull);
      expect(notice.primary, isNull);
      expect(r.s.exampleIndex, 1);
      expect(r.s.phase, ScriptPhase.praticaVez);
      expect(r.s.speech, ['p2.t']);
      expect(r.s.orientation, Side.black);
      expect(r.s.movable, Side.black);
    });

    test('mesmo lado: sem anúncio de troca', () async {
      final r = await _Rig.open(json: _practiceJson());
      await r.cubit.onMove('g7g8');
      final seen = <LessonScriptState>[];
      final sub = r.cubit.stream.listen(seen.add);
      await r.next();
      await sub.cancel();
      expect(seen.where((s) => s.speech.join().contains('troca')), isEmpty);
    });

    test('Rever a ideia volta à primeira etapa', () async {
      final r = await _Rig.open(json: _practiceJson());
      await r.cubit.onMove('g7g8');
      await r.next();
      await r.cubit.onMove('g7g8');
      await r.cubit.onAction(ScriptAction.reverIdeia);
      expect(r.s.stageIndex, 0);
      expect(r.s.exampleIndex, 0);
      expect(r.source.completed, isEmpty);
      expect(r.source.checkpoints.last.step, 0);
    });

    test('objetivo não cumprido: fala do fim e Voltar ao início', () async {
      final json = _practiceJson(fen: '8/8/8/8/1k6/8/P7/K7 w - - 0 1');
      final r = await _Rig.open(json: json);
      await r.cubit.onMove('a2a3');
      expect(r.s.phase, ScriptPhase.praticaFim);
      expect(r.s.speech, ['fim.capturado']);
      expect(r.s.primary, ScriptAction.voltarInicio);
      expect(r.s.secondary, isNull);
      await r.cubit.onAction(ScriptAction.voltarInicio);
      expect(r.s.phase, ScriptPhase.praticaVez);
      expect(r.s.fen, '8/8/8/8/1k6/8/P7/K7 w - - 0 1');
      expect(r.s.exampleIndex, 0);
      expect(r.s.movable, Side.white);
    });
  });

  group('lista da partida (jogo livre e prática)', () {
    List<ScriptMoveEntry> game(_Rig r) =>
        r.s.moves.where((m) => m.id.startsWith('g:')).toList();
    List<String> ids(_Rig r) => [for (final m in game(r)) m.id];

    Future<_Rig> free() async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3d4');
      await r.times(2);
      await r.cubit.onMove('g3g4');
      return r;
    }

    test('refutação: a partida na lista, "?" no erro previsto', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3d4');
      expect(ids(r), ['g:1']);
      expect(game(r).first.symbol, '?');
      expect(game(r).first.depth, 0);
      expect(r.s.currentMoveId, 'g:1');
      await r.next();
      expect(ids(r), ['g:1', 'g:2']);
      expect(game(r)[1].symbol, isNull);
      expect(r.s.currentMoveId, 'g:2');
      await r.next();
      expect(r.s.phase, ScriptPhase.livrePerdido);
      expect(r.s.currentMoveId, 'g:2');
      await r.cubit.onMove('g3g4');
      expect(ids(r), ['g:1', 'g:2', 'g:3', 'g:4']);
      expect(r.s.currentMoveId, 'g:4');
      expect(game(r).every((m) => m.depth == 0), isTrue);
    });

    test('lance fora que mantém: na lista, sem "?"', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3e3');
      expect(ids(r), ['g:1', 'g:2']);
      expect(game(r).first.symbol, isNull);
      expect(r.s.currentMoveId, 'g:2');
    });

    test('toque num lance anterior e outro lance abre sublinha', () async {
      final r = await free();
      await r.cubit.goToMove('g:2');
      expect(r.s.phase, ScriptPhase.livrePerdido);
      expect(r.s.fen, afterKd4Ke7);
      expect(r.s.movable, Side.white);
      expect(r.s.speech, ['free']);
      expect(r.s.currentMoveId, 'g:2');
      expect(r.s.transition.kind, TransitionKind.jump);
      await r.cubit.onMove('d4e4');
      // A sublinha vem logo depois do lance trocado (Lichess).
      expect(ids(r), ['g:1', 'g:2', 'g:3', 'g:5', 'g:6', 'g:4']);
      final sub = game(r)[3];
      expect(sub.depth, 1);
      expect(sub.startsVariant, isTrue);
      expect(game(r)[4].depth, 1);
      expect(r.s.currentMoveId, 'g:6');
      expect(r.s.movable, Side.white);
      await r.cubit.goToMove('g:4');
      expect(r.s.currentMoveId, 'g:4');
      expect(r.s.movable, Side.white);
      // O mesmo lance de antes segue a linha que já existe.
      await r.cubit.goToMove('g:2');
      await r.cubit.onMove('g3g4');
      expect(r.s.currentMoveId, 'g:4');
      expect(ids(r), hasLength(6));
    });

    test('toque no lance da máquina não a faz jogar de novo', () async {
      final r = await free();
      await r.cubit.goToMove('g:3');
      expect(r.s.movable, isNull);
      expect(r.s.machineThinking, isFalse);
      expect(ids(r), hasLength(4));
    });

    test('na refutação a lista só mostra', () async {
      final r = await _Rig.open();
      await r.times(3);
      await r.cubit.onMove('d3d4');
      await r.next();
      await r.cubit.goToMove('g:1');
      expect(r.s.phase, ScriptPhase.refutacao);
      expect(r.s.currentMoveId, 'g:2');
    });

    test('fim: o resultado no último lance; ◀ e toque voltam a ele', () async {
      final r = await free();
      var guard = 0;
      while (r.s.phase == ScriptPhase.livrePerdido &&
          r.s.movable != null &&
          guard++ < 200) {
        await r.anyMove();
      }
      expect(r.s.phase, ScriptPhase.livreFim);
      final last = game(r).last;
      expect(last.id, r.s.currentMoveId);
      expect(last.result, isIn(['½–½', '1–0', '0–1']));
      expect(game(r).where((m) => m.result != null), hasLength(1));
      r.cubit.back();
      expect(r.s.phase, ScriptPhase.livrePerdido);
      expect(r.s.currentMoveId, isNot(last.id));
      expect(game(r).last.result, isNotNull);
      await r.cubit.goToMove(last.id);
      expect(r.s.phase, ScriptPhase.livreFim);
      expect(r.s.primary, ScriptAction.linhaPrincipal);
      expect(r.s.movable, isNull);
    });

    test('prática: lista, toque num lance e ◀ com o cursor', () async {
      final r = await _Rig.open(stage: 2);
      await r.cubit.onMove('f3e3');
      expect(ids(r), ['g:1', 'g:2']);
      expect(r.s.currentMoveId, 'g:2');
      await r.cubit.goToMove('g:1');
      expect(r.s.phase, ScriptPhase.praticaVez);
      expect(r.s.currentMoveId, 'g:1');
      expect(r.s.movable, isNull);
      expect(r.s.speech, ['p.t']);
      expect(ids(r), hasLength(2));
      await r.cubit.goToMove('g:2');
      expect(r.s.movable, Side.white);
      r.cubit.back();
      expect(r.s.currentMoveId, 'g:1');
      r.cubit.back();
      expect(r.s.currentMoveId, 'g:2');
    });

    test('prática que acaba: resultado na lista', () async {
      final r = await _Rig.open(json: _practiceJson());
      await r.cubit.onMove('g7g8');
      expect(game(r).single.result, '1–0');
      expect(game(r).single.san, startsWith('g8=Q'));
    });
  });

  group('curiosidades', () {
    test('resolve a referência por id e o jogador em linha', () async {
      const book = Reference(
        id: 'book1',
        kind: 'book',
        fields: {'title': 'Um livro'},
      );
      final r = await _Rig.open(refs: const [book]);
      final cur = r.s.curiosities!;
      expect(cur.text, 'cur.t');
      expect(cur.quote, 'cur.q');
      expect(cur.quoteAuthor, 'Alguém');
      expect(cur.references.map((e) => e.title), ['Um livro', 'Ada Lovelace']);
      expect(cur.references.last.kind, 'player');
    });

    test(
      'id que a aula não tem fica de fora; exemplo sem curiosidade, nulo',
      () async {
        final r = await _Rig.open();
        expect(r.s.curiosities!.references.map((e) => e.title), [
          'Ada Lovelace',
        ]);
        final demo = await _Rig.open(stage: 1);
        expect(demo.s.curiosities, isNull);
      },
    );
  });
}
