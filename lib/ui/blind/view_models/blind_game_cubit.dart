import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/blind/blind_log_repository.dart';
import '../../../data/repositories/blind/speech_input_repository.dart';
import '../../../data/repositories/draw/draw_offer_repository.dart';
import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/voice/voice_repository.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/voice.dart';
import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/spoken_move_parser.dart';
import '../../../domain/use_cases/spoken_text.dart';
import '../../../domain/use_cases/voice_resolver.dart';

/// Em que pé está a partida às cegas.
enum BlindPhase {
  loading,

  /// Antes de começar: ouvir a posição ou olhar o tabuleiro.
  intro,

  /// A máquina pensa no lance dela.
  opponentThinking,

  /// O adversário anuncia o lance em voz alta (o microfone fica desligado).
  opponentSpeaking,

  /// A vez do jogador: falar (ou tocar no tabuleiro).
  playerTurn,

  /// O microfone está aberto.
  listening,

  /// O lance dito serve para mais de uma peça: o app pergunta qual.
  confirming,

  /// O app entendeu um lance e pergunta se é isso ("torre f5?").
  proposing,

  /// Acabou: o resultado e o tabuleiro de volta.
  finished,
}

/// Como o tabuleiro aparece.
enum BlindView {
  /// Com as peças.
  board,

  /// Só as casas (o padrão).
  empty,

  /// Sem tabuleiro nenhum.
  hidden,
}

/// O microfone.
enum MicPermission { unknown, asking, granted, denied }

/// As frases que o app fala, no idioma da tela (montadas pela tela, com os
/// textos traduzidos).
class BlindPhrases {
  const BlindPhrases({
    required this.yourTurn,
    required this.notUnderstood,
    required this.which,
    required this.position,
    required this.pawn,
    required this.won,
    required this.lost,
    required this.draw,
    required this.resigned,
    required this.confirm,
    required this.start,
    required this.moveLine,
    required this.noMoves,
    required this.illegal,
    required this.drawAgreed,
    required this.drawDeclined,
  });

  final String yourTurn;
  final String notUnderstood;

  /// "Qual: torre de a3 ou torre de h3?"
  final String Function(List<String> options) which;

  /// "Brancas: rei e1, dama d1. Pretas: rei e5."
  final String Function(String white, String black) position;

  /// O nome do peão ("peão").
  final String pawn;
  final String won;
  final String lost;
  final String draw;
  final String resigned;

  /// "Torre f5. Confirma?"
  final String Function(String move) confirm;

  /// "Posição inicial."
  final String start;

  /// "Lance 1, brancas: torre a7."
  final String Function(int number, Side side, String move) moveLine;

  /// "Nenhum lance ainda."
  final String noMoves;

  /// "Rei d3 não é possível nesta posição…"
  final String Function(String move) illegal;

  /// A máquina aceitou o empate.
  final String drawAgreed;

  /// A máquina recusou o empate.
  final String drawDeclined;
}

class BlindState {
  const BlindState({
    this.phase = BlindPhase.loading,
    this.view = BlindView.empty,
    this.position,
    this.userSide = Side.white,
    this.kind = OpponentKind.maia,
    this.level,
    this.sans = const [],
    this.lastUser,
    this.lastOpponent,
    this.options = const [],
    this.heard,
    this.notUnderstood = false,
    this.end,
    this.mic = MicPermission.unknown,
    this.offlineMissing = false,
    this.showMoves = true,
    this.lastMove,
    this.proposal,
    this.tooShort = false,
    this.levels = const [],
    this.processing = false,
    this.recorded = Duration.zero,
    this.illegal,
    this.illegalShown,
    this.selected,
    this.typing = false,
    this.drawDeclines = 0,
    this.offeringDraw = false,
    this.white,
    this.black,
    this.running,
  });

  final BlindPhase phase;
  final BlindView view;
  final Position? position;
  final Side userSide;
  final OpponentKind kind;

  /// O nível do Maia.
  final int? level;

  /// Os lances da partida, em notação algébrica (em inglês).
  final List<String> sans;
  final String? lastUser;
  final String? lastOpponent;
  final Move? lastMove;

  /// As peças possíveis quando o lance dito serviu para mais de uma.
  final List<SanMove> options;

  /// O lance que o app entendeu, esperando o "sim".
  final SanMove? proposal;

  /// O último toque no microfone foi rápido demais: é para segurar.
  final bool tooShort;

  /// O volume da voz nos últimos instantes da gravação, de 0 a 1 (as ondas).
  final List<double> levels;

  /// Soltou o botão: esperando o reconhecedor entender o que foi dito.
  final bool processing;

