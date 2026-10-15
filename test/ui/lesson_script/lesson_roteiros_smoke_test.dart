import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/repositories/tablebase/kpk_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/judge_move.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';
import 'package:lucena/domain/use_cases/machine_move.dart';
import 'package:lucena/domain/use_cases/move_tree.dart';
import 'package:lucena/domain/use_cases/script_moves.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';

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

/// Os roteiros como `<lição>` (Escola) ou `<lição>/<capítulo>` (aula de
/// final, T76), o caminho sem a pasta e sem o `.json`.
List<String> _roteiros() => [
  for (final file in io.Directory(
    'assets/lessons/roteiros',
  ).listSync(recursive: true))
    if (file.path.endsWith('.json'))
      file.path
          .replaceFirst('assets/lessons/roteiros/', '')
          .replaceAll('.json', ''),
]..sort();

String _lessonOf(String key) => key.split('/').first;

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
      final shown = text.replaceAll(SpeechText.markPattern, '');
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

  /// Um lance do aluno na prática contra a máquina: o melhor pela tabela;
  /// no objetivo `mate`, o que encurrala o rei ([_mateMove]).
  String practiceMove() {
    final position = GameRules.fromFen(s.fen)!;
    if (example.goal == ScriptGoal.mate) return _mateMove(position, seen);
    if (example.goal == ScriptGoal.casa) return _casaMove(position);
    return MachineMove.choose(_kpk, position)!;
  }

  /// No objetivo `casa`: entre os lances que mantêm o ganho, o que deixa o rei
  /// do aluno mais perto de uma das casas (chegar encerra com sucesso).
  String _casaMove(Position position) {
    final us = position.turn;
    int distance(Position next) {
      final king = next.board.kingOf(us)!;
      return example.squares
          .map(
            (c) => max((c.file - king.file).abs(), (c.rank - king.rank).abs()),
          )
          .reduce(min);
    }

    String? best;
    var bestDistance = 99;
    for (final MapEntry(:key, :value) in position.legalMoves.entries) {
      for (final to in value.squares) {
        final move = NormalMove(from: key, to: to);
        final next = position.playUnchecked(move);
        if (JudgeMove.judge(_kpk, position, move, wantsWin: true) !=
            MoveVerdict.keeps) {
          continue;
        }
        final d = distance(next);
        if (d < bestDistance) {
          bestDistance = d;
          best = move.uci;
        }
      }
    }
    return best ?? MachineMove.choose(_kpk, position)!;
  }

  /// As posições da prática de mate já vistas (para não repetir).
  final seen = <String>{};

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
          case PracticeKind.toque:
            final targets = practice.targets;
            if (targets.isEmpty) {
              problems.add('$where: toque sem alvos');
              return false;
            }
            if (withErrors) {
              final miss = targets.first == 'a1' ? 'h8' : 'a1';
              await act('toque errado $miss', () => cubit.onSquare(miss));
              if (s.touchMiss != miss) {
                problems.add('$where: o toque errado $miss não marcou');
              }
              if (s.touched.isNotEmpty) {
                problems.add('$where: o toque errado $miss avançou a prática');
              }
            }
            for (final square in targets) {
              await act('toque $square', () => cubit.onSquare(square));
              if (s.touchMiss != null) {
                problems.add('$where: o toque certo $square não limpou o erro');
              }
            }
          case PracticeKind.jogo:
            final uci = practiceMove();
            await act('prática $uci', () => cubit.onMove(uci));
        }
      case ScriptPhase.livrePerdido || ScriptPhase.livreMantido:
        await act(
          'linha principal',
          () => cubit.onAction(ScriptAction.linhaPrincipal),
        );
      case ScriptPhase.praticaFim when s.primary == ScriptAction.voltarInicio:
        problems.add('$where: a prática não cumpriu o objetivo');
        return false;
      case ScriptPhase.praticaFim
          when example.practice?.kind == PracticeKind.jogo &&
              example.goal != ScriptGoal.casa &&
              !s.machineThinking:
        // A partida contra a máquina fecha com o resultado na lista.
        final last = s.moves.where((m) => m.id == s.currentMoveId).firstOrNull;
        if (!_results.contains(last?.result)) {
          problems.add(
            '$where: fim sem resultado (${last?.san} ${last?.result})',
          );
        }
        await act(s.primary!.name, () => cubit.onAction(s.primary!));
      default:
        final action = s.primary;
        if (action == null) return false;
        await act(action.name, () => cubit.onAction(action));
    }
    return true;
  }
}

