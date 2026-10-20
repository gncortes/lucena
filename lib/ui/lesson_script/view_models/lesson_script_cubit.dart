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
//    parte, `outcome.nextPart`);
//  - prática de toque: `touching`, `touched` (verde), `touchMiss` (vermelho)
//    e `coordinates`; demonstração: `demo`.
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
//    (junta trechos curtos); `null` desliga a junção;
//  - `onSquare(casa)`: clique numa casa na prática de toque;
//  - `demoToggle()`, `demoRepeat()`, `demoStepBack()`, `demoVoice(speaking:)`:
//    a demonstração;
//  - `pauseForBackground()`/`resumeFromBackground()`: o app vai ao fundo e
//    volta (a demonstração espera).
import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/school/lesson_script_repository.dart';
import '../../../data/repositories/school/lesson_source.dart';
import '../../../data/repositories/tablebase/kpk_repository.dart';
import '../../../data/repositories/tablebase/script_table_repository.dart';
import '../../core/sound/game_sounds.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../domain/models/kpk_outcome.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/lesson_script.dart';
import '../../../domain/models/script_table.dart';
import '../../../domain/models/wdl.dart';
import '../../../domain/use_cases/free_play_referee.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/group_speech.dart';
import '../../../domain/use_cases/judge_move.dart';
import '../../../domain/use_cases/kpk_oracle.dart';
import '../../../domain/use_cases/machine_move.dart';
import '../../../domain/use_cases/move_tree.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/position_judge.dart';
import '../../../domain/use_cases/script_moves.dart';
import '../../../domain/use_cases/spoken_text.dart';
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
/// O que o "Tentar de novo" restaura depois da refutação de um erro.
class _Refutation {
  const _Refutation({
    required this.before,
    required this.scene,
    required this.cursor,
    required this.known,
  });

  final LessonScriptState before;
  final _Scene scene;
  final String? cursor;