  /// Quanto durou a última gravação (o áudio acima do lance entendido).
  final Duration recorded;

  /// O lance entendido, mas impossível nesta posição, esperando o "sim"
  /// (em notação, como `Kd3`).
  final String? illegal;

  /// O lance impossível que o jogador confirmou: o recado fica à vista até
  /// ele falar de novo.
  final String? illegalShown;

  /// A casa de origem tocada no tabuleiro só com as casas.
  final Square? selected;

  /// O jogador está digitando o lance (no lugar do microfone).
  final bool typing;

  /// Quantas propostas de empate a máquina recusou (a tela avisa a cada uma).
  final int drawDeclines;

  /// A máquina pensando na proposta de empate.
  final bool offeringDraw;

  /// O tempo que resta a cada lado. Nulos: sem relógio.
  final Duration? white;
  final Duration? black;

  /// De quem é o relógio que está correndo.
  final Side? running;

  bool get hasClock => white != null && black != null;

  Duration? timeOf(Side side) => side == Side.white ? white : black;

  /// O que o reconhecedor ouviu por último.
  final String? heard;

  /// O último pedido não foi entendido.
  final bool notUnderstood;
  final GameEnd? end;
  final MicPermission mic;

  /// O idioma não tem reconhecimento sem internet no aparelho.
  final bool offlineMissing;

  /// Os últimos lances em texto, embaixo (dá para esconder).
  final bool showMoves;

  bool get ready => phase != BlindPhase.loading;

  /// O jogador pode falar agora.
  bool get canListen =>
      (phase == BlindPhase.playerTurn ||
          phase == BlindPhase.confirming ||
          phase == BlindPhase.proposing) &&
      mic != MicPermission.denied;

  /// A partida já começou (passou da entrada).
  bool get started => phase != BlindPhase.loading && phase != BlindPhase.intro;

  /// Quem venceu, do ponto de vista do jogador: verdadeiro se ele, falso se
  /// a máquina, nulo no empate.
  bool? get userWon {
    final winner = end?.winner;
    return winner == null ? null : winner == userSide;
  }

  BlindState copyWith({
    BlindPhase? phase,
    BlindView? view,
    Position? position,
    Side? userSide,
    OpponentKind? kind,
    int? level,
    List<String>? sans,
    String? lastUser,
    String? lastOpponent,
    Move? lastMove,
    List<SanMove>? options,
    String? Function()? heard,
    bool? notUnderstood,
    GameEnd? end,
    MicPermission? mic,
    bool? offlineMissing,
    bool? showMoves,
    SanMove? Function()? proposal,
    bool? tooShort,
    List<double>? levels,
    bool? processing,
    Duration? recorded,
    String? Function()? illegal,
    String? Function()? illegalShown,
    Square? Function()? selected,
    bool? typing,
    int? drawDeclines,
    bool? offeringDraw,
    Duration? white,
    Duration? black,
    Side? Function()? running,
  }) => BlindState(
    phase: phase ?? this.phase,
    view: view ?? this.view,
    position: position ?? this.position,
    userSide: userSide ?? this.userSide,
    kind: kind ?? this.kind,
    level: level ?? this.level,
    sans: sans ?? this.sans,
    lastUser: lastUser ?? this.lastUser,
    lastOpponent: lastOpponent ?? this.lastOpponent,
    lastMove: lastMove ?? this.lastMove,
    options: options ?? this.options,
    heard: heard == null ? this.heard : heard(),
    notUnderstood: notUnderstood ?? this.notUnderstood,
    end: end ?? this.end,
    mic: mic ?? this.mic,
    offlineMissing: offlineMissing ?? this.offlineMissing,
    showMoves: showMoves ?? this.showMoves,
    proposal: proposal == null ? this.proposal : proposal(),
    tooShort: tooShort ?? this.tooShort,
    levels: levels ?? this.levels,
    processing: processing ?? this.processing,
    recorded: recorded ?? this.recorded,
    illegal: illegal == null ? this.illegal : illegal(),
    illegalShown: illegalShown == null ? this.illegalShown : illegalShown(),
    selected: selected == null ? this.selected : selected(),
    typing: typing ?? this.typing,
    drawDeclines: drawDeclines ?? this.drawDeclines,
    offeringDraw: offeringDraw ?? this.offeringDraw,
    white: white ?? this.white,
    black: black ?? this.black,
    running: running == null ? this.running : running(),
  );
}

