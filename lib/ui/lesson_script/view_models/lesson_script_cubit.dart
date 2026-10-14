// A tela de roteiro (T70): tabuleiro, balão do professor e botões, tocados
// por um `LessonScript` (pergunta, linha, jogo livre, prática).
//
// API para a tela (lote B):
//
// Estado (`LessonScriptState`, ver o arquivo dele):
//  - `ready`, `stageIndex/stageCount/stageId`, `exampleIndex/exampleCount`;
//  - `phase` (`ScriptPhase`: tabela 7.1 do contrato);
//  - tabuleiro: `fen`, `orientation` (embaixo = lado do aluno), `lastMove`,
//    `marks`, `arrows`, `movable` (lado que aceita toque; nulo = bloqueado),
//    `transition` (animar só quando o `id` muda);
//  - balão: `speech` (um ou mais balões), `tone` (neutro/certo/errado);
//  - botões: `primary` e `secondary` (`ScriptAction`; nulo = não aparece),
//    `canBack` (◀);
//  - lista de lances: `moves` (só os já vistos) e `currentMoveId`;
//  - `curiosities` (nula = sem o ícone do livro), `machineThinking`,
//    `outcome` (preenchido depois de `proximaParte`: navegar para a próxima
//    parte, `outcome.nextPart`).
//
// Métodos:
//  - `start()`: carrega e abre a etapa pedida;
//  - `onAction(ScriptAction)`: o que os botões fazem (passe `state.primary`
//    ou `state.secondary`);
//  - `onMove(uci)`: lance do aluno no tabuleiro (pergunta, jogo livre,
//    prática); o Future termina depois da resposta da máquina;
//  - `back()`: o ◀;
//  - `goToMove(id)`: toque num lance já visto da lista;
//  - `setSpeechFits(fn)`: a tela diz se uma lista de balões cabe na área
//    (junta trechos curtos); `null` desliga a junção.
import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/school/lesson_script_repository.dart';
import '../../../data/repositories/school/lesson_source.dart';
import '../../../data/repositories/tablebase/kpk_repository.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/kpk_outcome.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/lesson_script.dart';
import '../../../domain/use_cases/free_play_referee.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/group_speech.dart';
import '../../../domain/use_cases/judge_move.dart';
import '../../../domain/use_cases/kpk_oracle.dart';
import '../../../domain/use_cases/machine_move.dart';
import '../../../domain/use_cases/move_tree.dart';
import '../../../domain/use_cases/now.dart';
import 'lesson_script_state.dart';

export 'lesson_script_state.dart';

/// Espera [duration]. Nos testes, volta na hora.
typedef ScriptDelay = Future<void> Function(Duration duration);

/// Agenda [callback] para daqui a [duration] (o passo seguinte da
/// demonstração). Nos testes, um relógio controlado.
typedef DemoTimer = Timer Function(Duration duration, void Function() callback);

/// Uma fotografia da tela para o ◀.
class _Frame {
  const _Frame(this.state, this.scene);

  final LessonScriptState state;
  final _Scene scene;
}

/// O que a tela está tocando além do que o estado mostra.
class _Scene {
  const _Scene({
    required this.track,
    this.steps = const [],
    this.head = 0,
    this.end = 0,
    this.kept = false,
    this.cursor,
  });

  /// `entrada`, `main`, `reveal`, `alt:<uci>` (ScriptTracks), `err:<uci>`,
  /// `fora:<uci>`, `question`, `free`, `freeFora` (jogo livre depois de um
  /// lance fora do roteiro), `pratica`.
  final String track;
  final List<ScriptStep> steps;

  /// O trecho em tela: [head] até [end] (exclusivo).
  final int head;
  final int end;

  /// Jogo livre que ainda mantém o resultado do aluno.
  final bool kept;

  /// O lance da partida (refutação, jogo livre, prática) que está no
  /// tabuleiro; nulo = a posição de partida.
  final String? cursor;

  /// A mesma cena com o lance [cursor] no tabuleiro (para o ◀).
  _Scene at(String? cursor) => _Scene(
    track: track,
    steps: steps,
    head: head,
    end: end,
    kept: kept,
    cursor: cursor,
  );
}

/// Um lance da partida contra a máquina, na árvore da lista de lances: o
/// primeiro filho é a continuação; os outros, sublinhas (como no Lichess).
class _GameNode {
  _GameNode({
    required this.id,
    required this.parent,
    required this.uci,
    required this.san,
    required this.number,
    required this.side,
    required this.fen,
    this.symbol,
  });

  final String id;
  final String? parent;
  final String uci;
  final String san;
  final int number;
  final Side side;

  /// A posição depois do lance.
  final String fen;
  final String? symbol;
  final children = <String>[];

  /// O jogo livre ainda mantinha o resultado do aluno depois do lance.
  bool kept = false;

  /// Como a partida acabou neste lance; nulo se ela segue.
  FreeEnd? end;

  /// O resultado, se a partida acabou neste lance: quem coroou ganhou; o
  /// resto é empate.
  String? get result => switch (end) {
    null => null,
    FreeEnd.coroa => side == Side.white ? '1–0' : '0–1',
    _ => '½–½',
  };
}

class LessonScriptCubit extends Cubit<LessonScriptState> {
  LessonScriptCubit({
    required this.lessonId,
    required this.partId,
    required this.scriptPath,
    required this.language,
    required this._scripts,
    required this._kpk,
    required this._source,
    this.initialStage = 0,
    ScriptDelay? delay,
    this._now = const SystemNow(),
    this._timer = Timer.new,
  }) : _delay = delay ?? ((duration) => Future<void>.delayed(duration)),
       super(const LessonScriptState());

  /// O tempo de leitura de um passo da demonstração, como `DemoPace` da
  /// lição antiga (spike T51): 65 ms por letra, no mínimo 2,5 s, mais a
  /// pausa de 600 ms, com teto de 8 s.
  static Duration readTime(String text) =>
      Duration(milliseconds: min(max(2500, text.length * 65) + 600, 8000));

  /// O tempo da máquina antes de responder, e de o lance errado da prática
  /// ser desfeito.
  static const machineDelay = Duration(milliseconds: 500);
  static const undoDelay = Duration(milliseconds: 800);