  /// Os nós da partida de antes do erro.
  final Set<String> known;
}

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

  /// Quem ganhou, na coroação e no mate (T76): o dono da peça coroada, ou
  /// quem deu o mate.
  Side? winner;

  /// O resultado, se a partida acabou neste lance: quem coroou ganhou; o
  /// resto é empate.
  String? get result => switch (end) {
    null => null,
    FreeEnd.coroa ||
    FreeEnd.mate => (winner ?? side) == Side.white ? '1–0' : '0–1',
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
    this._opponent,
    this._tables,
    this._engineJudge,
    this._sounds,
  }) : _delay = delay ?? ((duration) => Future<void>.delayed(duration)),
       super(const LessonScriptState());

  /// Os sons das peças (ligados ou não em Som e voz); nulo nos testes.
  final GameSounds? _sounds;

  /// Todo lance que entra no tabuleiro, de quem quer que seja (aluno,
  /// máquina, demonstração), toca o som dele. Voltar um passo não toca: o
  /// lance só vale quando sai da posição anterior e chega na nova.
  @override
  void onChange(Change<LessonScriptState> change) {
    super.onChange(change);
    final sounds = _sounds;
    if (sounds == null) return;
    final san = playedSan(change.currentState, change.nextState);
    if (san != null) unawaited(sounds.move(san));
  }

  /// O SAN do lance que leva de [from] a [to], ou nulo quando não foi um
  /// lance (passo novo, voltar, troca de exemplo).
  static String? playedSan(LessonScriptState from, LessonScriptState to) {
    final uci = to.lastMove;
    if (uci == null || from.fen.isEmpty || from.fen == to.fen) return null;
    if (uci == from.lastMove && from.fen == to.fen) return null;
    try {
      final before = Chess.fromSetup(Setup.parseFen(from.fen));
      final move = Move.parse(uci);
      if (move == null || !before.isLegal(move)) return null;
      final (after, san) = before.makeSan(move);
      final board = to.fen.split(' ').first;
      return after.fen.split(' ').first == board ? san : null;
    } on Object {
      return null;
    }
  }

  /// O tempo de leitura de um passo da demonstração, como `DemoPace` da
  /// lição antiga (spike T51): 65 ms por letra, no mínimo 2,5 s, mais a
  /// pausa de 600 ms, com teto de 8 s.
  static Duration readTime(String text) =>
      Duration(milliseconds: min(max(2500, text.length * 65) + 600, 8000));

  /// Com a voz, o passo espera a fala acabar e só faz esta pausa depois.
  static const voicePause = Duration(milliseconds: 600);

  /// Na teoria (etapa 1) o aluno lê e olha o tabuleiro com mais calma: uma
  /// vez e meia o [readTime] (Gabriel, 16/10/2026).
  static Duration theoryReadTime(String text) => readTime(text) * 1.5;

  /// A pausa depois da voz na teoria.
  static const theoryVoicePause = Duration(milliseconds: 1500);

  /// O teto da espera pela voz: se o TTS travar falando (sem avisar o fim),
  /// depois de quatro vezes o tempo de leitura o passo segue como se a fala
  /// tivesse acabado.
  static Duration speechCap(String text) => readTime(text) * 4;

  /// O tempo da máquina antes de responder, e de o lance errado da prática
  /// ser desfeito.
  static const machineDelay = Duration(milliseconds: 500);
  static const undoDelay = Duration(milliseconds: 800);

  /// O intervalo entre os lances da refutação de um erro da prática: ritmo
  /// de quem lê e olha o tabuleiro.
  static const refuteDelay = Duration(milliseconds: 1400);

  /// O tempo que o Stockfish pensa no objetivo `mate`.
  static const engineTime = Duration(milliseconds: 400);

  /// O tempo da fala de troca de lado: o tabuleiro gira (600 ms) e o aluno lê.
  static const switchDelay = Duration(milliseconds: 1600);

  /// O limite de lances completos do jogo livre.
  static const freeLimit = 40;

  final String lessonId;
  final String partId;
  final String scriptPath;

  /// A aula é da trilha de finais (a tela de fim volta para ela); falso na
  /// escola (segue para a próxima aula do curso).
  bool get endgame => _source.endgame;
  final String language;
  final int initialStage;
  final LessonScriptRepository _scripts;
  final KpkRepository _kpk;
  final LessonSource _source;
  final ScriptDelay _delay;

  /// O motor que defende no objetivo `mate` (sem ele, a máquina joga o
  /// primeiro lance legal).
  final OpponentRepository? _opponent;

  /// As tabelas dos roteiros com mais de 3 peças (T76); sem ela, só a KPK.
  final ScriptTableRepository? _tables;

  /// O juiz de reserva (o Stockfish), para a posição fora das tabelas.
  final PositionJudge? _engineJudge;

  late LessonScript _script;
  late ScriptTexts _texts;
  late KpkOracle _oracle;
  ScriptTable _table = ScriptTable.empty;

  /// O juiz dos lances: KPK, a tabela do roteiro e o motor (T76).
  late PositionJudge _judge;
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

  /// O app está em segundo plano: a demonstração espera parada.
  bool _background = false;
  bool _demoPlaying = true;
  String? _demoKey;
  int _demoTick = 0;
  Duration _demoTotal = Duration.zero;

  /// O tempo do passo já decorrido antes de [_demoRunStart].
  Duration _demoElapsed = Duration.zero;
  DateTime? _demoRunStart;

  /// A voz do Viktor está dizendo a fala do passo: o relógio espera.
  bool _demoSpeaking = false;

  Map<String, ScriptRef> get _seen =>
      _seenBy.putIfAbsent('$_stage/$_exampleIndex', () => {});

  ScriptStage get _stageData => _script.stages[_stage];

  String _say(String key) => _texts.say(key);

  // ---- Abertura -----------------------------------------------------------

  Future<void> start() async {
    _script = await _scripts.script(scriptPath);
    _texts = await _scripts.texts(lessonId, language);
    _oracle = await _kpk.oracle();
    _table = await _tables?.table(scriptPath) ?? ScriptTable.empty;
    _judge = LayeredJudge(_oracle, _table, _engineJudge);
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
    // Só a posição com curiosidade própria mostra o livro; sem ela, é só
    // um exemplo (Gabriel, 14/10/2026).
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

  /// Mostra a fala de troca de lado já na posição nova e virada: um
  /// crossfade só, sem passar pela posição que acabou virada (canvas
  /// `T70-etapa1-estados`, E13g3). Espera [switchDelay]. Falso se o aluno
  /// saiu dali no meio.
  Future<bool> _announceSwitch() async {
    final epoch = _epoch;
    final from = state.fen;
    _resetGame(_example.fen);
    _publish(
      state.copyWith(
        fen: _example.fen,
        lastMove: null,
        currentMoveId: null,
        speech: [_say('gen.troca.${_example.student.name}')],
        tone: ScriptTone.neutral,
        marks: const [],
        arrows: const [],
        primary: null,
        secondary: null,
        movable: null,
        machineThinking: false,
        transition: _transition(const [], fromFen: from, jump: true),
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
    final touch =
        _practiceKind == PracticeKind.toque &&
        (s.phase == ScriptPhase.praticaVez ||
            s.phase == ScriptPhase.praticaFim);
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
        demo: _autoPlays(s) ? _demoState(s) : _demoStop(),
        dests: s.movable == null
            ? null
            : ScriptMoves.dests(s.fen, pieces: _movablePieces(s.phase)),
        stars: _starsLeft(s.phase),
        touching: touch && s.phase == ScriptPhase.praticaVez,
        touched: touch ? s.touched : const [],
        touchMiss: touch ? s.touchMiss : null,
        coordinates: !touch || _example.practice!.coordinates,
      ),
    );
  }

  // ---- Tarefa sem adversário (curso de iniciante) -------------------------

  /// O exemplo é uma tarefa: a vez não passa.
  bool get _task => _example.goal == ScriptGoal.tarefa;

  PracticeKind? get _practiceKind => _example.practice?.kind;

  /// Os lances da partida, da posição de partida ao tabuleiro.
  List<String> _pathUcis() {
    final ucis = <String>[];
    for (var id = _cursor; id != null; id = _game[id]!.parent) {
      ucis.add(_game[id]!.uci);
    }
    return ucis.reversed.toList();
  }

  /// As casas das peças que o aluno pode mover na fase [phase]; nulo: todas
  /// do lado. Na prática, as peças andam: segue cada uma pela partida.
  List<String>? _movablePieces(ScriptPhase phase) {
    if (phase == ScriptPhase.pergunta) return _example.question?.pieces;
    final initial = _example.practice?.pieces;
    if (phase != ScriptPhase.praticaVez || initial == null) return null;
    final squares = [...initial];
    for (final uci in _pathUcis()) {
      final at = squares.indexOf(uci.substring(0, 2));
      if (at >= 0) squares[at] = uci.substring(2, 4);
    }
    return squares;
  }

  /// As estrelas que a partida ainda não pegou.
  List<String> _starsLeft([ScriptPhase? phase]) {
    final practice = _example.practice;
    if (practice == null || practice.kind != PracticeKind.estrelas) {
      return const [];
    }
    final landed = {for (final uci in _pathUcis()) uci.substring(2, 4)};
    return [
      for (final star in practice.stars)
        if (!landed.contains(star)) star,
    ];
  }

  // ---- Passo automático (etapas 1 e 2) -----------------------------------

  /// Etapa de demonstrações, num exemplo sem pergunta (com pergunta, segue a
  /// regra da etapa 1).
  bool get _inDemo =>
      _stageData.id == 'demos' &&
      _example.question == null &&
      !_example.isPractice;

  /// As fases da etapa 1 que só pedem "Continuar".
  static const _theoryPhases = {
    ScriptPhase.entrada,
    ScriptPhase.linha,
    ScriptPhase.fimExemplo,
  };

  /// Na etapa 1 (teoria), as falas que só pedem "Continuar" também passam
  /// sozinhas, no ritmo da voz do Viktor, com o anel e o ⏸ (Gabriel,
  /// 16/10/2026: "antes do aluno ficar clicando em continuar toda hora").
  /// A pergunta, a refutação de um erro, o jogo livre e o fim da etapa
  /// esperam o aluno.
  bool _inTheory(LessonScriptState s) =>
      _stageData.id == 'ideia' &&
      !_example.isPractice &&
      !_inGame &&
      _theoryPhases.contains(s.phase) &&
      s.primary == ScriptAction.continuar &&
      s.secondary == null;

  /// O passo em tela anda sozinho: a demonstração ou a teoria.
  bool _autoPlays(LessonScriptState s) => _inDemo || _inTheory(s);

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

  /// Para o relógio do passo onde está (pausa, voz, segundo plano).
  void _demoHold() {
    _demoElapsed = _demoSpent;
    _demoRunStart = null;
    _demoTimer?.cancel();
    _demoTimer = null;
  }

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
      _demoSpeaking = false;
      _demoTotal = _inDemo
          ? readTime(s.speech.join(' '))
          : theoryReadTime(s.speech.join(' '));
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
      speaking: _demoSpeaking,
      full: _inDemo,
    );
  }

  /// Agenda o fim do passo com o tempo que falta (com a voz falando, espera
  /// ela acabar: [demoVoice], até o [speechCap]).
  void _demoRun() {
    _demoTimer?.cancel();
    if (_background) {
      _demoTimer = null;
      _demoRunStart = null;
      return;
    }
    if (_demoSpeaking) {
      _demoRunStart = null;
      _demoTimer = _timer(
        speechCap(state.speech.join(' ')) * (_inDemo ? 1 : 1.5),
        () {
          _demoTimer = null;
          if (isClosed || state.demo == null || !_demoSpeaking) return;
          demoVoice(speaking: false);
        },
      );
      return;
    }
    final left = _demoTotal - _demoElapsed;
    _demoRunStart = _now();
    _demoTimer = _timer(left.isNegative ? Duration.zero : left, () {
      _demoTimer = null;
      if (isClosed || state.demo == null) return;
      final action = state.primary;
      if (action != null) unawaited(onAction(action));
    });
  }

  /// A voz do Viktor começou ([speaking]) ou acabou de dizer a fala do passo
  /// em tela (a tela conta). Falando, o relógio para; quando ela acaba, o
  /// passo só espera [voicePause]. Sem voz, vale o [readTime].
  void demoVoice({required bool speaking}) {
    if (state.demo?.ended != false) return;
    if (speaking == _demoSpeaking) return;
    _demoHold();
    _demoSpeaking = speaking;
    if (!speaking) {
      _demoElapsed = Duration.zero;
      _demoTotal = _inDemo ? voicePause : theoryVoicePause;
    }
    _demoEmit();
    if (_demoPlaying) _demoRun();
  }

  /// Emite o estado da demonstração de novo (pausa, retomada).
  void _demoEmit() => emit(state.copyWith(demo: _demoState(state)));

  /// ⏸/▶: pausa onde está ou retoma de onde parou.
  void demoToggle() {
    if (state.demo?.ended != false) return;
    if (_demoPlaying) {
      _demoPause();
    } else {
      _demoPlaying = true;
      _demoRun();
    }
    _demoEmit();
  }

  void _demoPause() {
    _demoHold();
    _demoPlaying = false;
  }

  /// O app foi para o segundo plano: tudo fica como está (a regra do
  /// Gabriel); a demonstração para o relógio onde está, sem pausar.
  void pauseForBackground() {
    if (_background) return;
    _background = true;
    _demoHold();
  }

  /// Voltou do segundo plano: a demonstração andando segue de onde estava.
  void resumeFromBackground() {
    if (!_background) return;
    _background = false;
    if (isClosed || state.demo?.ended != false) return;
    if (_demoPlaying) _demoRun();
    _demoEmit();
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
    final from = parent?.fen ?? _gameRootFen;
    final played = ScriptMoves.play(from, uci, keepTurn: _task);
    if (played == null) return null;
    // Na tarefa a vez não passa: os lances só se numeram, e o das pretas
    // fica com o número do lance das brancas que veio antes.
    final mover = _task
        ? ScriptMoves.moverOf(from, uci) ?? _example.student
        : _sideOf(from);
    final node = _GameNode(
      id: 'g:${++_gameSeq}',
      parent: _cursor,
      uci: uci,
      san: played.san,
      number: _task
          ? ScriptMoves.taskNumber(
              mover: mover,
              parentNumber: parent?.number,
              parentSide: parent?.side,
            )
          : int.tryParse(from.split(' ').elementAtOrNull(5) ?? '') ?? 1,
      side: mover,
      fen: played.fen,
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
  Future<FreeEnd?> _markResult(int limit) async {
    var end = FreePlayReferee.check(_pathFens(), limit: limit, mate: _mateGoal);
    final node = _cursorNode;
    final position = GameRules.fromFen(_gameFen);
    // Com mais de 3 peças, a coroação fecha a partida se quem coroou ganha
    // (pelo juiz); senão, ela segue (T76).
    if (end == null &&
        !_mateGoal &&
        node != null &&
        node.uci.length == 5 &&
        position != null &&
        position.board.occupied.size > 3 &&
        await _judge.evaluate(position) == Wdl.loss) {
      end = FreeEnd.coroa;
    }
    if (node != null) {
      node.end = end;
      node.winner = switch (end) {
        FreeEnd.coroa => _crownOwner(position) ?? node.side,
        FreeEnd.mate => node.side,
        _ => null,
      };
    }
    return end;
  }

  /// O dono da única peça além dos reis (a coroada), se há só três.
  static Side? _crownOwner(Position? position) {
    final board = position?.board;
    if (board == null || board.occupied.size != 3) return null;
    return board.occupied.squares
        .where((sq) => board.roleAt(sq) != Role.king)
        .map(board.sideAt)
        .firstOrNull;
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
      // O salto sem lance cai num lance já visto (ou no começo).
      final landing = _isScriptTrack(track) ? _nodeStep(track, steps, i) : step;
      if (!step.hasMove && _tree.anchors(landing)) {
        final id = _tree.anchorOf(landing);
        return (uci: id == null ? null : _tree.node(id)?.uci, nodeId: id);
      }
      if (!step.hasMove && _tree.of(landing).isEmpty) continue;
      final nodes = _isScriptTrack(track)
          ? _tree.of(_nodeStep(track, steps, i))
          : const <MoveNode>[];
      return (
        uci: step.hasMove ? step.moves.last : nodes.lastOrNull?.uci,
        nodeId: nodes.lastOrNull?.id,
      );
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
        // Ver resposta é o botão cheio (canvas E2a).
        primary: ScriptAction.verResposta,
        secondary: null,
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
      case ScriptAction.tentarDeNovo:
        _retryAfterError();
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
        } else if (_example.question!.free case final free?) {
          await _startFree(
            kept: false,
            speech: _say(free.t),
            offScript: _scene.track.startsWith('fora:'),
          );
        } else {
          _returnToQuestion();
        }
      case ScriptPhase.fimExemplo:
        _push();
        await _nextExample();
      case ScriptPhase.livreFim:
        if (state.primary != ScriptAction.continuar) {
          await _backToLine();
          return;
        }
        // Depois da fala do fim, o convite a ver a linha principal.
        _push();
        _publish(
          state.copyWith(
            speech: [_say(_seeLineKey)],
            primary: ScriptAction.linhaPrincipal,
          ),
        );
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

  /// Juiz lista: depois do erro, a pergunta de novo com a fala `volta`.
  void _returnToQuestion() {
    final question = _example.question!;
    final index = _history.lastIndexWhere(
      (f) => f.state.phase == ScriptPhase.pergunta,
    );
    if (index >= 0) _history.removeRange(index, _history.length);
    _epoch++;
    _showQuestion(
      speechKey: question.back ?? question.t,
      fromFen: state.fen,
      jump: true,
    );
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
      speechKey: _example.question!.free?.back,
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
    // Quem volta quer reler: o passo automático para onde está.
    if (state.demo != null) _demoPause();
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
    if (state.demo != null) _demoPause();
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

  Future<void> onMove(String uci) async {
    final movable = state.movable;
    if (!state.ready || movable == null || movable != _sideOf(state.fen)) {
      return;
    }
    final legal = ScriptMoves.legal(
      state.fen,
      uci,
      pieces: _movablePieces(state.phase),
    );
    if (legal == null) return;
    if (state.phase == ScriptPhase.pergunta) return _answer(legal);
    if (state.phase == ScriptPhase.praticaVez) {
      switch (_practiceKind) {
        case PracticeKind.estrelas:
          return _starMove(legal);
        case PracticeKind.lance:
          return _findMove(legal);
        case PracticeKind.toque:
          return;
        default:
          break;
      }
    }
    final position = GameRules.fromFen(state.fen);
    final move = Move.parse(legal);
    if (position == null || move == null) return;
    switch (state.phase) {
      case ScriptPhase.livrePerdido || ScriptPhase.livreMantido:
        await _freeMove(position, move);
      case ScriptPhase.praticaVez:
        await _practiceMove(position, move);
      default:
        break;
    }
  }

  bool get _wantsWin => _example.goal.wantsWin || _mateGoal;
  bool get _mateGoal => _example.goal == ScriptGoal.mate;

  /// O `mate` com tabela do roteiro (T77, bispo e cavalo): o lance do aluno é
  /// julgado como no `ganhar` e a máquina defende pela tabela. Sem tabela, o
  /// lance não é julgado e o Stockfish defende.
  bool get _mateByEngine => _mateGoal && _table.length == 0;

  /// O fim cumpre o objetivo: no `mate`, só o mate.
  /// Coroação e mate cumprem se o vencedor é o aluno (ganhar também cumpre o
  /// empatar); o resto cumpre só o empatar (T76).
  bool _meets(FreeEnd end) {
    if (_mateGoal) return end == FreeEnd.mate;
    final winner = _cursorNode?.winner;
    if (winner != null && (end == FreeEnd.coroa || end == FreeEnd.mate)) {
      return winner == _example.student;
    }
    return end.meets(_wantsWin);
  }

  // `casa` usa as falas genéricas do `ganhar`.
  String get _goalName =>
      _example.goal == ScriptGoal.casa ? 'ganhar' : _example.goal.name;

  /// A fala genérica do erro na prática: o `mate` usa a do `ganhar` (o lance
  /// que deixa a vitória escapar).
  String get _refuteGoal => _mateGoal ? 'ganhar' : _goalName;

  /// O convite a ver a linha principal (a fala com o link).
  String get _seeLineKey => 'gen.verLinha.$_goalName';

  Future<void> _answer(String uci) async {
    final question = _example.question!;
    final from = state.fen;
    final covered = question.covers(uci);
    if (!covered && question.judge == ScriptJudge.lista) {
      return _bounce(uci, question.outside ?? 'ini.fora');
    }
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
      final position = GameRules.fromFen(from)!;
      final after = position.playUnchecked(Move.parse(uci)!);
      final verdict = JudgeMove.ofWdl(
        await _judge.evaluate(after),
        wantsWin: _wantsWin,
      );
      if (isClosed) return;
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

  Side get _machineSide => _task
      ? _example.student.opposite
      : _example.isPractice
      ? _example.practice!.machine
      : _example.question!.free?.machine ?? _example.student.opposite;

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
    final end = await _markResult(freeLimit);
    if (isClosed) return;
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
      final verdict = await JudgeMove.judgeWith(
        _judge,
        position,
        move,
        wantsWin: _wantsWin,
      );
      if (isClosed) return;
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
    final end = await _markResult(freeLimit);
    if (isClosed) return;
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
    final text = free?.ends[end.name] ?? 'gen.fim.${end.name}';
    // Cumpriu o objetivo: o Viktor volta à ideia. Não cumpriu: diz o que a
    // posição dá e convida a ver a linha principal (Gabriel, 14/10/2026).
    final next = kept && _meets(end)
        ? 'gen.voltaIdeia'
        : _meets(end)
        ? null
        : _seeLineKey;
    if (next == _seeLineKey) {
      // A frase com o link é um passo sozinho, depois da fala do fim: no
      // balão de 2 linhas do 360 o link nunca fica no corte (T71, opção D).
      return base.copyWith(
        phase: ScriptPhase.livreFim,
        speech: [_say(text)],
        primary: ScriptAction.continuar,
        secondary: null,
        movable: null,
        machineThinking: false,
      );
    }
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
    final uci = position == null ? null : await _machineMove(position);
    if (isClosed || epoch != _epoch) return;
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
    final end = await _markResult(
      practice ? _example.practice!.limit : freeLimit,
    );
    if (isClosed || epoch != _epoch) return;
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

  /// O lance da máquina em [position]: no `mate` sem tabela, o do motor; até
  /// 3 peças, o da tabela KPK; com mais, o da tabela do roteiro e, fora dela,
  /// o do motor (T76). Sem motor, o da regra KPK (o primeiro lance legal).
  Future<String?> _machineMove(Position position) async {
    if (_mateByEngine) return _engineMove(position);
    if (position.board.occupied.size > 3) {
      final best = _table.best(position.fen);
      final move = best == null ? null : Move.parse(best);
      if (move != null && position.isLegal(move)) return best;
      if (_opponent != null) return _engineMove(position);
    }
    return MachineMove.choose(_oracle, position);
  }

  /// O lance do Stockfish (no máximo, como no app) em [position]. Se o motor
  /// falhar, o primeiro lance legal, para a prática não travar.
  Future<String?> _engineMove(Position position) async {
    try {
      final move = await _opponent?.pickMove(position, thinkTime: engineTime);
      if (move != null) return move.uci;
    } on Object {
      // Segue com o lance legal abaixo.
    }
    final moves = [
      for (final MapEntry(key: from, value: targets)
          in position.legalMoves.entries)
        for (final to in targets.squares) NormalMove(from: from, to: to).uci,
    ]..sort();
    return moves.firstOrNull;
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
    if (_practiceKind == PracticeKind.estrelas && _starsLeft().isEmpty) {
      _publish(_finishTask(base, 'ini.estrelas.sucesso'));
      return;
    }
    _publish(base);
    // O lance do aluno ainda sem resposta (tocado enquanto a máquina
    // pensava): ela responde agora.
    final game = !practice || _practiceKind == PracticeKind.jogo;
    if (game && base.movable == null && node.children.isEmpty) {
      await _machineReply();
    }
  }

  // ---- Prática ------------------------------------------------------------

  Future<void> _startPractice(String fromFen) async {
    final practice = _example.practice!;
    final fen = _example.fen;
    _resetGame(fen);
    _scene = const _Scene(track: 'pratica');
    final touch = practice.kind == PracticeKind.toque;
    _publish(
      state.copyWith(
        phase: ScriptPhase.praticaVez,
        fen: fen,
        lastMove: null,
        speech: [
          _say(practice.t),
          if (touch && practice.targets.isNotEmpty)
            _touchAsk(practice.targets.first),
        ],
        tone: ScriptTone.neutral,
        marks: const [],
        arrows: const [],
        primary: null,
        secondary: null,
        movable: touch ? null : _studentTurn(fen),
        machineThinking: false,
        currentMoveId: null,
        transition: _transition(const [], fromFen: fromFen, jump: true),
        touched: const [],
        touchMiss: null,
      ),
    );
    if (practice.kind == PracticeKind.jogo &&
        _sideOf(fen) == practice.machine) {
      await _machineReply();
    }
  }

  /// "Clique na casa {casa}."
  String _touchAsk(String square) =>
      _say('ini.toque.pedido').replaceAll('{casa}', square);

  /// Toque numa casa (prática do tipo toque): a pedida fica verde e vem a
  /// próxima; outra fica vermelha e o pedido continua o mesmo.
  Future<void> onSquare(String square) async {
    if (!state.ready || !state.touching) return;
    final targets = _example.practice!.targets;
    final done = state.touched.length;
    if (done >= targets.length) return;
    final target = targets[done];
    if (square != target) {
      _publish(
        state.copyWith(
          speech: [
            _say('ini.toque.errado')
                .replaceAll('{clicada}', square)
                .replaceAll('{casa}', target),
          ],
          tone: ScriptTone.bad,
          touchMiss: square,
        ),
      );
      return;
    }
    final touched = [...state.touched, square];
    final base = state.copyWith(
      touched: touched,
      touchMiss: null,
      tone: ScriptTone.good,
    );
    if (touched.length == targets.length) {
      _publish(_finishTask(base, 'ini.toque.sucesso'));
      return;
    }
    _publish(base.copyWith(speech: [_touchAsk(targets[touched.length])]));
  }

  /// O lance aparece, o Viktor diz [key] e a peça volta depois de
  /// [undoDelay] (lance fora da lista, erro na prática do tipo lance).
  Future<void> _bounce(String uci, String key) async {
    final from = state.fen;
    final played = ScriptMoves.play(from, uci, keepTurn: _task);
    if (played == null) return;
    final epoch = ++_epoch;
    final before = state;
    // Fala em duas partes (`.1` o que o lance perde, `.2` o porquê), como na
    // prática contra a máquina; sem partes, a chave inteira.
    final speech = _texts.has('$key.1')
        ? [_say('$key.1'), if (_texts.has('$key.2')) _say('$key.2')]
        : [_say(key)];
    emit(
      state.copyWith(
        fen: played.fen,
        lastMove: uci,
        speech: speech,
        tone: ScriptTone.bad,
        movable: null,
        dests: null,
        transition: _transition([uci], fromFen: from),
      ),
    );
    await _delay(undoDelay);
    if (isClosed || epoch != _epoch) return;
    emit(
      before.copyWith(
        speech: speech,
        tone: ScriptTone.bad,
        transition: ScriptTransition(
          id: ++_tick,
          kind: TransitionKind.back,
          fromFen: played.fen,
          ucis: [uci],
        ),
      ),
    );
  }

  /// Estrelas: a peça anda; pegou a última, acabou.
  Future<void> _starMove(String uci) async {
    final from = state.fen;
    _push();
    final node = _playGame(uci);
    if (node == null) return;
    _scene = _scene.at(_cursor);
    final base = state.copyWith(
      fen: node.fen,
      lastMove: uci,
      speech: [_say(_example.practice!.t)],
      tone: ScriptTone.neutral,
      movable: _example.student,
      transition: _transition([uci], fromFen: from),
    );
    _publish(
      _starsLeft().isEmpty ? _finishTask(base, 'ini.estrelas.sucesso') : base,
    );
  }

  /// Quantos lances do aluno a partida tem até o tabuleiro.
  int _studentMoves() {
    var count = 0;
    for (var id = _cursor; id != null; id = _game[id]!.parent) {
      if (_game[id]!.side == _example.student) count++;
    }
    return count;
  }

  /// Achar o lance: o certo segue (com a resposta, se há); o errado volta.
  Future<void> _findMove(String uci) async {
    final practice = _example.practice!;
    final turn = _studentMoves();
    if (turn >= practice.line.length) return;
    final step = practice.line[turn];
    if (!step.right.contains(uci)) {
      // Erro com fala própria: `erros` no primeiro lance, `errosPos` em
      // qualquer vez (pela posição).
      final error = practice.errorKey(state.fen, uci, start: _example.fen);
      return _bounce(uci, error ?? 'ini.lance.errado');
    }
    final from = state.fen;
    _push();
    if (_playGame(uci) == null) return;
    _scene = _scene.at(_cursor);
    var base = state.copyWith(
      fen: _gameFen,
      lastMove: uci,
      speech: [_say('ini.lance.certo')],
      tone: ScriptTone.good,
      movable: null,
      transition: _transition([uci], fromFen: from),
    );
    if (turn + 1 >= practice.line.length) {
      _publish(_finishTask(base, 'ini.lance.certo'));
      return;
    }
    final reply = step.reply;
    if (reply != null) {
      final epoch = ++_epoch;
      _publish(base.copyWith(machineThinking: true));
      await _delay(machineDelay);
      if (isClosed || epoch != _epoch) return;
      final before = _gameFen;
      if (_playGame(reply) == null) return;
      _scene = _scene.at(_cursor);
      base = state.copyWith(
        fen: _gameFen,
        lastMove: reply,
        machineThinking: false,
        transition: _transition([reply], fromFen: before),
      );
    }
    _publish(base.copyWith(movable: _example.student));
  }

  /// Fim da prática sem adversário: a fala de sucesso [key] e a do exemplo.
  LessonScriptState _finishTask(LessonScriptState base, String key) {
    final practice = _example.practice!;
    final last = _exampleIndex == _stageData.examples.length - 1;
    return base.copyWith(
      phase: ScriptPhase.praticaFim,
      speech: [_say(key), if (practice.end != null) _say(practice.end!)],
      tone: ScriptTone.good,
      primary: last ? ScriptAction.proximaParte : ScriptAction.continuar,
      secondary: last ? ScriptAction.reverIdeia : null,
      movable: null,
      machineThinking: false,
    );
  }

  Future<void> _practiceMove(Position position, Move move) async {
    final uci = move.uci;
    final from = state.fen;
    // No `mate` sem tabela o lance não é julgado: a partida corre.
    final verdict = _mateByEngine
        ? MoveVerdict.keeps
        : await JudgeMove.judgeWith(
            _judge,
            position,
            move,
            wantsWin: _wantsWin,
          );
    if (isClosed) return;
    if (verdict == MoveVerdict.loses) {
      return _refute(position, move, from);
    }
    _push();
    _playGame(uci);
    _scene = _scene.at(_cursor);
    final end = await _markResult(_example.practice!.limit);
    if (isClosed) return;
    final arrived = _example.kingOnSquare(GameRules.fromFen(_gameFen)!);
    final base = state.copyWith(
      fen: _gameFen,
      lastMove: uci,
      speech: _mateGoal ? state.speech : [_say('gen.pratica.certo')],
      tone: _mateGoal ? ScriptTone.neutral : ScriptTone.good,
      movable: null,
      transition: _transition([uci], fromFen: from),
    );
    if (arrived || end != null) {
      _publish(_finishPractice(base, arrived ? null : end));
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

  /// A refutação em andamento ou na tela: o que o "Tentar de novo" desfaz.
  _Refutation? _refutation;

  /// Lance que deixa o objetivo escapar na prática: fica no tabuleiro, o
  /// Viktor diz por que falha e a refutação (2 a 4 lances, da tabela) é
  /// jogada lance a lance. No fim, "Tentar de novo" volta à posição de antes.
  Future<void> _refute(Position position, Move move, String from) async {
    final uci = move.uci;
    final epoch = ++_epoch;
    final saved = _Refutation(
      before: state,
      scene: _scene,
      cursor: _cursor,
      known: _game.keys.toSet(),
    );
    _refutation = saved;
    // A refutação: o adversário responde, o aluno segue pelo melhor e o
    // adversário fecha (a escolha é a do MachineMove, igual nos dois lados).
    final plies = <String>[uci];
    var current = position.playUnchecked(move);
    for (var i = 0; i < 3 && current.board.pawns.isNotEmpty; i++) {
      final reply = await _machineMove(current);
      if (isClosed || epoch != _epoch) return;
      if (reply == null) break;
      plies.add(reply);
      current = current.playUnchecked(Move.parse(reply)!);
    }
    final fens = [from];
    final labels = <String>[];
    var walk = from;
    for (final ply in plies) {
      final played = ScriptMoves.play(walk, ply);
      if (played == null) break;
      labels.add(_numbered(walk, played.san));
      walk = played.fen;
      fens.add(walk);
    }
    // A fala do roteiro cita o lance numerado: vale só no primeiro lance da
    // prática. Em duas partes, `.1` (o que o lance perde) entra com o erro e
    // `.2` (o porquê, com a resposta) entra com a resposta e fica até o fim.
    final custom = _example.practice!.errorKey(from, uci, start: _example.fen);
    final split = custom != null && _texts.has('$custom.1');
    final why = split && _texts.has('$custom.2') ? _say('$custom.2') : null;
    final intro = custom != null
        ? _say(split ? '$custom.1' : custom)
        : labels.length < 2
        ? _say('gen.pratica.errado.$_refuteGoal')
        : _say('gen.pratica.refuta.$_refuteGoal')
              .replaceAll('{lance}', labels[0])
              .replaceAll('{lado}', _say('gen.lado.${_sideOf(fens[1]).name}'))
              .replaceAll('{resposta}', labels[1]);
    _playGame(uci, symbol: '?');
    _scene = _scene.at(_cursor);
    _publish(
      state.copyWith(
        fen: fens[1],
        lastMove: uci,
        speech: [intro],
        tone: ScriptTone.bad,
        movable: null,
        machineThinking: false,
        transition: _transition([uci], fromFen: from),
      ),
    );
    for (var i = 1; i < labels.length; i++) {
      await _delay(refuteDelay);
      if (isClosed || epoch != _epoch) return;
      _playGame(plies[i]);
      _scene = _scene.at(_cursor);
      _publish(
        state.copyWith(
          fen: fens[i + 1],
          lastMove: plies[i],
          speech: i == 1 && why != null ? [why] : state.speech,
          transition: _transition([plies[i]], fromFen: fens[i]),
        ),
      );
    }
    await _delay(refuteDelay);
    if (isClosed || epoch != _epoch) return;
    _publish(
      state.copyWith(
        phase: ScriptPhase.praticaFim,
        speech: [why ?? intro],
        tone: ScriptTone.bad,
        primary: ScriptAction.tentarDeNovo,
        secondary: null,
        movable: null,
      ),
    );
  }

  /// O lance de [fen] com número e a marca de quem joga: `1.Re3`, `1...Rf7`.
  String _numbered(String fen, String san) {
    final number = fen.split(' ').elementAtOrNull(5) ?? '1';
    final dots = _sideOf(fen) == Side.white ? '.' : '...';
    return '$number$dots${SpokenText.localSan(san, language)}';
  }

  /// "Tentar de novo": tira a refutação da partida e volta à posição de
  /// antes do erro, com a vez do aluno.
  void _retryAfterError() {
    final saved = _refutation;
    if (saved == null || state.phase != ScriptPhase.praticaFim) return;
    _refutation = null;
    _epoch++;
    final added = _game.keys.where((id) => !saved.known.contains(id)).toList();
    for (final id in added) {
      final node = _game.remove(id)!;
      (node.parent == null ? _gameTop : _game[node.parent]?.children)?.remove(
        id,
      );
    }
    _cursor = saved.cursor;
    _scene = saved.scene;
    _publish(
      saved.before.copyWith(
        tone: ScriptTone.neutral,
        transition: ScriptTransition(
          id: ++_tick,
          kind: TransitionKind.jump,
          fromFen: state.fen,
        ),
      ),
    );
  }

  /// [end] nulo: o rei do aluno chegou à casa do objetivo `casa` (sucesso).
  LessonScriptState _finishPractice(LessonScriptState base, FreeEnd? end) {
    final met = end == null || _meets(end);
    final last = _exampleIndex == _stageData.examples.length - 1;
    return base.copyWith(
      phase: ScriptPhase.praticaFim,
      speech: [
        _say(
          met
              ? 'gen.pratica.sucesso.$_goalName'
              : _example.practice!.ends[end.name] ?? 'gen.fim.${end.name}',
        ),
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