/// Jogar um final às cegas contra a máquina, falando os lances (spike da
/// T40). O adversário anuncia o lance dele em voz alta; o jogador fala o
/// seu, que o app entende sem IA ([SpokenMoveParser]). Cada tentativa vai
/// para o registro de medições.
class BlindGameCubit extends Cubit<BlindState> {
  BlindGameCubit({
    required this._opponent,
    required this._voice,
    required this._input,
    required this._log,
    required this._now,
    this._draws,
    this._progress,
    this.speechTimeout = const Duration(seconds: 12),
    this.thinkTime = const Duration(milliseconds: 800),
    this.releaseWait = const Duration(seconds: 3),
    this.restartDelay = const Duration(milliseconds: 250),
    this.tick = const Duration(milliseconds: 200),
  }) : super(const BlindState());

  final OpponentRepository _opponent;
  final VoiceRepository _voice;
  final SpeechInputRepository _input;
  final BlindLogRepository _log;
  final Now _now;
  final DrawOfferRepository? _draws;

  // Os desafios da Jornada jogados às cegas ficam no histórico, como os
  // outros: é assim que o desafio conta como cumprido.
  final ProgressRepository? _progress;
  String? _challengeId;
  String? _positionId;
  PositionGoal _goal = PositionGoal.win;
  String? _startFen;

  /// O máximo que se espera a voz terminar de falar.
  final Duration speechTimeout;
  final Duration thinkTime;

  /// Depois de soltar o botão, quanto se espera o resultado final. No
  /// reconhecedor do aparelho, ele chega depois do aviso de fim.
  final Duration releaseWait;

  /// A pausa antes de voltar a escutar quando o reconhecedor para sozinho.
  final Duration restartDelay;

  /// De quanto em quanto o relógio é conferido (e a tela, atualizada).
  final Duration tick;

  /// Quantas vezes ele volta a escutar num mesmo aperto.
  static const maxRestarts = 30;

  late BlindPhrases _phrases;
  String _language = 'pt-BR';
  ResolvedVoice? _speaker;
  final _history = <Position>[];
  final _ucis = <String>[];
  StreamSubscription<SpeechInputEvent>? _listening;
  // O reconhecedor quebra uma fala longa em pedaços (para no silêncio e
  // volta a escutar): os pedaços já fechados e as alternativas do atual.
  final _segments = <String>[];
  List<String> _current = const [];

  /// O que foi dito na gravação inteira, para entender: os pedaços juntos
  /// (com cada alternativa do último) e, depois, cada pedaço sozinho.
  List<String> get _heard {
    final out = <String>{
      for (final alternative in _current.isEmpty ? const [''] : _current)
        [..._segments, alternative].join(' ').trim(),
      ..._current,
      ..._segments.reversed,
    }..remove('');
    return out.toList();
  }

  DateTime? _released;
  bool _onDevice = true;

  // O dedo está no botão do microfone.
  bool _holding = false;
  int _restarts = 0;
  Completer<void>? _done;
  DateTime? _startedAt;

  // O relógio: a configuração (nula sem relógio), o estado e o tique.
  ClockConfig? _clockConfig;
  ClockState? _clock;
  Timer? _ticker;
  BlindPhase _beforeListening = BlindPhase.playerTurn;

  Future<void> load({
    required String fen,
    required Side userSide,
    required OpponentKind kind,
    int? level,
    required String language,
    required BlindPhrases phrases,
    ClockConfig? clock,
    BlindView? view,
    String? challengeId,
    String? positionId,
    PositionGoal goal = PositionGoal.win,
  }) async {
    _phrases = phrases;
    _challengeId = challengeId;
    _positionId = positionId;
    _goal = goal;
    _startFen = fen;
    _clockConfig = clock;
    _language = language;
    final position = GameRules.fromFen(fen);
    if (position == null) return;
    _speaker = await _teacherVoice();
    final mic = await _input.hasPermission()
        ? MicPermission.granted
        : MicPermission.unknown;
    if (isClosed) return;
    _history.add(position);
    emit(
      state.copyWith(
        phase: BlindPhase.intro,
        position: position,
        userSide: userSide,
        kind: kind,
        level: level,
        mic: mic,
        white: clock?.white.initial,
        black: clock?.black.initial,
        view: view,
      ),
    );
  }

  /// "Começar": a partida sai da entrada.
  Future<void> start() async {
    if (state.phase != BlindPhase.intro) return;
    await _voice.stop();
    final config = _clockConfig;
    if (config != null) {
      _clock = ClockEngine.start(
        config,
        turn: state.position!.turn,
        now: _now(),
      );
      emit(state.copyWith(running: () => state.position!.turn));
      _ticker = Timer.periodic(tick, (_) => _tickClock());
    }
    if (state.position!.turn == state.userSide) {
      emit(state.copyWith(phase: BlindPhase.playerTurn));
      await _say(_phrases.yourTurn);
    } else {
      await _opponentTurn();
    }
  }