  /// O tempo da fala de troca de lado: o tabuleiro gira (600 ms) e o aluno lê.
  static const switchDelay = Duration(milliseconds: 1600);

  /// O limite de lances completos do jogo livre.
  static const freeLimit = 40;

  final String lessonId;
  final String partId;
  final String scriptPath;
  final String language;
  final int initialStage;
  final LessonScriptRepository _scripts;
  final KpkRepository _kpk;
  final LessonSource _source;
  final ScriptDelay _delay;

  late LessonScript _script;
  late ScriptTexts _texts;
  late KpkOracle _oracle;
  List<Reference> _lessonRefs = const [];

  int _stage = 0;
  int _exampleIndex = 0;
  late ScriptExample _example;
  late MoveTree _tree;
  ScriptCuriosities? _curiosities;
  final _seenBy = <String, Map<String, ScriptRef>>{};
  final _history = <_Frame>[];
  _Scene _scene = const _Scene(track: ScriptTracks.entry);
  SpeechFits? _fits;
  int _tick = 0;
  int _epoch = 0;

  /// A partida contra a máquina (ids `g:N`): os lances, os de saída da
  /// posição [_gameRootFen] e o que está no tabuleiro.
  final _game = <String, _GameNode>{};
  final _gameTop = <String>[];
  String _gameRootFen = '';
  String? _cursor;
  int _gameSeq = 0;

  /// A fala do jogo livre, que volta quando o aluno toca num lance dele.
  String _freeSpeech = '';

  /// A demonstração automática: o relógio do passo em tela.
  final Now _now;
  final DemoTimer _timer;
  Timer? _demoTimer;
  bool _demoPlaying = true;
  String? _demoKey;
  int _demoTick = 0;
  Duration _demoTotal = Duration.zero;

  /// O tempo do passo já decorrido antes de [_demoRunStart].
  Duration _demoElapsed = Duration.zero;
  DateTime? _demoRunStart;

  Map<String, ScriptRef> get _seen =>
      _seenBy.putIfAbsent('$_stage/$_exampleIndex', () => {});

  ScriptStage get _stageData => _script.stages[_stage];

  String _say(String key) => _texts.say(key);

  // ---- Abertura -----------------------------------------------------------

  Future<void> start() async {
    _script = await _scripts.script(scriptPath);
    _texts = await _scripts.texts(lessonId, language);
    _oracle = await _kpk.oracle();
    try {
      _lessonRefs = await _source.references(lessonId);
    } on Object {
      _lessonRefs = const [];
    }
    final last = _script.stages.length - 1;
    await _enterStage(initialStage.clamp(0, last));
  }

  /// Abre a etapa [index]. [keep]: veio da etapa anterior pelo botão, e o ◀
  /// pode voltar a ela.
  Future<void> _enterStage(int index, {bool keep = false}) async {
    _stage = index;
    if (!keep) {
      _history.clear();
      _seenBy.clear();
    }
    _epoch++;
    await _source.saveCheckpoint(
      LessonCheckpoint(lessonId: lessonId, part: partId, step: index),
    );
    await _enterExample(0, jump: true);
  }

  void _loadExample(int index) {
    _exampleIndex = index;
    _example = _stageData.examples[index];
    _tree = MoveTree.build(_example);
    final c = _example.curiosities;
    _curiosities = c == null
        ? null
        : ScriptCuriosities(
            text: _say(c.t),
            quote: c.quote == null ? null : _say(c.quote!),
            quoteAuthor: c.quoteAuthor,
            references: [
              for (final ref in c.references) ?ref.resolve(_lessonRefs),
            ],
          );
  }

  Future<void> _enterExample(int index, {bool jump = false}) async {
    final side = state.orientation;
    _loadExample(index);
    _epoch++;
    // Troca de lado sem entrada que a anuncie (as posições da prática): o
    // Viktor avisa no balão e o tabuleiro gira à vista antes da posição nova.
    if (index > 0 && _example.entry.isEmpty && _example.student != side) {
      if (!await _announceSwitch()) return;
    }
    final from = state.fen.isEmpty ? _example.fen : state.fen;
    if (_example.isPractice) {
      _history.clear();
      await _startPractice(from);
      return;
    }
    if (_example.entry.isNotEmpty) {
      _present(
        _groupState(
          ScriptTracks.entry,
          _example.entry,
          0,
          fromFen: from,
          jump: true,
        ),
      );
    } else if (_example.question != null) {
      _showQuestion(fromFen: from, jump: true);
    } else {
      _present(
        _groupState(
          ScriptTracks.main,
          ScriptTracks.steps(_example, ScriptTracks.main),
          0,
          fromFen: from,
          jump: true,
        ),
      );
    }
  }

  /// Mostra a fala de troca de lado na posição que acabou, já com o lado
  /// novo (a tela gira o tabuleiro), e espera [switchDelay]. Falso se o aluno
  /// saiu dali no meio.
  Future<bool> _announceSwitch() async {
    final epoch = _epoch;
    _publish(
      state.copyWith(
        speech: [_say('gen.troca.${_example.student.name}')],
        tone: ScriptTone.neutral,
        marks: const [],
        arrows: const [],
        primary: null,
        secondary: null,
        movable: null,
        machineThinking: false,
        transition: _transition(const [], fromFen: state.fen),
      ),
    );
    await _delay(switchDelay);
    return !isClosed && epoch == _epoch;
  }

  // ---- Estado -------------------------------------------------------------

  Side _sideOf(String fen) =>
      fen.split(' ').elementAtOrNull(1) == 'b' ? Side.black : Side.white;

  /// Põe no estado o que vale para a tela toda e emite.
  void _publish(LessonScriptState s) {
    final seen = _seen;
    final demo = _inDemo;
    final game = _inGame;
    final right = _example.question?.rightStep;
    emit(
      s.copyWith(
        ready: true,
        stageIndex: _stage,
        stageCount: _script.stages.length,
        stageId: _stageData.id,
        exampleIndex: _exampleIndex,
        exampleCount: _stageData.examples.length,
        orientation: _example.student,
        canBack: _history.isNotEmpty || (demo && _stage > 0),
        curiosities: _curiosities,
        currentMoveId: game ? _cursor : s.currentMoveId,
        moves: [
          for (final node in _tree.nodes)
            if (seen.containsKey(node.id) &&
                (!game || node.ref.track == ScriptTracks.entry))
              ScriptMoveEntry(
                id: node.id,
                san: node.san,
                number: node.number,
                side: node.side,
                variant: node.variant,
                symbol: identical(node.step, right) ? '!' : null,
              ),
          if (game) ..._gameEntries(),
        ],
        demo: demo ? _demoState(s) : _demoStop(),
      ),
    );
  }

