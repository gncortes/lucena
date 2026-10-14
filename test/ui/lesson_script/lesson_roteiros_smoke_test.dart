import 'dart:async';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/repositories/tablebase/kpk_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';
import 'package:lucena/domain/use_cases/machine_move.dart';
import 'package:lucena/domain/use_cases/script_moves.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';

/// Teste de fumaça (T71): cada roteiro de `assets/lessons/roteiros/`, com as
/// falas e a tabela KPK de verdade, do começo ao fim pelo caminho certo e,
/// numa segunda volta, com um erro previsto em cada pergunta.

/// Os assets lidos do disco, como o app os lê do pacote.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await io.File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      io.File(key).readAsString();
}

final _kpk = KpkTableOracle(io.File(AssetKpkRepository.path).readAsBytesSync());

/// Fala que vazou a chave ou um marcador que a tela não troca.
final _rawKey = RegExp(r'\b(rot|ini|gen)\.[A-Za-z]');

List<String> _roteiros() => [
  for (final file in io.Directory('assets/lessons/roteiros').listSync())
    if (file.path.endsWith('.json'))
      file.uri.pathSegments.last.replaceAll('.json', ''),
]..sort();

class _Run {
  _Run(this.cubit, this.script, this.switching);

  final LessonScriptCubit cubit;
  final LessonScript script;
  final problems = <String>[];
  final trail = <String>[];

  /// As falas de troca de lado: passam sozinhas, sem botão.
  final Set<String> switching;

  /// As perguntas em que o erro previsto já foi jogado (`etapa/exemplo`).
  final erred = <String>{};

  LessonScriptState get s => cubit.state;

  String get where => '${s.stageId}/${s.exampleIndex} ${s.phase.name}';

  ScriptExample get example =>
      script.stages[s.stageIndex].examples[s.exampleIndex];

  void check(LessonScriptState state) {
    // Nada a conferir antes de abrir nem depois de concluir a parte.
    if (!state.ready || state.outcome != null) return;
    final at = '${state.stageId}/${state.exampleIndex} ${state.phase.name}';
    for (final text in state.speech) {
      final shown = text.replaceAll(ScriptSpeech.markPattern, '');
      if (_rawKey.hasMatch(shown) || shown.contains('{')) {
        problems.add('$at: fala crua "$text"');
      }
    }
    if (state.speech.isEmpty && !state.machineThinking) {
      problems.add('$at: sem fala');
    }
    const waiting = {
      ScriptPhase.entrada,
      ScriptPhase.linha,
      ScriptPhase.refutacao,
      ScriptPhase.fimExemplo,
      ScriptPhase.fimEtapa,
      ScriptPhase.praticaFim,
      ScriptPhase.livreFim,
    };
    if (waiting.contains(state.phase) &&
        !state.speech.every(switching.contains) &&
        !state.machineThinking &&
        state.primary == null) {
      problems.add('$at: sem botão principal (${state.fen}, ${state.speech})');
    }
  }

  Future<void> act(String what, Future<void> Function() action) async {
    trail.add('$where → $what');
    await action();
  }

  /// Um lance do aluno na prática contra a máquina: o melhor pela tabela.
  String practiceMove() {
    final position = GameRules.fromFen(s.fen)!;
    return MachineMove.choose(_kpk, position)!;
  }

  /// O caminho mais curto da peça até a estrela mais perto (busca em
  /// largura com a vez parada, como na tarefa).
  List<String> starPath() {
    final from = s.dests!.keys.single.name;
    final queue = <(String, String, List<String>)>[(s.fen, from, [])];
    final seen = <String>{from};
    while (queue.isNotEmpty) {
      final (fen, square, path) = queue.removeAt(0);
      final dests = ScriptMoves.dests(fen, pieces: [square]);
      for (final to in dests.values.expand((t) => t)) {
        final uci = '$square${to.name}';
        final next = [...path, uci];
        if (s.stars.contains(to.name)) return next;
        if (!seen.add(to.name)) continue;
        final played = ScriptMoves.play(fen, uci, keepTurn: true);
        if (played != null) queue.add((played.fen, to.name, next));
      }
    }
    return const [];
  }