  /// Lê onde está cada peça agora.
  Future<void> narratePosition() => _say(_describe(state.position!));

  /// Conta a partida desde o começo: a posição inicial e cada lance.
  Future<void> narrateGame() async {
    final start = _history.first;
    final parts = [_phrases.start, _describe(start)];
    var number = start.fullmoves;
    var side = start.turn;
    for (final san in state.sans) {
      parts.add(
        _phrases.moveLine(number, side, SpokenText.san(san, _language)),
      );
      if (side == Side.black) number++;
      side = side.opposite;
    }
    if (state.sans.isEmpty) parts.add(_phrases.noMoves);
    await _say(parts.join(' '));
  }

  /// Pede ao adversário para repetir o último lance.
  Future<void> repeatOpponent() async {
    final last = state.lastOpponent;
    await _say(
      last == null ? _phrases.noMoves : SpokenText.san(last, _language),
    );
  }

  /// O botãozinho de áudio do lance proposto: lê "torre f5. Confirma?".
  Future<void> sayProposal() async {
    final san = state.proposal?.san ?? state.illegal;
    if (state.phase != BlindPhase.proposing || san == null) return;
    await _say(_phrases.confirm(SpokenText.san(san, _language)));
  }

  /// "Sim": joga o lance proposto.
  Future<void> confirm() async {
    if (state.phase != BlindPhase.proposing) return;
    final illegal = state.illegal;
    if (illegal != null) {
      // Confirmou um lance impossível: avisa e sugere ouvir a posição.
      await _record(const [], 'illegalConfirmed', _now(), san: illegal);
      await _showIllegal(illegal);
      return;
    }
    final proposal = state.proposal;
    if (proposal == null) return;
    await _record(const [], 'confirmed', _now(), san: proposal.san);
    await _playUser(proposal.move);
  }

  /// "Não": descarta o lance proposto; o jogador fala de novo.
  Future<void> reject() async {
    if (state.phase != BlindPhase.proposing) return;
    final san = state.proposal?.san ?? state.illegal;
    await _voice.stop();
    emit(
      state.copyWith(
        phase: BlindPhase.playerTurn,
        proposal: () => null,
        illegal: () => null,
      ),
    );
    await _record(const [], 'rejected', _now(), san: san);
  }

  /// A voz do modo às cegas: a do professor, a que o jogador escolheu e
  /// deixou do jeito dele (o tom também).
  Future<ResolvedVoice?> _teacherVoice() async {
    final settings = await _voice.load();
    final voices = TtsVoice.forLanguage(await _voice.voices(), _language);
    final profiles = await _voice.profiles();
    const id = 'master';
    return VoiceResolver.resolve(
      profile: profiles[id] ?? const CharacterVoiceProfile.neutral(id),
      voices: voices,
      teacherVoiceId: settings.teacherVoice,
      teacher: true,
      speed: settings.speed,
      tone: settings.teacherTone,
    );
  }

  void setView(BlindView view) => emit(state.copyWith(view: view));

  /// As medições, em JSON, para copiar para o relatório.
  Future<String> exportLog() => _log.export();

  void toggleMoves() => emit(state.copyWith(showMoves: !state.showMoves));

  /// O microfone: a tela já explicou para que serve; agora o sistema pede.
  /// Negado, fica o toque no tabuleiro.
  Future<void> requestMic() async {
    final granted = await _input.requestPermission();
    if (isClosed) return;
    emit(
      state.copyWith(
        mic: granted ? MicPermission.granted : MicPermission.denied,
        view: granted ? null : BlindView.board,
      ),
    );
    if (granted) await listen();
  }

  /// Desistiu de liberar o microfone na explicação: fica o toque.
  void declineMic() =>
      emit(state.copyWith(mic: MicPermission.denied, view: BlindView.board));

  /// Apertou o botão: grava enquanto o dedo estiver nele, como um áudio.
  /// Sem permissão ainda, a tela explica e pede.
  Future<void> listen() async {
    if (!state.canListen) return;
    if (state.mic != MicPermission.granted) {
      emit(state.copyWith(mic: MicPermission.asking));
      return;
    }
    // Quem vai falar é o jogador: a voz do app para.
    await _voice.stop();
    _holding = true;
    _restarts = 0;
    _startedAt = _now();
    _beforeListening = state.phase;
    _segments.clear();
    _current = const [];
    _released = null;
    emit(
      state.copyWith(
        phase: BlindPhase.listening,
        heard: () => null,
        notUnderstood: false,
        tooShort: false,
        levels: const [],
        illegalShown: () => null,
      ),
    );
    _debug('segurou: escutando ($_language, só no aparelho: $_onDevice)');
    await _listening?.cancel();
    _listening = _input.events.listen(_onHeard);
    await _input.listen(_language, onDevice: _onDevice);
  }