  // ---- Demonstração automática (etapa 2) ---------------------------------

  /// Etapa de demonstrações, num exemplo sem pergunta (com pergunta, segue a
  /// regra da etapa 1).
  bool get _inDemo =>
      _stageData.id == 'demos' &&
      _example.question == null &&
      !_example.isPractice;

  /// Fora da demonstração: para o relógio; a próxima começa andando.
  Null _demoStop() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _demoKey = null;
    _demoPlaying = true;
    return null;
  }

  Duration get _demoSpent => _demoRunStart == null
      ? _demoElapsed
      : _demoElapsed + _now().difference(_demoRunStart!);

  /// O estado da demonstração para [s]; num passo novo, zera o relógio e,
  /// andando, agenda o próximo.
  ScriptDemo _demoState(LessonScriptState s) {
    final ended = s.phase == ScriptPhase.fimEtapa;
    final key = '$_stage/$_exampleIndex/${_scene.track}/${_scene.head}';
    if (key != _demoKey) {
      _demoKey = key;
      _demoTick++;
      _demoTimer?.cancel();
      _demoTimer = null;
      _demoElapsed = Duration.zero;
      _demoRunStart = null;
      _demoTotal = readTime(s.speech.join(' '));
      if (_demoPlaying && !ended) _demoRun();
    }
    final spent = _demoSpent;
    final remaining = spent >= _demoTotal ? Duration.zero : _demoTotal - spent;
    return ScriptDemo(
      playing: _demoPlaying && !ended,
      ended: ended,
      progress: _demoTotal == Duration.zero
          ? 0
          : min(spent.inMicroseconds / _demoTotal.inMicroseconds, 1),
      remaining: remaining,
      tick: _demoTick,
      canStepBack: _stepBackIndex(s.fen) >= 0,
    );
  }

  /// Agenda o fim do passo com o tempo que falta.
  void _demoRun() {
    _demoTimer?.cancel();
    final left = _demoTotal - _demoElapsed;
    _demoRunStart = _now();
    _demoTimer = _timer(left.isNegative ? Duration.zero : left, () {
      _demoTimer = null;
      if (isClosed || !_inDemo) return;
      final action = state.primary;
      if (action != null) unawaited(onAction(action));
    });
  }

  /// Emite o estado da demonstração de novo (pausa, retomada).
  void _demoEmit() => emit(state.copyWith(demo: _demoState(state)));

  /// ⏸/▶: pausa onde está ou retoma de onde parou.
  void demoToggle() {
    if (!_inDemo || state.demo?.ended != false) return;
    if (_demoPlaying) {
      _demoPause();
    } else {
      _demoPlaying = true;
      _demoRun();
    }
    _demoEmit();
  }

  void _demoPause() {
    _demoElapsed = _demoSpent;
    _demoRunStart = null;
    _demoTimer?.cancel();
    _demoTimer = null;
    _demoPlaying = false;
  }

  /// ↻: recomeça a demonstração do exemplo, andando.
  Future<void> demoRepeat() async {
    if (!_inDemo) return;
    _history.removeWhere(
      (f) =>
          f.state.stageIndex == _stage && f.state.exampleIndex == _exampleIndex,
    );
    _seen.clear();
    _demoPlaying = true;
    _demoKey = null;
    await _enterExample(_exampleIndex, jump: true);
  }

  /// O quadro do ◀ com uma posição diferente de [fen], no mesmo exemplo;
  /// -1 se não tem.
  int _stepBackIndex(String fen) {
    for (var i = _history.length - 1; i >= 0; i--) {
      final f = _history[i].state;
      if (f.stageIndex != _stage || f.exampleIndex != _exampleIndex) break;
      if (f.fen != fen) return i;
    }
    return -1;
  }

  /// ⏮: volta ao lance anterior (a peça volta animando) e pausa.
  void demoStepBack() {
    if (!_inDemo) return;
    final index = _stepBackIndex(state.fen);
    if (index < 0) return;
    _demoPause();
    final frame = _history[index];
    // O quadro que chegou à posição atual diz o lance que a desfaz.
    final arrived = index + 1 < _history.length
        ? _history[index + 1].state.transition
        : state.transition;
    _history.removeRange(index, _history.length);
    final undo =
        arrived.kind == TransitionKind.move &&
        arrived.fromFen == frame.state.fen;
    _restore(frame, undo: undo ? arrived.ucis : null);
  }

  @override
  Future<void> close() {
    _demoTimer?.cancel();
    _demoTimer = null;
    return super.close();
  }

  /// A lista mostra a partida (e não o roteiro): refutação, jogo livre e
  /// prática.
  bool get _inGame {
    final track = _scene.track;
    return track.startsWith('err:') ||
        track.startsWith('fora:') ||
        track == 'free' ||
        track == 'freeFora' ||
        track == 'pratica';
  }

  // ---- Partida contra a máquina -------------------------------------------

  /// Começa uma partida nova em [fen].
  void _resetGame(String fen) {
    _game.clear();
    _gameTop.clear();
    _gameRootFen = fen;
    _cursor = null;
    _gameSeq = 0;
  }

  /// Joga [uci] depois do lance no tabuleiro: segue um lance que já existe
  /// ali ou abre um novo (sublinha, se já havia continuação).
  _GameNode? _playGame(String uci, {String? symbol}) {
    final parent = _cursor == null ? null : _game[_cursor];
    final siblings = parent?.children ?? _gameTop;
    for (final id in siblings) {
      if (_game[id]!.uci == uci) {
        _cursor = id;
        return _game[id];
      }
    }
    final position = GameRules.fromFen(parent?.fen ?? _gameRootFen);
    final move = Move.parse(uci);
    if (position == null || move == null) return null;
    final played = GameRules.play(position, move);
    final node = _GameNode(
      id: 'g:${++_gameSeq}',
      parent: _cursor,
      uci: uci,
      san: played?.san ?? uci,
      number: position.fullmoves,
      side: position.turn,
      fen: played?.position.fen ?? position.playUnchecked(move).fen,
      symbol: symbol,
    );
    _game[node.id] = node;
    siblings.add(node.id);
    _cursor = node.id;
    return node;
  }

  _GameNode? get _cursorNode => _cursor == null ? null : _game[_cursor];

  /// A posição no tabuleiro da partida.
  String get _gameFen => _cursorNode?.fen ?? _gameRootFen;

  /// As posições da partida, da de partida à do tabuleiro.
  List<String> _pathFens() {
    final fens = <String>[];
    for (var id = _cursor; id != null; id = _game[id]!.parent) {
      fens.add(_game[id]!.fen);
    }
    return [_gameRootFen, ...fens.reversed];
  }

  /// O fim da partida no lance do tabuleiro, marcado nele (a lista mostra o
  /// resultado); nulo se ela segue.
  FreeEnd? _markResult(int limit) {
    final end = FreePlayReferee.check(_pathFens(), limit: limit);
    _cursorNode?.end = end;
    return end;
  }

  /// A partida na ordem da notação: a continuação primeiro e, logo depois do
  /// lance que trocam, as sublinhas entre parênteses.
  List<ScriptMoveEntry> _gameEntries() {
    final out = <ScriptMoveEntry>[];
    ScriptMoveEntry entry(_GameNode n, int depth, {bool starts = false}) =>
        ScriptMoveEntry(
          id: n.id,
          san: n.san,
          number: n.number,
          side: n.side,
          variant: depth > 0,
          depth: depth,
          startsVariant: starts,
          symbol: n.symbol,
          result: n.result,
        );
    void line(List<String> kids, int depth) {
      while (kids.isNotEmpty) {
        final main = _game[kids.first]!;
        out.add(entry(main, depth));
        for (final id in kids.skip(1)) {
          final variant = _game[id]!;
          out.add(entry(variant, depth + 1, starts: true));
          line(variant.children, depth + 1);
        }
        kids = main.children;
      }
    }

    line(_gameTop, 0);
    return out;
  }

  /// A refutação (erro previsto ou lance fora que perde) é uma partida
  /// desde a pergunta, até o passo [stop] (exclusivo). Só o erro previsto
  /// leva "?": é o roteiro que o marca.
  void _refutationGame(String track, List<ScriptStep> steps, int stop) {
    _resetGame(_example.questionFen);
    final mark = track.startsWith('err:');
    for (var i = 0; i < stop; i++) {
      for (final uci in steps[i].moves) {
        _playGame(uci, symbol: mark && _gameTop.isEmpty ? '?' : null);
      }
    }
  }

  void _present((LessonScriptState, _Scene) built) {
    _scene = built.$2;
    _publish(built.$1);
  }

  void _push() => _history.add(_Frame(state, _scene.at(_cursor)));

  ScriptTransition _transition(
    List<String> ucis, {
    required String fromFen,
    bool jump = false,
    bool seq = false,
  }) {
    final kind = jump
        ? TransitionKind.jump
        : ucis.isEmpty
        ? TransitionKind.none
        : seq || ucis.length > 1
        ? TransitionKind.seq
        : TransitionKind.move;
    return ScriptTransition(
      id: ++_tick,
      kind: kind,
      fromFen: fromFen,
      ucis: ucis,
    );
  }

  // ---- Trechos ------------------------------------------------------------

  ScriptStep _nodeStep(String track, List<ScriptStep> steps, int i) =>
      track == ScriptTracks.reveal && i == 0
      ? _example.question!.rightStep
      : steps[i];

  void _markSeen(String track, List<ScriptStep> steps, int from, int to) {
    if (!_isScriptTrack(track)) return;
    for (var i = from; i < to; i++) {
      for (final node in _tree.of(_nodeStep(track, steps, i))) {
        _seen[node.id] = ScriptRef(track, i);
      }
    }
  }

  bool _isScriptTrack(String track) =>
      track == ScriptTracks.entry ||
      track == ScriptTracks.main ||
      track == ScriptTracks.reveal ||
      track.startsWith(ScriptTracks.altPrefix);

  /// O último lance (UCI) jogado até o passo [stop] (exclusivo), para
  /// destacar, e o nó dele na lista.
  ({String? uci, String? nodeId}) _lastMove(
    String track,
    List<ScriptStep> steps,
    int stop,
  ) {
    for (var i = stop - 1; i >= 0; i--) {
      final step = steps[i];
      if (!step.hasMove) continue;
      final nodes = _isScriptTrack(track)
          ? _tree.of(_nodeStep(track, steps, i))
          : const <MoveNode>[];
      return (uci: step.moves.last, nodeId: nodes.lastOrNull?.id);
    }
    if (track != ScriptTracks.entry && _isScriptTrack(track)) {
      return _lastMove(
        ScriptTracks.entry,
        _example.entry,
        _example.entry.length,
      );
    }
    return (uci: null, nodeId: null);
  }

  /// A posição antes do passo [head]: de onde a peça sai.
  String _preFen(String track, List<ScriptStep> steps, int head) => head > 0
      ? steps[head - 1].fen
      : track == ScriptTracks.entry
      ? _example.fen
      : _example.questionFen;

  ScriptPhase _phaseOf(String track, bool last) {
    if (track == ScriptTracks.entry) {
      final over = last && _example.question == null && _example.line.isEmpty;
      return over ? _endPhase : ScriptPhase.entrada;
    }
    if (!_isScriptTrack(track)) return ScriptPhase.refutacao;
    return last ? _endPhase : ScriptPhase.linha;
  }

  ScriptPhase get _endPhase => _example.end == ScriptEnd.etapa
      ? ScriptPhase.fimEtapa
      : ScriptPhase.fimExemplo;

  /// O estado do trecho que começa em [head] de [steps].
  (LessonScriptState, _Scene) _groupState(
    String track,
    List<ScriptStep> steps,
    int head, {
    required String fromFen,
    bool jump = false,
  }) {
    final stop = GroupSpeech.end(steps, head, _say, _fits);
    final first = steps[head];
    final last = steps[stop - 1];
    _markSeen(track, steps, head, stop);
    if (!_isScriptTrack(track)) _refutationGame(track, steps, stop);
    final phase = _phaseOf(track, stop == steps.length);
    final move = _lastMove(track, steps, stop);
    final ScriptAction action = switch (phase) {
      ScriptPhase.fimEtapa => ScriptAction.proximaEtapa,
      _ => ScriptAction.continuar,
    };
    final built = state.copyWith(
      phase: phase,
      fen: last.fen,
      lastMove: move.uci,
      speech: [for (var i = head; i < stop; i++) _say(steps[i].t)],
      tone: ScriptTone.neutral,
      marks: last.marks,
      arrows: last.arrows,
      primary: action,
      secondary: null,
      movable: null,
      machineThinking: false,
      currentMoveId: move.nodeId,
      transition: _transition(
        first.moves,
        fromFen: first.moves.isEmpty ? fromFen : _preFen(track, steps, head),
        jump: jump || first.jump,
        seq: first.seq.isNotEmpty,
      ),
    );
    return (
      built,
      _Scene(
        track: track,
        steps: steps,
        head: head,
        end: stop,
        cursor: _cursor,
      ),
    );
  }

  void _showQuestion({
    String? speechKey,
    required String fromFen,
    bool jump = false,
  }) => _present(_questionState(speechKey, fromFen, jump));

  (LessonScriptState, _Scene) _questionState(
    String? speechKey,
    String fromFen,
    bool jump,
  ) {
    final question = _example.question!;
    final fen = _example.questionFen;
    final move = _lastMove(
      ScriptTracks.entry,
      _example.entry,
      _example.entry.length,
    );
    return (
      state.copyWith(
        phase: ScriptPhase.pergunta,
        fen: fen,
        lastMove: move.uci,
        speech: [_say(speechKey ?? question.t)],
        tone: ScriptTone.neutral,
        marks: const [],
        arrows: const [],
        primary: null,
        secondary: ScriptAction.verResposta,
        movable: _sideOf(fen),
        machineThinking: false,
        currentMoveId: move.nodeId,
        transition: _transition(const [], fromFen: fromFen, jump: jump),
      ),
      const _Scene(track: 'question'),
    );
  }

  // ---- Botões -------------------------------------------------------------

  Future<void> onAction(ScriptAction action) async {
    switch (action) {
      case ScriptAction.continuar:
        await _continue();
      case ScriptAction.verResposta:
        if (state.phase != ScriptPhase.pergunta) return;
        _push();
        _present(
          _groupState(
            ScriptTracks.reveal,
            ScriptTracks.steps(_example, ScriptTracks.reveal),
            0,
            fromFen: state.fen,
          ),
        );
      case ScriptAction.proximaEtapa:
        _push();
        await _nextStage();
      case ScriptAction.voltarInicio:
        await _backToStart();
      case ScriptAction.linhaPrincipal:
        await _backToLine();
      case ScriptAction.reverIdeia:
        await _enterStage(0);
      case ScriptAction.proximaParte:
        await finishPart();
    }
  }

  Future<void> _continue() async {
    switch (state.phase) {
      case ScriptPhase.entrada:
        _push();
        if (_scene.end < _scene.steps.length) {
          _present(
            _groupState(
              _scene.track,
              _scene.steps,
              _scene.end,
              fromFen: state.fen,
            ),
          );
        } else if (_example.question != null) {
          _showQuestion(fromFen: state.fen);
        } else {
          _present(
            _groupState(
              ScriptTracks.main,
              ScriptTracks.steps(_example, ScriptTracks.main),
              0,
              fromFen: state.fen,
            ),
          );
        }
      case ScriptPhase.linha:
        _push();
        _present(
          _groupState(
            _scene.track,
            _scene.steps,
            _scene.end,
            fromFen: state.fen,
          ),
        );
      case ScriptPhase.refutacao:
        _push();
        if (_scene.end < _scene.steps.length) {
          _present(
            _groupState(
              _scene.track,
              _scene.steps,
              _scene.end,
              fromFen: state.fen,
            ),
          );
        } else {
          await _startFree(
            kept: false,
            speech: _say(_example.question!.free.t),
            offScript: _scene.track.startsWith('fora:'),
          );
        }
      case ScriptPhase.fimExemplo:
        _push();
        await _nextExample();
      case ScriptPhase.livreFim:
        await _backToLine();
      case ScriptPhase.praticaFim:
        await _nextExample();
      default:
        break;
    }
  }

  Future<void> _nextExample() async {
    final next = _exampleIndex + 1;
    if (next < _stageData.examples.length) {
      await _enterExample(next, jump: true);
    } else {
      await _nextStage();
    }
  }

  Future<void> _nextStage() async {
    final next = _stage + 1;
    if (next < _script.stages.length) {
      await _enterStage(next, keep: true);
    } else {
      await finishPart();
    }
  }

  /// Conclui a parte (`completePart`); a tela navega pelo `outcome`.
  Future<void> finishPart() async {
    final outcome = await _source.completePart(lessonId, partId);
    if (isClosed) return;
    emit(state.copyWith(outcome: outcome));
  }

  /// Volta à pergunta depois do jogo livre, ou recomeça a prática.
  Future<void> _backToStart() async {
    if (state.phase == ScriptPhase.praticaFim) {
      await _enterExample(_exampleIndex);
      return;
    }
    final index = _history.lastIndexWhere(
      (f) => f.state.phase == ScriptPhase.pergunta,
    );
    if (index < 0) return;
    _epoch++;
    _history.removeRange(index, _history.length);
    _showQuestion(
      speechKey: _example.question!.free.back,
      fromFen: state.fen,
      jump: true,
    );
  }

  /// O jogo livre acabou bem: volta à posição da pergunta e segue a linha a
  /// partir do lance certo, como se o aluno o tivesse jogado.
  Future<void> _backToLine() async {
    final index = _history.lastIndexWhere(
      (f) => f.state.phase == ScriptPhase.pergunta,
    );
    if (index < 0) return;
    _epoch++;
    _history.removeRange(index + 1, _history.length);
    final steps = ScriptTracks.steps(_example, ScriptTracks.main);
    _present(
      _groupState(ScriptTracks.main, steps, 0, fromFen: state.fen, jump: true),
    );
  }

  // ---- ◀ e lista ----------------------------------------------------------

  void back() {
    final demo = _inDemo;
    if (demo) _demoPause();
    if (_history.isEmpty) {
      // Etapa 2 aberta direto: o ◀ volta ao começo da etapa 1.
      if (demo && _stage > 0) unawaited(_enterStage(_stage - 1, keep: true));
      return;
    }
    final phase = state.phase;
    final _Frame frame;
    if (phase == ScriptPhase.refutacao ||
        phase == ScriptPhase.livrePerdido ||
        phase == ScriptPhase.livreMantido) {
      final index = _history.lastIndexWhere(
        (f) => f.state.phase == ScriptPhase.pergunta,
      );
      if (index < 0) return;
      frame = _history[index];
      _history.removeRange(index, _history.length);
    } else {
      frame = _history.removeLast();
    }
    final last = state.transition;
    final undo =
        last.kind == TransitionKind.move && last.fromFen == frame.state.fen;
    _restore(frame, undo: undo ? last.ucis : null);
  }

  /// Volta ao quadro [frame]; [undo]: os lances que a peça desfaz animando
  /// (senão, corte).
  void _restore(_Frame frame, {List<String>? undo}) {
    _epoch++;
    final from = state.fen;
    if (frame.state.stageIndex != _stage) {
      _stage = frame.state.stageIndex;
      _loadExample(frame.state.exampleIndex);
    } else if (frame.state.exampleIndex != _exampleIndex) {
      _loadExample(frame.state.exampleIndex);
    }
    _scene = frame.scene;
    _cursor = frame.scene.cursor;
    _publish(
      frame.state.copyWith(
        machineThinking: false,
        transition: ScriptTransition(
          id: ++_tick,
          kind: undo != null ? TransitionKind.back : TransitionKind.jump,
          fromFen: from,
          ucis: undo ?? const [],
        ),
      ),
    );
  }

  /// Toque num lance já visto: mostra o passo dele (e a fala).
  Future<void> goToMove(String id) async {
    if (_inDemo) _demoPause();
    if (_game.containsKey(id)) return _goToGameMove(id);
    final ref = _seen[id];
    if (ref == null || _example.isPractice) return;
    _epoch++;
    final steps = ScriptTracks.steps(_example, ref.track);
    final groups = GroupSpeech.groups(steps, _say, _fits);
    final target = groups.indexWhere(
      (g) => ref.index >= g.$1 && ref.index < g.$2,
    );
    if (target < 0) return;
    final frames = <_Frame>[];
    void collect(String track, List<ScriptStep> list, int count) {
      final all = GroupSpeech.groups(list, _say, _fits);
      for (var g = 0; g < count; g++) {
        final built = _groupState(track, list, all[g].$1, fromFen: state.fen);
        frames.add(_Frame(built.$1, built.$2));
      }
    }

    if (ref.track != ScriptTracks.entry) {
      collect(ScriptTracks.entry, _example.entry, _entryGroups);
      if (_example.question != null) {
        final built = _questionState(null, state.fen, false);
        frames.add(_Frame(built.$1, built.$2));
      }
    }
    collect(ref.track, steps, target);
    final current = _groupState(
      ref.track,
      steps,
      groups[target].$1,
      fromFen: state.fen,
      jump: true,
    );
    _history
      ..clear()
      ..addAll(frames);
    _present(current);
  }

  int get _entryGroups =>
      GroupSpeech.groups(_example.entry, _say, _fits).length;

  /// A tela mede se [fits] cabe; recompõe o trecho em tela.
  void setSpeechFits(SpeechFits? fits) {
    _fits = fits;
    if (!state.ready || _scene.steps.isEmpty) return;
    const grouped = {
      ScriptPhase.entrada,
      ScriptPhase.linha,
      ScriptPhase.fimExemplo,
      ScriptPhase.fimEtapa,
      ScriptPhase.refutacao,
    };
    if (!grouped.contains(state.phase)) return;
    final stop = GroupSpeech.end(_scene.steps, _scene.head, _say, fits);
    if (stop == _scene.end) return;
    final built = _groupState(
      _scene.track,
      _scene.steps,
      _scene.head,
      fromFen: state.fen,
    );
    _present((
      built.$1.copyWith(
        transition: ScriptTransition(id: ++_tick, fromFen: state.fen),
      ),
      built.$2,
    ));
  }

  // ---- Lance do aluno -----------------------------------------------------

  /// O lance [uci] legal em [position] (com dama quando o peão coroa), ou
  /// nulo.
  Move? _legal(Position position, String uci) {
    var move = Move.parse(uci);
    if (move is NormalMove &&
        move.promotion == null &&
        position.board.roleAt(move.from) == Role.pawn &&
        (move.to.rank == Rank.first || move.to.rank == Rank.eighth)) {
      move = NormalMove(from: move.from, to: move.to, promotion: Role.queen);
    }
    if (move == null || !position.isLegal(move)) return null;
    return move;
  }

  Future<void> onMove(String uci) async {
    final movable = state.movable;
    if (!state.ready || movable == null || movable != _sideOf(state.fen)) {
      return;
    }
    final position = GameRules.fromFen(state.fen);
    if (position == null) return;
    final move = _legal(position, uci);
    if (move == null) return;
    switch (state.phase) {
      case ScriptPhase.pergunta:
        await _answer(position, move);
      case ScriptPhase.livrePerdido || ScriptPhase.livreMantido:
        await _freeMove(position, move);
      case ScriptPhase.praticaVez:
        await _practiceMove(position, move);
      default:
        break;
    }
  }

  bool get _wantsWin => _example.goal.wantsWin;
  String get _goalName => _example.goal.name;

  Future<void> _answer(Position position, Move move) async {
    final question = _example.question!;
    final uci = move.uci;
    final from = state.fen;
    _push();
    final errors = question.errors[uci];
    final alternative = question.alternatives[uci];
    if (errors != null) {
      _present(_groupState('err:$uci', errors, 0, fromFen: from));
    } else if (alternative != null) {
      _present(
        _groupState(
          ScriptTracks.alt(uci),
          ScriptTracks.steps(_example, ScriptTracks.alt(uci)),
          0,
          fromFen: from,
        ),
      );
    } else if (question.right.contains(uci)) {
      _present(
        _groupState(
          ScriptTracks.main,
          ScriptTracks.steps(_example, ScriptTracks.main),
          0,
          fromFen: from,
        ),
      );
    } else {
      final after = position.playUnchecked(move);
      final verdict = JudgeMove.ofOutcome(
        _oracle.evaluate(after),
        wantsWin: _wantsWin,
      );
      if (verdict == MoveVerdict.loses) {
        _present(
          _groupState(
            'fora:$uci',
            [
              ScriptStep(
                fen: after.fen,
                t: 'gen.foraPerde.$_goalName',
                move: uci,
              ),
            ],
            0,
            fromFen: from,
          ),
        );
      } else {
        _resetGame(from);
        _playGame(uci)?.kept = true;
        _freeSpeech = _say('gen.foraMantem.$_goalName');
        await _freeProceed(
          kept: true,
          speech: _freeSpeech,
          uci: uci,
          fromFen: from,
          offScript: true,
        );
      }
    }
  }

  // ---- Jogo livre ---------------------------------------------------------

  Side get _machineSide => _example.isPractice
      ? _example.practice!.machine
      : _example.question!.free.machine;

  /// O jogo livre começou num lance fora do roteiro (e não num erro previsto).
  bool get _offScript => _scene.track == 'freeFora';

  /// O lado que joga na posição [fen] pode mexer: é a vez do aluno.
  Side? _studentTurn(String fen) =>
      _sideOf(fen) == _machineSide ? null : _sideOf(fen);

  /// Começa o jogo livre na posição da partida (depois da refutação).
  Future<void> _startFree({
    required bool kept,
    required String speech,
    required bool offScript,
  }) async {
    final fen = _gameFen;
    _freeSpeech = speech;
    _scene = _Scene(
      track: offScript ? 'freeFora' : 'free',
      kept: kept,
      cursor: _cursor,
    );
    final base = state.copyWith(
      phase: kept ? ScriptPhase.livreMantido : ScriptPhase.livrePerdido,
      fen: fen,
      speech: [speech],
      tone: ScriptTone.neutral,
      marks: const [],
      arrows: const [],
      primary: null,
      // Em todo jogo livre contra a máquina, a saída para a linha
      // principal fica embaixo (Gabriel, 14/10/2026).
      secondary: ScriptAction.linhaPrincipal,
      movable: _studentTurn(fen),
      machineThinking: false,
      transition: _transition(const [], fromFen: fen),
    );
    // A refutação pode ter acabado a partida (o rei capturou o peão).
    final end = _markResult(freeLimit);
    if (end != null) {
      _publish(_finishFree(base, end, kept));
      return;
    }
    _publish(base);
    if (_sideOf(fen) == _machineSide) await _machineReply();
  }

  Future<void> _freeMove(Position position, Move move) async {
    final from = state.fen;
    _push();
    var kept = _scene.kept;
    var speech = state.speech.first;
    if (state.phase == ScriptPhase.livreMantido) {
      final verdict = JudgeMove.judge(
        _oracle,
        position,
        move,
        wantsWin: _wantsWin,
      );
      kept = verdict == MoveVerdict.keeps;
      speech = _say(
        kept ? 'gen.segueBem.$_goalName' : 'gen.estragou.$_goalName',
      );
    }
    _playGame(move.uci)?.kept = kept;
    await _freeProceed(
      kept: kept,
      speech: speech,
      uci: move.uci,
      fromFen: from,
      offScript: _offScript,
    );
  }

  /// Emite a posição depois do lance do aluno (já na partida) e passa a
  /// vez: fim de jogo ou resposta da máquina.
  Future<void> _freeProceed({
    required bool kept,
    required String speech,
    required String uci,
    required String fromFen,
    required bool offScript,
  }) async {
    final end = _markResult(freeLimit);
    _scene = _Scene(
      track: offScript ? 'freeFora' : 'free',
      kept: kept,
      cursor: _cursor,
    );
    final phase = kept ? ScriptPhase.livreMantido : ScriptPhase.livrePerdido;
    final base = state.copyWith(
      phase: phase,
      fen: _gameFen,
      lastMove: uci,
      speech: [speech],
      tone: ScriptTone.neutral,
      marks: const [],
      arrows: const [],
      primary: null,
      secondary: ScriptAction.linhaPrincipal,
      movable: null,
      machineThinking: false,
      transition: _transition([uci], fromFen: fromFen),
    );
    if (end != null) {
      _publish(_finishFree(base, end, kept));
      return;
    }
    // A fala do lance do aluno só vem com a resposta da máquina; até lá, os
    // pontinhos no balão.
    _publish(base.copyWith(speech: state.speech, machineThinking: true));
    await _machineReply(speech: base.speech, tone: base.tone);
  }

  LessonScriptState _finishFree(
    LessonScriptState base,
    FreeEnd end,
    bool kept,
  ) {
    final free = _example.question!.free;
    final text = free.ends[end.name] ?? 'gen.fim.${end.name}';
    // Cumpriu o objetivo: o Viktor volta à ideia. Não cumpriu: diz o que a
    // posição dá e convida a ver a linha principal (Gabriel, 14/10/2026).
    final next = kept && end.meets(_wantsWin)
        ? 'gen.voltaIdeia'
        : end.meets(_wantsWin)
        ? null
        : 'gen.verLinha.$_goalName';
    return base.copyWith(
      phase: ScriptPhase.livreFim,
      speech: [_say(text), if (next != null) _say(next)],
      // Um botão só: voltar ao início e ver a linha davam no mesmo lugar
      // (Gabriel, 14/10/2026).
      primary: ScriptAction.linhaPrincipal,
      secondary: null,
      movable: null,
      machineThinking: false,
    );
  }

  /// A máquina responde depois de [machineDelay], com os pontinhos no balão;
  /// a resposta traz a fala [speech] (e o [tone]), se houver.
  Future<void> _machineReply({List<String>? speech, ScriptTone? tone}) async {
    final epoch = _epoch;
    emit(state.copyWith(machineThinking: true, movable: null));
    await _delay(machineDelay);
    if (isClosed || epoch != _epoch) return;
    final from = _gameFen;
    final position = GameRules.fromFen(from);
    final uci = position == null ? null : MachineMove.choose(_oracle, position);
    final node = uci == null ? null : _playGame(uci);
    if (node == null) {
      emit(
        state.copyWith(
          machineThinking: false,
          speech: speech ?? state.speech,
          tone: tone ?? state.tone,
        ),
      );
      return;
    }
    node.kept = _scene.kept;
    final practice = state.phase == ScriptPhase.praticaVez;
    final end = _markResult(practice ? _example.practice!.limit : freeLimit);
    _scene = _scene.at(_cursor);
    final base = state.copyWith(
      fen: node.fen,
      lastMove: uci,
      speech: speech ?? state.speech,
      tone: tone ?? state.tone,
      machineThinking: false,
      movable: null,
      transition: _transition([uci!], fromFen: from),
    );
    if (end != null) {
      _publish(
        practice
            ? _finishPractice(base, end)
            : _finishFree(base, end, _scene.kept),
      );
      return;
    }
    _publish(base.copyWith(movable: _sideOf(node.fen)));
  }

  /// Toque num lance da partida (jogo livre ou prática): o tabuleiro volta a
  /// ele e, se é a vez do aluno, ele pode jogar outro lance, que abre uma
  /// sublinha. Na refutação a lista só mostra.
  Future<void> _goToGameMove(String id) async {
    final node = _game[id]!;
    final practice = _example.isPractice;
    const free = {
      ScriptPhase.livrePerdido,
      ScriptPhase.livreMantido,
      ScriptPhase.livreFim,
    };
    const drill = {ScriptPhase.praticaVez, ScriptPhase.praticaFim};
    if (!(practice ? drill : free).contains(state.phase)) return;
    if (id == _cursor && !state.machineThinking) return;
    _epoch++;
    _push();
    _cursor = id;
    _scene = _Scene(track: _scene.track, kept: node.kept, cursor: id);
    final base = state.copyWith(
      phase: practice
          ? ScriptPhase.praticaVez
          : node.kept
          ? ScriptPhase.livreMantido
          : ScriptPhase.livrePerdido,
      fen: node.fen,
      lastMove: node.uci,
      speech: [practice ? _say(_example.practice!.t) : _freeSpeech],
      tone: ScriptTone.neutral,
      marks: const [],
      arrows: const [],
      primary: null,
      secondary: practice ? null : ScriptAction.linhaPrincipal,
      movable: _studentTurn(node.fen),
      machineThinking: false,
      transition: _transition(const [], fromFen: state.fen, jump: true),
    );
    final end = node.end;
    if (end != null) {
      _publish(
        practice
            ? _finishPractice(base, end)
            : _finishFree(base, end, node.kept),
      );
      return;
    }
    _publish(base);
    // O lance do aluno ainda sem resposta (tocado enquanto a máquina
    // pensava): ela responde agora.
    if (base.movable == null && node.children.isEmpty) await _machineReply();
  }

  // ---- Prática ------------------------------------------------------------

  Future<void> _startPractice(String fromFen) async {
    final practice = _example.practice!;
    final fen = _example.fen;
    _resetGame(fen);
    _scene = const _Scene(track: 'pratica');
    _publish(
      state.copyWith(
        phase: ScriptPhase.praticaVez,
        fen: fen,
        lastMove: null,
        speech: [_say(practice.t)],
        tone: ScriptTone.neutral,
        marks: const [],
        arrows: const [],
        primary: null,
        secondary: null,
        movable: _studentTurn(fen),
        machineThinking: false,
        currentMoveId: null,
        transition: _transition(const [], fromFen: fromFen, jump: true),
      ),
    );
    if (_sideOf(fen) == practice.machine) await _machineReply();
  }

  Future<void> _practiceMove(Position position, Move move) async {
    final uci = move.uci;
    final from = state.fen;
    final verdict = JudgeMove.judge(
      _oracle,
      position,
      move,
      wantsWin: _wantsWin,
    );
    final after = position.playUnchecked(move);
    if (verdict == MoveVerdict.loses) {
      final epoch = ++_epoch;
      final before = state;
      emit(
        state.copyWith(
          fen: after.fen,
          lastMove: uci,
          speech: [_say('gen.pratica.errado.$_goalName')],
          tone: ScriptTone.bad,
          movable: null,
          transition: _transition([uci], fromFen: from),
        ),
      );
      await _delay(undoDelay);
      if (isClosed || epoch != _epoch) return;
      emit(
        before.copyWith(
          speech: [_say('gen.pratica.errado.$_goalName')],
          tone: ScriptTone.bad,
          transition: ScriptTransition(
            id: ++_tick,
            kind: TransitionKind.back,
            fromFen: after.fen,
            ucis: [uci],
          ),
        ),
      );
      return;
    }
    _push();
    _playGame(uci);
    _scene = _scene.at(_cursor);
    final end = _markResult(_example.practice!.limit);
    final base = state.copyWith(
      fen: _gameFen,
      lastMove: uci,
      speech: [_say('gen.pratica.certo')],
      tone: ScriptTone.good,
      movable: null,
      transition: _transition([uci], fromFen: from),
    );
    if (end != null) {
      _publish(_finishPractice(base, end));
      return;
    }
    _publish(
      base.copyWith(
        speech: state.speech,
        tone: state.tone,
        machineThinking: true,
      ),
    );
    await _machineReply(speech: base.speech, tone: base.tone);
  }

  LessonScriptState _finishPractice(LessonScriptState base, FreeEnd end) {
    final met = end.meets(_wantsWin);
    final last = _exampleIndex == _stageData.examples.length - 1;
    return base.copyWith(
      phase: ScriptPhase.praticaFim,
      speech: [
        _say(met ? 'gen.pratica.sucesso.$_goalName' : 'gen.fim.${end.name}'),
        if (met && _example.practice!.end != null)
          _say(_example.practice!.end!),
      ],
      tone: met ? ScriptTone.good : ScriptTone.neutral,
      primary: !met
          ? ScriptAction.voltarInicio
          : last
          ? ScriptAction.proximaParte
          : ScriptAction.continuar,
      secondary: met && last ? ScriptAction.reverIdeia : null,
      movable: null,
      machineThinking: false,
    );
  }
}