  /// Um passo do aluno; falso quando a parte acabou.
  Future<bool> step({required bool withErrors}) async {
    if (s.outcome != null) return false;
    switch (s.phase) {
      case ScriptPhase.pergunta:
        final question = example.question!;
        final key = '${s.stageIndex}/${s.exampleIndex}';
        if (withErrors && question.errors.isNotEmpty && erred.add(key)) {
          final uci = question.errors.keys.first;
          await act('erro $uci', () => cubit.onMove(uci));
          if (s.phase != ScriptPhase.refutacao) {
            problems.add('$where: o erro $uci não abriu a refutação');
          }
        } else {
          final uci = question.right.first;
          await act('certo $uci', () => cubit.onMove(uci));
          if (s.phase == ScriptPhase.pergunta) {
            problems.add('$where: o lance certo $uci não saiu da pergunta');
            return false;
          }
        }
      case ScriptPhase.praticaVez:
        final practice = example.practice!;
        switch (practice.kind) {
          case PracticeKind.estrelas:
            final path = starPath();
            if (path.isEmpty) {
              problems.add('$where: nenhuma estrela ao alcance');
              return false;
            }
            for (final uci in path) {
              await act('estrela $uci', () => cubit.onMove(uci));
            }
          case PracticeKind.lance:
            final turn = s.moves
                .where((m) => !m.variant && m.side == example.student)
                .length;
            final uci = practice.line[turn].right.first;
            await act('lance $uci', () => cubit.onMove(uci));
          case PracticeKind.jogo:
            final uci = practiceMove();
            await act('prática $uci', () => cubit.onMove(uci));
          default:
            problems.add('$where: prática ${practice.kind} sem caminho');
            return false;
        }
      case ScriptPhase.livrePerdido || ScriptPhase.livreMantido:
        await act(
          'linha principal',
          () => cubit.onAction(ScriptAction.linhaPrincipal),
        );
      case ScriptPhase.praticaFim when s.primary == ScriptAction.voltarInicio:
        problems.add('$where: a prática não cumpriu o objetivo');
        return false;
      default:
        final action = s.primary;
        if (action == null) return false;
        await act(action.name, () => cubit.onAction(action));
    }
    return true;
  }
}

Future<_Run> _drive(String id, {required bool withErrors}) async {
  final repository = AssetLessonScriptRepository(AssetService(_DiskBundle()));
  final path = AssetLessonScriptRepository.scriptPath(id);
  final script = await repository.script(path);
  final source = FakeLessonSource();
  final cubit = LessonScriptCubit(
    lessonId: id,
    partId: script.partId,
    scriptPath: path,
    language: 'pt',
    scripts: repository,
    kpk: FakeKpkRepository(_kpk),
    source: source,
    delay: (_) => Future.value(),
    // A demonstração não anda sozinha: o teste clica.
    timer: (_, _) => Timer(const Duration(days: 1), () {}),
  );
  addTearDown(cubit.close);
  final texts = await repository.texts(id, 'pt');
  final run = _Run(cubit, script, {
    for (final side in Side.values) texts.say('gen.troca.${side.name}'),
  });
  final sub = cubit.stream.listen(run.check);
  addTearDown(sub.cancel);
  await cubit.start();
  run.check(cubit.state);
  for (var i = 0; i < 600; i++) {
    if (!await run.step(withErrors: withErrors)) break;
    await Future<void>.delayed(Duration.zero);
  }
  if (run.s.outcome == null) {
    run.problems.add('não concluiu a parte (parou em ${run.where})');
  }
  expect(
    source.completed,
    run.s.outcome == null ? isEmpty : ['$id/${script.partId}'],
  );
  return run;
}

void main() {
  for (final id in _roteiros()) {
    group(id, () {
      for (final withErrors in [false, true]) {
        test(
          withErrors ? 'com um erro por pergunta' : 'caminho certo',
          () async {
            final run = await _drive(id, withErrors: withErrors);
            final questions = [
              for (final stage in run.script.stages)
                for (final example in stage.examples)
                  if (example.question?.errors.isNotEmpty ?? false) example,
            ];
            expect(run.erred, hasLength(withErrors ? questions.length : 0));
            expect(
              run.problems,
              isEmpty,
              reason: 'caminho:\n${run.trail.takeLast(12).join('\n')}',
            );
          },
        );
      }
    });
  }
}

extension<T> on List<T> {
  Iterable<T> takeLast(int n) => skip(length > n ? length - n : 0);
}