  /// Soltou o botão: o que foi dito vai para o app entender.
  Future<void> stopListening() async {
    if (state.phase != BlindPhase.listening || !_holding) return;
    _holding = false;
    _released = _now();
    _debug('soltou: esperando o resultado final (ouvido até agora: $_heard)');
    final done = _done = Completer<void>();
    final started = _startedAt;
    emit(
      state.copyWith(
        processing: true,
        recorded: started == null ? null : _released!.difference(started),
      ),
    );
    await _input.stop();
    // O reconhecedor ainda manda o resultado final depois de parar; sem ele
    // no prazo, vale o último parcial.
    await done.future.timeout(releaseWait, onTimeout: () {});
    if (isClosed) return;
    emit(state.copyWith(processing: false));
    await _handle(_heard);
  }

  /// Arrastou o dedo para fora ou o toque foi curto demais: descarta, como
  /// o áudio cancelado. [tooShort]: mostra que é para segurar.
  Future<void> cancelListening({bool tooShort = false}) async {
    if (state.phase != BlindPhase.listening) return;
    _holding = false;
    unawaited(_listening?.cancel());
    _listening = null;
    await _input.cancel();
    emit(
      state.copyWith(
        phase: _beforeListening,
        heard: () => null,
        tooShort: tooShort,
      ),
    );
  }

  void _onHeard(SpeechInputEvent event) {
    if (isClosed || state.phase != BlindPhase.listening) return;
    if (event is! SpeechLevel) _debug('evento: $event');
    switch (event) {
      case SpeechLevel(:final level):
        // As ondas: o volume de -2 a 10 dB vira 0 a 1. A gravação inteira
        // fica (até um limite), para o desenho do áudio gravado.
        final normal = ((level + 2) / 12).clamp(0.0, 1.0);
        final levels = [...state.levels, normal];
        emit(
          state.copyWith(
            levels: levels.length > 600
                ? levels.sublist(levels.length - 600)
                : levels,
          ),
        );
      case SpeechHeard(:final alternatives, :final isFinal):
        final said = [
          for (final a in alternatives)
            if (a.trim().isNotEmpty) a.trim(),
        ];
        if (said.isNotEmpty) {
          _current = said;
          emit(state.copyWith(heard: () => _heard.firstOrNull));
        }
        if (isFinal) _segmentEnded(result: true);
      case SpeechFailed(:final offlineMissing):
        if (offlineMissing && _onDevice) {
          // Sem reconhecimento no aparelho: avisa e segue com o do sistema.
          _onDevice = false;
          emit(state.copyWith(offlineMissing: true));
        }
        _segmentEnded();
      case SpeechStopped():
        _segmentEnded(stopped: true);
    }
  }

  /// O reconhecedor parou (silêncio, fim da frase, erro). Com o dedo ainda
  /// no botão, ele volta a escutar sem o jogador perceber; depois de soltar,
  /// é o fim.
  ///
  /// Depois de soltar, só o resultado final (ou um erro) encerra: o aviso de
  /// fim ([stopped]) do reconhecedor do aparelho chega antes do resultado.
  void _segmentEnded({bool result = false, bool stopped = false}) {
    if (_holding) {
      // O pedaço fechou: fica guardado, e o próximo continua a frase.
      if (_current.isNotEmpty) {
        _segments.add(_current.first);
        _current = const [];
      }
      if (_restarts++ < maxRestarts) {
        unawaited(
          Future<void>.delayed(restartDelay, () async {
            if (_holding && !isClosed) {
              await _input.listen(_language, onDevice: _onDevice);
            }
          }),
        );
      }
      return;
    }
    if (stopped) return;
    final done = _done;
    if (done != null && !done.isCompleted) done.complete();
  }