/// O aluno das práticas de mate (sem motor): dá mate se puder (em 1 ou em
/// 2); com peão, coroa ou avança quando ele não cai; senão, entre os lances
/// que não afogam nem deixam peça sem defesa ao alcance do rei, o que captura
/// peça, deixa o rei com menos casas livres na pior resposta dele e o próprio
/// rei mais perto dele.
String _mateMove(Position position, Set<String> seen) {
  final us = position.turn;
  final safe = <(NormalMove, Position)>[];
  for (final (move, next) in _moves(position)) {
    if (next.isCheckmate) return move.uci;
    if (next.isStalemate || _hangs(next, us)) continue;
    safe.add((move, next));
  }
  // Mate em 2: toda resposta deixa um mate.
  for (final (move, next) in safe) {
    final replies = _moves(next).toList();
    if (replies.every((r) => _moves(r.$2).any((m) => m.$2.isCheckmate))) {
      return _remember(position, move.uci, seen);
    }
  }
  final pawnMoves = [
    for (final (move, _) in safe)
      if (position.board.roleAt(move.from) == Role.pawn)
        (move.promotion != null ? 0 : 1, move.uci),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  if (pawnMoves.isNotEmpty) {
    return _remember(position, pawnMoves.first.$2, seen);
  }
  final candidates = <(int, String)>[];
  for (final (move, next) in safe) {
    final theirKing = next.board.kingOf(us.opposite)!;
    // A pior resposta: a que deixa o rei com mais casas.
    var room = 0;
    for (final (_, reply) in _moves(next)) {
      room = max(room, _kingRoom(reply, us));
    }
    final escort = [
      for (final p in next.board.pawns.intersect(next.board.bySide(us)).squares)
        _distance(next.board.kingOf(us)!, p),
    ].fold(0, (a, b) => a + b);
    final key = next.fen.split(' ').take(4).join(' ');
    final score =
        room * 30 +
        _distance(next.board.kingOf(us)!, theirKing) * 3 +
        escort * 60 +
        next.board.bySide(us.opposite).squares.length * 500 +
        (seen.contains(key) ? 3000 : 0);
    candidates.add((score, move.uci));
  }
  candidates.sort((a, b) {
    final byScore = a.$1.compareTo(b.$1);
    return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
  });
  return _remember(position, candidates.first.$2, seen);
}

/// Os lances legais (coroação com dama) e a posição depois de cada um.
Iterable<(NormalMove, Position)> _moves(Position position) sync* {
  for (final MapEntry(key: from, value: targets)
      in position.legalMoves.entries) {
    final pawn = position.board.roleAt(from) == Role.pawn;
    for (final to in targets.squares) {
      final promotes =
          pawn && (to.rank == Rank.first || to.rank == Rank.eighth);
      final move = NormalMove(
        from: from,
        to: to,
        promotion: promotes ? Role.queen : null,
      );
      yield (move, position.play(move));
    }
  }
}

/// O adversário captura alguma peça de [us] em [next].
bool _hangs(Position next, Side us) => next.legalMoves.entries.any(
  (entry) => entry.value.squares.any((sq) => next.board.sideAt(sq) == us),
);

String _remember(Position position, String uci, Set<String> seen) {
  seen.add(position.play(Move.parse(uci)!).fen.split(' ').take(4).join(' '));
  return uci;
}

/// As casas que o rei de quem defende alcança sem passar por casa atacada.
int _kingRoom(Position position, Side attacker) {
  final board = position.board;
  final king = board.kingOf(attacker.opposite)!;
  final occupied = board.occupied.withoutSquare(king);
  var attacked = SquareSet.empty;
  for (final square in board.bySide(attacker).squares) {
    attacked = attacked.union(switch (board.roleAt(square)!) {
      Role.king => kingAttacks(square),
      Role.queen => queenAttacks(square, occupied),
      Role.rook => rookAttacks(square, occupied),
      Role.bishop => bishopAttacks(square, occupied),
      Role.knight => knightAttacks(square),
      Role.pawn => pawnAttacks(attacker, square),
    });
  }
  final room = <Square>{king};
  final queue = [king];
  while (queue.isNotEmpty) {
    for (final next in kingAttacks(queue.removeLast()).squares) {
      if (attacked.has(next) || room.contains(next)) continue;
      room.add(next);
      queue.add(next);
    }
  }
  return room.length;
}

int _distance(Square a, Square b) =>
    max((a.file - b.file).abs(), (a.rank - b.rank).abs());

/// Abre a lição [id] no cubit, com os assets de verdade.
Future<(_Run, FakeLessonSource)> _open(String key) async {
  final id = _lessonOf(key);
  final repository = AssetLessonScriptRepository(AssetService(_DiskBundle()));
  final path = AssetLessonScriptRepository.scriptPath(key);
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
    // No objetivo `mate`, o motor de mentira: dá mate se puder, senão o
    // primeiro lance em ordem.
    opponent: FakeOpponentRepository(),
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
  return (run, source);
}

Future<_Run> _drive(String key, {required bool withErrors}) async {
  final (run, source) = await _open(key);
  final id = _lessonOf(key);
  for (var i = 0; i < 600; i++) {
    if (!await run.step(withErrors: withErrors)) break;
    await Future<void>.delayed(Duration.zero);
  }
  if (run.s.outcome == null) {
    run.problems.add('não concluiu a parte (parou em ${run.where})');
  }
  expect(
    source.completed,
    run.s.outcome == null ? isEmpty : ['$id/${run.script.partId}'],
  );
  return run;
}

/// Os lances do aluno na pergunta que entram no jogo livre: os erros, os
/// alternativos e um lance legal fora do roteiro, se sobra algum.
List<String> _offLine(ScriptExample example) {
  final question = example.question!;
  final position = GameRules.fromFen(example.questionFen)!;
  final legal = [
    for (final MapEntry(key: from, value: targets)
        in position.legalMoves.entries)
      for (final to in targets.squares) '${from.name}${to.name}',
  ]..sort();
  final fora = legal.where((uci) => !question.covers(uci));
  return [
    ...question.errors.keys,
    ...question.alternatives.keys,
    if (fora.isNotEmpty) fora.first,
  ];
}

/// As perguntas com jogo livre (lições com a tabela KPK).
List<(int, int, ScriptExample)> _freeQuestions(String id) {
  final script = LessonScript.fromJson(
    jsonDecode(
      io.File(AssetLessonScriptRepository.scriptPath(id)).readAsStringSync(),
    ) as Map<String, dynamic>,
  );
  return [
    for (final (s, stage) in script.stages.indexed)
      for (final (e, example) in stage.examples.indexed)
        if (example.question?.free != null) (s, e, example),
  ];
}

/// Quantas peças há no tabuleiro da [fen].
int _pieces(String fen) => fen
    .split(' ')
    .first
    .split('')
    .where((c) => RegExp('[a-zA-Z]').hasMatch(c))
    .length;

const _results = {'½–½', '1–0', '0–1'};

/// Da pergunta, joga [uci] e segue até o jogo livre acabar e a linha
/// principal voltar (ou, sem jogo livre, até sair do exemplo). Com [branch],
/// no meio da partida volta a um lance da máquina e joga outro lance.
Future<({bool ended, bool branched, int longest})> _freeGame(
  _Run run,
  ScriptExample example,
  String uci, {
  required bool branch,
}) async {
  final cubit = run.cubit;
  final index = run.s.exampleIndex;
  final err = example.question!.errors.containsKey(uci);
  await run.act('livre $uci', () => cubit.onMove(uci));
  var branched = false;
  var longest = 0;
  for (var i = 0; i < 400; i++) {
    final s = run.s;
    if (s.exampleIndex != index || s.phase == ScriptPhase.fimExemplo) {
      return (ended: false, branched: branched, longest: longest);
    }
    switch (s.phase) {
      case ScriptPhase.pergunta:
        return (ended: false, branched: branched, longest: longest);
      case ScriptPhase.livrePerdido || ScriptPhase.livreMantido:
        if (s.movable == null) {
          run.problems.add('${run.where}: jogo livre parado sem vez');
          return (ended: false, branched: branched, longest: longest);
        }
        final game = s.moves.where((m) => m.id.startsWith('g:')).toList();
        final machine = example.student.opposite;
        if (game.length > longest) longest = game.length;
        if (branch && !branched && game.length >= 4) {
          branched = true;
          await _branch(run, game, machine);
          continue;
        }
        await run.act('aluno', () => cubit.onMove(run.practiceMove()));
      case ScriptPhase.livreFim:
        final game = s.moves.where((m) => m.id.startsWith('g:')).toList();
        final last = game.where((m) => m.id == s.currentMoveId).firstOrNull;
        if (!_results.contains(last?.result)) {
          run.problems.add(
            '${run.where}: fim sem resultado (${last?.san} ${last?.result})',
          );
        }
        final marked = [
          for (final (i, m) in game.indexed)
            if (m.symbol == '?') i,
        ];
        if (!(err
            ? marked.length == 1 && marked.single == 0
            : marked.isEmpty)) {
          run.problems.add('${run.where}: "?" fora do erro previsto ($marked)');
        }
        if (s.primary == ScriptAction.continuar) {
          // A fala do fim; o convite com o link vem no passo seguinte.
          await run.act('continuar', () => cubit.onAction(s.primary!));
          continue;
        }
        if (s.primary != ScriptAction.linhaPrincipal) {
          run.problems.add('${run.where}: fim sem a linha principal');
          return (ended: false, branched: branched, longest: longest);
        }
        await run.act(
          'linha principal',
          () => cubit.onAction(ScriptAction.linhaPrincipal),
        );
        final back = run.s;
        final main = ScriptTracks.steps(example, ScriptTracks.main).first;
        if (back.phase != ScriptPhase.linha &&
            back.phase != ScriptPhase.fimExemplo) {
          run.problems.add('${run.where}: a linha principal não voltou');
        } else if (back.fen != main.fen) {
          run.problems.add('${run.where}: a linha voltou em ${back.fen}');
        }
        if (back.moves.any((m) => m.id.startsWith('g:'))) {
          run.problems.add('${run.where}: a partida ficou na lista');
        }
        return (ended: true, branched: branched, longest: longest);
      default:
        final action = s.primary;
        if (action == null) {
          run.problems.add('${run.where}: sem botão para seguir');
          return (ended: false, branched: branched, longest: longest);
        }
        await run.act(action.name, () => cubit.onAction(action));
    }
  }
  run.problems.add('${run.where}: o jogo livre não acabou');
  return (ended: false, branched: branched, longest: longest);
}

/// Volta a um lance da máquina já jogado, joga outro lance e confere a
/// sublinha logo depois do lance trocado.
Future<void> _branch(_Run run, List<ScriptMoveEntry> game, Side machine) async {
  // O lance do aluno que será trocado e o da máquina antes dele.
  final i = game.lastIndexWhere(
    (m) => m.side != machine && m.depth == 0,
    game.length - 2,
  );
  if (i < 1 || game[i - 1].side != machine) {
    run.problems.add('${run.where}: sem lance da máquina para voltar');
    return;
  }
  final replaced = game[i];
  await run.act(
    'volta a ${game[i - 1].san}',
    () => run.cubit.goToMove(game[i - 1].id),
  );
  if (run.s.movable == null) {
    run.problems.add('${run.where}: voltar ao lance não deu a vez ao aluno');
    return;
  }
  final position = GameRules.fromFen(run.s.fen)!;
  final other =
      [
            for (final MapEntry(key: from, value: targets)
                in position.legalMoves.entries)
              for (final to in targets.squares) '${from.name}${to.name}',
          ]
          .where((uci) => ScriptMoves.play(run.s.fen, uci)?.san != replaced.san)
          .firstOrNull;
  if (other == null) return;
  await run.act('outro lance $other', () => run.cubit.onMove(other));
  final entries = run.s.moves.where((m) => m.id.startsWith('g:')).toList();
  final at = entries.indexWhere((m) => m.id == replaced.id);
  final next = at < 0 ? null : entries.elementAtOrNull(at + 1);
  if (next == null || next.depth != 1 || !next.startsVariant) {
    run.problems.add(
      '${run.where}: a sublinha não abriu logo depois de ${replaced.san} '
      '(${next?.san} depth ${next?.depth})',
    );
  }
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
      final free = _freeQuestions(id);
      if (free.isNotEmpty) {
        // O jogo livre de um erro previsto sempre diz que o resultado se
        // perdeu: a tabela tem que concordar, e o certo e os alternativos
        // têm que manter.
        test('jogo livre: os erros perdem pela tabela; certo e alternativos '
            'mantêm', () {
          final wrong = <String>[];
          for (final (_, _, example) in free) {
            // A tabela local só cobre rei e peão contra rei; com mais
            // peças quem confere é o check_roteiro (tablebase).
            if (_pieces(example.questionFen) != 3) continue;
            final question = example.question!;
            final from = GameRules.fromFen(example.questionFen)!;
            final wantsWin = example.goal.wantsWin;
            MoveVerdict verdict(String uci) => JudgeMove.ofOutcome(
              _kpk.evaluate(from.playUnchecked(Move.parse(uci)!)),
              wantsWin: wantsWin,
            );
            for (final uci in question.errors.keys) {
              if (verdict(uci) != MoveVerdict.loses) {
                wrong.add('${example.id}: erro $uci mantém');
              }
            }
            for (final uci in [
              ...question.right,
              ...question.alternatives.keys,
            ]) {
              if (verdict(uci) != MoveVerdict.keeps) {
                wrong.add('${example.id}: $uci perde');
              }
            }
          }
          expect(wrong, isEmpty);
        });
      }
      for (final (stage, index, example) in free) {
        for (final (n, uci) in _offLine(example).indexed) {
          test('jogo livre: ${example.id} $uci', () async {
            final (run, _) = await _open(id);
            for (var i = 0; i < 200; i++) {
              final s = run.s;
              if (s.stageIndex == stage &&
                  s.exampleIndex == index &&
                  s.phase == ScriptPhase.pergunta) {
                break;
              }
              if (!await run.step(withErrors: false)) break;
            }
            expect(run.s.phase, ScriptPhase.pergunta);
            final game = await _freeGame(run, example, uci, branch: n == 0);
            // O erro previsto sempre acaba em jogo livre (a pergunta tem um).
            if (example.question!.errors.containsKey(uci)) {
              expect(game.ended, isTrue, reason: 'o jogo livre não acabou');
            }
            // Partida que acaba antes do 4º lance não tem onde ramificar.
            if (n == 0 && game.longest >= 4) expect(game.branched, isTrue);
            expect(
              run.problems,
              isEmpty,
              reason: 'caminho:\n${run.trail.takeLast(12).join('\n')}',
            );
          });
        }
      }
    });
  }
}

extension<T> on List<T> {
  Iterable<T> takeLast(int n) => skip(length > n ? length - n : 0);
}
