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
import 'lesson_script_state.dart';

export 'lesson_script_state.dart';

/// Espera [duration]. Nos testes, volta na hora.
typedef ScriptDelay = Future<void> Function(Duration duration);

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
    this.fens = const [],
    this.kept = false,
  });

  /// `entrada`, `main`, `reveal`, `alt:<uci>` (ScriptTracks), `err:<uci>`,
  /// `fora:<uci>`, `question`, `free`, `pratica`.
  final String track;
  final List<ScriptStep> steps;

  /// O trecho em tela: [head] até [end] (exclusivo).
  final int head;
  final int end;

  /// As posições do jogo livre ou da prática, da primeira à atual.
  final List<String> fens;

  /// Jogo livre que ainda mantém o resultado do aluno.
  final bool kept;
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
  }) : _delay = delay ?? ((duration) => Future<void>.delayed(duration)),
       super(const LessonScriptState());

  /// O tempo da máquina antes de responder, e de o lance errado da prática
  /// ser desfeito.
  static const machineDelay = Duration(milliseconds: 500);
  static const undoDelay = Duration(milliseconds: 800);

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
  final _seenBy = <int, Map<String, ScriptRef>>{};
  final _history = <_Frame>[];
  _Scene _scene = const _Scene(track: ScriptTracks.entry);
  SpeechFits? _fits;
  int _tick = 0;
  int _epoch = 0;

  Map<String, ScriptRef> get _seen =>
      _seenBy.putIfAbsent(_exampleIndex, () => {});

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

  Future<void> _enterStage(int index) async {
    _stage = index;
    _history.clear();
    _seenBy.clear();
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
    _loadExample(index);
    _epoch++;
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

  // ---- Estado -------------------------------------------------------------

  Side _sideOf(String fen) =>
      fen.split(' ').elementAtOrNull(1) == 'b' ? Side.black : Side.white;

  /// Põe no estado o que vale para a tela toda e emite.
  void _publish(LessonScriptState s) {
    final seen = _seen;
    emit(
      s.copyWith(
        ready: true,
        stageIndex: _stage,
        stageCount: _script.stages.length,
        stageId: _stageData.id,
        exampleIndex: _exampleIndex,
        exampleCount: _stageData.examples.length,
        orientation: _example.student,
        canBack: _history.isNotEmpty,
        curiosities: _curiosities,
        moves: [
          for (final node in _tree.nodes)
            if (seen.containsKey(node.id))
              ScriptMoveEntry(
                id: node.id,
                san: node.san,
                number: node.number,
                side: node.side,
                variant: node.variant,
              ),
        ],
      ),
    );
  }

  void _present((LessonScriptState, _Scene) built) {
    _scene = built.$2;
    _publish(built.$1);
  }

  void _push() => _history.add(_Frame(state, _scene));

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
    return (built, _Scene(track: track, steps: steps, head: head, end: stop));
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
        await _nextStage();
      case ScriptAction.voltarInicio:
        await _backToStart();
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
            fens: [_scene.steps.last.fen],
            kept: false,
            speech: _say(_example.question!.free.t),
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
      await _enterStage(next);
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
    if (_history.isEmpty) return;
    _epoch++;
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
    final from = state.fen;
    final last = state.transition;
    final undo =
        last.kind == TransitionKind.move && last.fromFen == frame.state.fen;
    if (frame.state.exampleIndex != _exampleIndex) {
      _loadExample(frame.state.exampleIndex);
    }
    _scene = frame.scene;
    _publish(
      frame.state.copyWith(
        machineThinking: false,
        transition: ScriptTransition(
          id: ++_tick,
          kind: undo ? TransitionKind.back : TransitionKind.jump,
          fromFen: from,
          ucis: undo ? last.ucis : const [],
        ),
      ),
    );
  }

  /// Toque num lance já visto: mostra o passo dele (e a fala).
  void goToMove(String id) {
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
        await _freeProceed(
          fens: [from, after.fen],
          kept: true,
          speech: _say('gen.foraMantem.$_goalName'),
          uci: uci,
          fromFen: from,
        );
      }
    }
  }

  // ---- Jogo livre ---------------------------------------------------------

  Side get _machineSide => _example.isPractice
      ? _example.practice!.machine
      : _example.question!.free.machine;

  Future<void> _startFree({
    required List<String> fens,
    required bool kept,
    required String speech,
  }) async {
    final fen = fens.last;
    _scene = _Scene(track: 'free', fens: fens, kept: kept);
    _publish(
      state.copyWith(
        phase: kept ? ScriptPhase.livreMantido : ScriptPhase.livrePerdido,
        fen: fen,
        speech: [speech],
        tone: ScriptTone.neutral,
        marks: const [],
        arrows: const [],
        primary: null,
        secondary: null,
        movable: _sideOf(fen) == _machineSide ? null : _sideOf(fen),
        machineThinking: false,
        transition: _transition(const [], fromFen: fen),
      ),
    );
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
    final after = position.playUnchecked(move);
    await _freeProceed(
      fens: [..._scene.fens, after.fen],
      kept: kept,
      speech: speech,
      uci: move.uci,
      fromFen: from,
    );
  }

  /// Emite a posição depois do lance do aluno e passa a vez: fim de jogo ou
  /// resposta da máquina.
  Future<void> _freeProceed({
    required List<String> fens,
    required bool kept,
    required String speech,
    required String uci,
    required String fromFen,
  }) async {
    final end = FreePlayReferee.check(fens, limit: freeLimit);
    final scene = _Scene(track: 'free', fens: fens, kept: kept);
    final phase = kept ? ScriptPhase.livreMantido : ScriptPhase.livrePerdido;
    final base = state.copyWith(
      phase: phase,
      fen: fens.last,
      lastMove: uci,
      speech: [speech],
      tone: ScriptTone.neutral,
      marks: const [],
      arrows: const [],
      primary: null,
      secondary: null,
      movable: null,
      machineThinking: false,
      currentMoveId: null,
      transition: _transition([uci], fromFen: fromFen),
    );
    _scene = scene;
    if (end != null) {
      _publish(_finishFree(base, end, kept));
      return;
    }
    _publish(base);
    await _machineReply();
  }

  LessonScriptState _finishFree(
    LessonScriptState base,
    FreeEnd end,
    bool kept,
  ) {
    final free = _example.question!.free;
    final text = free.ends[end.name] ?? 'gen.fim.${end.name}';
    final idea = kept && end.meets(_wantsWin);
    return base.copyWith(
      phase: ScriptPhase.livreFim,
      speech: [_say(text), if (idea) _say('gen.voltaIdeia')],
      primary: idea ? ScriptAction.continuar : ScriptAction.voltarInicio,
      movable: null,
      machineThinking: false,
    );
  }

  /// A máquina responde depois de [machineDelay].
  Future<void> _machineReply() async {
    final epoch = _epoch;
    emit(state.copyWith(machineThinking: true, movable: null));
    await _delay(machineDelay);
    if (isClosed || epoch != _epoch) return;
    final fens = _scene.fens;
    final position = GameRules.fromFen(fens.last);
    final uci = position == null ? null : MachineMove.choose(_oracle, position);
    final move = uci == null ? null : Move.parse(uci);
    if (position == null || move == null) {
      emit(state.copyWith(machineThinking: false));
      return;
    }
    final after = position.playUnchecked(move);
    final all = [...fens, after.fen];
    final practice = state.phase == ScriptPhase.praticaVez;
    final limit = practice ? _example.practice!.limit : freeLimit;
    final end = FreePlayReferee.check(all, limit: limit);
    _scene = _Scene(track: _scene.track, fens: all, kept: _scene.kept);
    final base = state.copyWith(
      fen: after.fen,
      lastMove: uci,
      machineThinking: false,
      movable: null,
      transition: _transition([uci!], fromFen: fens.last),
    );
    if (end != null) {
      _publish(
        practice
            ? _finishPractice(base, end)
            : _finishFree(base, end, _scene.kept),
      );
      return;
    }
    _publish(base.copyWith(movable: _sideOf(after.fen)));
  }

  // ---- Prática ------------------------------------------------------------

  Future<void> _startPractice(String fromFen) async {
    final practice = _example.practice!;
    final fen = _example.fen;
    _scene = _Scene(track: 'pratica', fens: [fen]);
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
        movable: _sideOf(fen) == practice.machine ? null : _sideOf(fen),
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
    final fens = [..._scene.fens, after.fen];
    _scene = _Scene(track: 'pratica', fens: fens);
    final end = FreePlayReferee.check(fens, limit: _example.practice!.limit);
    final base = state.copyWith(
      fen: after.fen,
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
    _publish(base);
    await _machineReply();
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