  Future<void> _handle(List<String> heard) async {
    if (state.phase != BlindPhase.listening) return;
    // Sem esperar: o cancelamento de dentro do próprio evento só termina
    // depois.
    unawaited(_listening?.cancel());
    _listening = null;
    final released = _released ?? _now();
    _debug('entender: $heard');
    final confirming = _beforeListening == BlindPhase.confirming;
    final parse = heard.isEmpty
        ? const SpokenUnknown()
        : SpokenMoveParser.parse(
            heard,
            state.position!,
            among: confirming ? state.options : null,
          );
    _debug('entendido: $parse');
    String result;
    switch (parse) {
      case SpokenMove(:final move):
        result = 'move';
        await _record(heard, result, released, san: move.san);
        // A resposta a "qual peça?" já é a confirmação.
        if (confirming) {
          await _playUser(move.move);
          return;
        }
        emit(
          state.copyWith(
            phase: BlindPhase.proposing,
            proposal: () => move,
            illegal: () => null,
            options: const [],
          ),
        );
        return;
      case SpokenAmbiguous(:final options):
        result = 'ambiguous';
        emit(state.copyWith(phase: BlindPhase.confirming, options: options));
        await _record(heard, result, released);
        await _say(
          _phrases.which([
            for (final o in options) SpokenText.san(_withOrigin(o), _language),
          ]),
        );
      case SpokenIllegal(:final san):
        // Mostra o que entendeu; confirmado, avisa que não é possível.
        result = 'illegal';
        emit(
          state.copyWith(
            phase: BlindPhase.proposing,
            proposal: () => null,
            illegal: () => san,
          ),
        );
        await _record(heard, result, released, san: san);
      case SpokenCommand(:final command):
        result = 'command';
        emit(state.copyWith(phase: _beforeListening));
        await _record(heard, result, released);
        await _command(command);
      case SpokenUnknown():
        // Só o recado ao lado do microfone, sem a voz repetir a cada vez.
        result = heard.isEmpty ? 'empty' : 'unknown';
        emit(state.copyWith(phase: _beforeListening, notUnderstood: true));
        await _record(heard, result, released);
    }
  }

  /// O lance com a casa de onde sai (`Ra3f3`, `exd5`), para a pergunta
  /// "qual?".
  static String _withOrigin(SanMove option) {
    final move = option.move;
    if (move is! NormalMove) return option.san;
    final capture = option.san.contains('x') ? 'x' : '';
    final piece = RegExp('^[KQRBN]').firstMatch(option.san)?.group(0);
    if (piece == null) return '${move.from.file.name}$capture${move.to.name}';
    return '$piece${move.from.name}$capture${move.to.name}';
  }

  /// O que acontece no microfone, no log do modo debug.
  static void _debug(String message) {
    if (kDebugMode) debugPrint('[às cegas] $message');
  }

  Future<void> _record(
    List<String> heard,
    String result,
    DateTime released, {
    String? san,
  }) => _log.add(
    BlindAttempt(
      at: _now(),
      alternatives: heard,
      result: result,
      san: san,
      latencyMs: _now().difference(released).inMilliseconds,
      onDevice: _onDevice,
    ),
  );

  Future<void> _command(BlindCommand command) async {
    switch (command) {
      case BlindCommand.repeat:
        final last = state.lastOpponent;
        await _say(
          last == null ? _phrases.yourTurn : SpokenText.san(last, _language),
        );
      case BlindCommand.position:
        await _say(_describe(state.position!));
      case BlindCommand.resign:
        await resign();
      case BlindCommand.yes when state.phase == BlindPhase.proposing:
        await confirm();
      case BlindCommand.no when state.phase == BlindPhase.proposing:
        await reject();
      // "Sim" ou "não" sem lance proposto: não há o que confirmar.
      case BlindCommand.yes || BlindCommand.no:
        emit(state.copyWith(notUnderstood: true));
        await _say(_phrases.notUnderstood);
    }
  }

  /// As peças de cada lado, em voz: rei primeiro, peões por último.
  String _describe(Position position) {
    String side(Side side) {
      final parts = <String>[];
      for (final role in const [
        Role.king,
        Role.queen,
        Role.rook,
        Role.bishop,
        Role.knight,
        Role.pawn,
      ]) {
        final squares = position.board.piecesOf(side, role).squares;
        for (final square in squares) {
          parts.add(
            role == Role.pawn
                ? '${_phrases.pawn} ${square.name}'
                : SpokenText.san(
                    '${_sanLetter[role]}${square.name}',
                    _language,
                  ),
          );
        }
      }
      return parts.join(', ');
    }

    return _phrases.position(side(Side.white), side(Side.black));
  }

  static const _sanLetter = {
    Role.king: 'K',
    Role.queen: 'Q',
    Role.rook: 'R',
    Role.bishop: 'B',
    Role.knight: 'N',
  };

  /// Troca o microfone pelo campo de digitar o lance, e de volta.
  void toggleTyping() => emit(state.copyWith(typing: !state.typing));

  /// O lance digitado (`Cf3`, `e2e4`, "cavalo f3"): joga direto; impossível,
  /// avisa; servindo para mais de uma peça, pergunta qual.
  Future<void> playTyped(String text) async {
    if (state.phase != BlindPhase.playerTurn &&
        state.phase != BlindPhase.proposing &&
        state.phase != BlindPhase.confirming) {
      return;
    }
    final parse = SpokenMoveParser.parseTyped(
      text,
      state.position!,
      language: _language,
    );
    _debug('digitou "$text": $parse');
    await _record([text], 'typed:${parse.runtimeType}', _now());
    switch (parse) {
      case SpokenMove(:final move):
        await _playUser(move.move);
      case SpokenAmbiguous(:final options):
        emit(
          state.copyWith(
            phase: BlindPhase.confirming,
            options: options,
            proposal: () => null,
            illegal: () => null,
          ),
        );
      case SpokenIllegal(:final san):
        await _showIllegal(san);
      case SpokenCommand(:final command):
        await _command(command);
      case SpokenUnknown():
        emit(state.copyWith(notUnderstood: true, heard: () => text));
    }
  }

  /// Uma casa tocada no tabuleiro só com as casas: a primeira é a origem; a
  /// segunda, o destino. Tocar a origem de novo desmarca.
  Future<void> tapSquare(Square square) async {
    if (state.phase != BlindPhase.playerTurn &&
        state.phase != BlindPhase.proposing &&
        state.phase != BlindPhase.confirming) {
      return;
    }
    final from = state.selected;
    if (from == null) {
      emit(state.copyWith(selected: () => square, illegalShown: () => null));
      return;
    }
    emit(state.copyWith(selected: () => null));
    if (from == square) return;
    final position = state.position!;
    for (final m in SpokenMoveParser.legalMoves(position)) {
      final move = m.move;
      if (move is NormalMove &&
          move.from == from &&
          move.to == square &&
          (move.promotion == null || move.promotion == Role.queen)) {
        await _record(
          ['${from.name}${square.name}'],
          'touch',
          _now(),
          san: m.san,
        );
        await _playUser(move);
        return;
      }
    }
    final piece = position.board.roleAt(from);
    final letter = piece == null || piece == Role.pawn
        ? ''
        : _sanLetter[piece]!;
    await _showIllegal('$letter${from.name}${square.name}');
  }

  /// Um lance impossível (digitado, tocado ou confirmado na voz): avisa.
  Future<void> _showIllegal(String san) async {
    emit(
      state.copyWith(
        phase: BlindPhase.playerTurn,
        illegal: () => null,
        proposal: () => null,
        illegalShown: () => san,
      ),
    );
    await _say(_phrases.illegal(SpokenText.san(san, _language)));
  }

  /// O toque no tabuleiro, como alternativa à voz.
  Future<void> playTouch(Move move) async {
    if (state.phase != BlindPhase.playerTurn &&
        state.phase != BlindPhase.confirming &&
        state.phase != BlindPhase.proposing) {
      return;
    }
    await _playUser(move);
  }

  Future<void> _playUser(Move move) async {
    final played = GameRules.play(state.position!, move);
    if (played == null) return;
    _history.add(played.position);
    _ucis.add(move.uci);
    _pressClock();
    emit(
      state.copyWith(
        position: played.position,
        sans: [...state.sans, played.san],
        lastUser: played.san,
        lastMove: move,
        options: const [],
        proposal: () => null,
        illegal: () => null,
        illegalShown: () => null,
        selected: () => null,
        notUnderstood: false,
        phase: BlindPhase.opponentThinking,
      ),
    );
    if (await _finishIfOver()) return;
    await _opponentTurn();
  }

  Future<void> _opponentTurn() async {
    emit(state.copyWith(phase: BlindPhase.opponentThinking));
    final position = state.position!;
    final move = await _opponent.pickMove(
      position,
      thinkTime: thinkTime,
      kind: state.kind,
      level: state.level,
      history: List.of(_history),
      time: _clockConfig?.of(state.userSide.opposite),
    );
    if (isClosed || move == null) return;
    final played = GameRules.play(position, move);
    if (played == null) return;
    _history.add(played.position);
    _ucis.add(move.uci);
    _pressClock();
    emit(
      state.copyWith(
        position: played.position,
        sans: [...state.sans, played.san],
        lastOpponent: played.san,
        lastMove: move,
        phase: BlindPhase.opponentSpeaking,
      ),
    );
    await _say(SpokenText.san(played.san, _language));
    if (isClosed) return;
    if (await _finishIfOver()) return;
    emit(state.copyWith(phase: BlindPhase.playerTurn));
  }

  Future<bool> _finishIfOver() async {
    final position = state.position!;
    final end = GameRules.endOf(
      position,
      repetitions: GameRules.repetitionsOf(_history.first, [
        for (final p in _history.skip(1)) p.fen,
      ]).clamp(1, 1),
    );
    if (end == null) return false;
    await _finish(end);
    return true;
  }

  /// Um lance foi jogado: o relógio passa para o outro lado.
  void _pressClock() {
    final clock = _clock;
    if (clock == null) return;
    final pressed = _clock = ClockEngine.press(clock, _now());
    emit(
      state.copyWith(
        white: pressed.white,
        black: pressed.black,
        running: () => pressed.running,
      ),
    );
  }

  /// O tique do relógio: atualiza a tela e vê se o tempo de alguém acabou.
  void _tickClock() {
    final clock = _clock;
    if (isClosed || clock == null || clock.running == null) return;
    final now = _now();
    emit(
      state.copyWith(
        white: ClockEngine.remaining(clock, Side.white, now),
        black: ClockEngine.remaining(clock, Side.black, now),
      ),
    );
    final flagged = ClockEngine.flagged(clock, now);
    if (flagged != null && state.phase != BlindPhase.finished) {
      unawaited(_input.cancel());
      unawaited(_finish(GameRules.timeoutEnd(state.position!, flagged)));
    }
  }

  /// Propõe empate: a máquina decide como na partida normal.
  Future<void> offerDraw() async {
    final draws = _draws;
    if (draws == null ||
        state.offeringDraw ||
        (state.phase != BlindPhase.playerTurn &&
            state.phase != BlindPhase.proposing &&
            state.phase != BlindPhase.confirming)) {
      return;
    }
    emit(state.copyWith(offeringDraw: true));
    final accepts = await draws.accepts(
      state.position!,
      machine: state.userSide.opposite,
      kind: state.kind,
      level: state.level,
    );
    if (isClosed) return;
    emit(state.copyWith(offeringDraw: false));
    if (accepts) {
      await _finish(const GameEnd(GameEndReason.drawAgreed));
    } else {
      emit(state.copyWith(drawDeclines: state.drawDeclines + 1));
      await _say(_phrases.drawDeclined);
    }
  }

  /// Fechou a pergunta "qual peça?" sem escolher: volta à vez do jogador.
  void cancelChoice() {
    if (state.phase != BlindPhase.confirming) return;
    emit(state.copyWith(phase: BlindPhase.playerTurn, options: const []));
  }

  /// Desiste: a máquina vence.
  Future<void> resign() async {
    if (state.phase == BlindPhase.finished) return;
    await _input.cancel();
    await _finish(
      GameEnd(GameEndReason.resign, winner: state.userSide.opposite),
    );
  }

  // O desafio da Jornada fica no histórico: cumprido se o objetivo da
  // posição foi alcançado (vencer, ou segurar o empate).
  Future<void> _recordChallenge(GameEnd end, bool? won) async {
    final progress = _progress;
    final positionId = _positionId;
    if (progress == null || positionId == null || _challengeId == null) {
      return;
    }
    await progress.addAttempt(
      Attempt(
        positionId: positionId,
        playedAt: _now(),
        outcome: won == null
            ? AttemptOutcome.draw
            : won
            ? AttemptOutcome.win
            : AttemptOutcome.loss,
        fulfilled: _goal == PositionGoal.win ? won ?? false : won != false,
        opponent: state.kind,
        opponentLevel: state.kind == OpponentKind.maia ? state.level : null,
        startFen: _startFen,
        moves: List.of(_ucis),
        userSide: state.userSide,
        endReason: end.reason,
        challengeId: _challengeId,
      ),
    );
  }

  Future<void> _finish(GameEnd end) async {
    _ticker?.cancel();
    final clock = _clock;
    if (clock != null) {
      final stopped = _clock = ClockEngine.stop(clock, _now());
      emit(
        state.copyWith(
          white: stopped.white,
          black: stopped.black,
          running: () => null,
        ),
      );
    }
    emit(
      state.copyWith(
        phase: BlindPhase.finished,
        end: end,
        view: BlindView.board,
      ),
    );
    final won = state.userWon;
    await _recordChallenge(end, won);
    await _say(
      end.reason == GameEndReason.resign
          ? _phrases.resigned
          : end.reason == GameEndReason.drawAgreed
          ? _phrases.drawAgreed
          : won == null
          ? _phrases.draw
          : won
          ? _phrases.won
          : _phrases.lost,
    );
  }

  /// Fala [text] e espera terminar (o microfone fica fechado enquanto isso).
  Future<void> _say(String text) async {
    final voice = _speaker;
    if (voice == null) return;
    final done = _voice.events
        .firstWhere((e) => e is TtsFinished)
        .timeout(speechTimeout, onTimeout: () => const TtsFinished());
    await _voice.speak(text, voice);
    await done;
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _listening?.cancel();
    await _input.cancel();
    await _voice.stop();
    return super.close();
  }
}
