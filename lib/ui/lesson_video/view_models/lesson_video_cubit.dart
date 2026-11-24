// A aula em vídeo (L1, tela): a Teoria ou a Demonstração de um capítulo
// tocam como um vídeo gerado na hora (tabuleiro, marcas, legenda), com barra
// para voltar a qualquer ponto. O relógio manda (`VideoClock` + `Now`): em
// cada tique o view model calcula o quadro (`VideoTimeline.frameAt`).
//
// A voz (L4) vem do pacote do capítulo: baixado, a fala segue o áudio
// (`VideoPace.voice`) e toca junto com o relógio; sem o pacote ou com a voz
// desligada, modo leitura. O L2 trata o lance na pergunta. O L3 salva onde
// parou e os ajustes (`LessonVideoRepository`, `VideoResume`) e pausa em
// qualquer interrupção, sem nunca voltar a tocar sozinho.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_video/lesson_video_repository.dart';
import '../../../data/repositories/lesson_voice/lesson_voice_repository.dart';
import '../../../data/services/voice_audio_service.dart';
import '../../../data/repositories/lesson_video/video_interruptions_repository.dart';
import '../../../data/repositories/school/lesson_script_repository.dart';
import '../../../domain/models/lesson_script.dart';
import '../../../domain/models/lesson_video.dart';
import '../../../domain/models/lesson_video_progress.dart';
import '../../../domain/use_cases/lesson_video_converter.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/video_clock.dart';
import '../../../domain/use_cases/video_resume.dart';
import '../../../domain/use_cases/video_timeline.dart';
import '../../../domain/use_cases/video_turn.dart';
import 'lesson_video_turn_view.dart';

/// O tique periódico (nos testes, nenhum: o teste chama [LessonVideoCubit.tick]).
typedef VideoTicker = Timer? Function(
  Duration period,
  void Function(Timer) callback,
);

enum LessonVideoStatus { loading, ready, failed }

/// A voz do Viktor na aula: desligada (leitura sem aviso), tocando o pacote
/// do capítulo, ou sem o pacote ("Sem áudio." e "Baixar a voz"), baixando e
/// falhou ("Não deu para baixar a voz." e "Tentar novamente").
enum VideoVoice { off, ready, missing, downloading, failed }

class LessonVideoState {
  const LessonVideoState({
    this.status = LessonVideoStatus.loading,
    this.frame,
    this.position = Duration.zero,
    this.total = Duration.zero,
    this.reachable = Duration.zero,
    this.playing = false,
    this.waiting = false,
    this.ended = false,
    this.rate = 1,
    this.captions = true,
    this.flip = false,
    this.notice = false,
    this.chapters = const [],
    this.gates = const [],
    this.turn,
    this.voice = VideoVoice.off,
  });

  final LessonVideoStatus status;

  /// A voz do capítulo (o aviso "Sem áudio." aparece fora de [VideoVoice.off]
  /// e [VideoVoice.ready]).
  final VideoVoice voice;

  /// O que a tela mostra agora.
  final VideoFrame? frame;

  /// A agulha da etapa.
  final Duration position;
  final Duration total;

  /// Até onde a barra deixa ir (a primeira pergunta sem resposta).
  final Duration reachable;
  final bool playing;

  /// Parado na pergunta, esperando o lance (o L2 trata o lance).
  final bool waiting;

  /// Chegou ao fim da etapa: a tela troca os controles pelo rodapé.
  final bool ended;
  final double rate;

  /// A legenda (balão) aparece.
  final bool captions;

  /// O tabuleiro do exemplo atual é visto pelas pretas.
  final bool flip;

  /// "Você parou aqui. Recomeçar do início": reabriu no meio; some no play.
  final bool notice;

  /// Começo de cada exemplo e cada pergunta (marcas na barra).
  final List<Duration> chapters;
  final List<Duration> gates;

  /// A vez do aluno (L2): nulo fora da pergunta.
  final VideoTurnView? turn;

  LessonVideoState copyWith({
    LessonVideoStatus? status,
    VideoFrame? frame,
    Duration? position,
    Duration? total,
    Duration? reachable,
    bool? playing,
    bool? waiting,
    bool? ended,
    double? rate,
    bool? captions,
    bool? flip,
    bool? notice,
    VideoVoice? voice,
    List<Duration>? chapters,
    List<Duration>? gates,
    VideoTurnView? Function()? turn,
  }) => LessonVideoState(
    status: status ?? this.status,
    frame: frame ?? this.frame,
    position: position ?? this.position,
    total: total ?? this.total,
    reachable: reachable ?? this.reachable,
    playing: playing ?? this.playing,
    waiting: waiting ?? this.waiting,
    ended: ended ?? this.ended,
    rate: rate ?? this.rate,
    captions: captions ?? this.captions,
    flip: flip ?? this.flip,
    notice: notice ?? this.notice,
    chapters: chapters ?? this.chapters,
    gates: gates ?? this.gates,
    turn: turn == null ? this.turn : turn(),
    voice: voice ?? this.voice,
  );
}

class LessonVideoCubit extends Cubit<LessonVideoState> {
  LessonVideoCubit({
    required this._scripts,
    required this._videos,
    required this._interruptions,
    required this._now,
    required this.lessonId,
    required this.partId,
    required this.scriptPath,
    this.stage = 'ideia',
    this.language = 'pt',
    this._autoplay = true,
    VideoTicker? ticker,
    this._voice,
    this._audio,
    String? chapterId,
  }) : _ticker = ticker ?? Timer.periodic,
       chapterId = chapterId ?? lessonId,
       super(const LessonVideoState());

  final LessonVoiceRepository? _voice;
  final Future<VoiceAudioService> Function()? _audio;

  /// O capítulo do pacote da voz (padrão: a lição).
  final String chapterId;

  final LessonScriptRepository _scripts;
  final LessonVideoRepository _videos;
  final VideoInterruptionsRepository _interruptions;
  final Now _now;
  final VideoTicker _ticker;
  final bool _autoplay;
  final String lessonId;
  final String partId;
  final String scriptPath;

  /// A etapa que toca: `ideia` (Teoria) ou `demos` (Demonstração).
  final String stage;
  final String language;

  /// Cada quanto a tela é recalculada tocando (~30 quadros por segundo).
  static const tickPeriod = Duration(milliseconds: 33);

  /// O pulo dos botões ±10 s.
  static const skipStep = Duration(seconds: 10);

  LessonVideo? _video;
  LessonScript? _script;
  ScriptTexts? _texts;
  VideoPace _pace = VideoPace.reading;

  // ---- Voz (L4) ----------------------------------------------------------
  VoiceAudioService? _player;
  StreamSubscription<VoiceInterruption>? _audioInterrupted;
  final _files = <String, String>{};
  TimedLine? _speaking;
  bool _voiceDirty = false;
  late VideoTimeline _main;
  VideoClock _clock = const VideoClock();
  final _resolved = <String>{};
  Timer? _timer;
  StreamSubscription<VideoInterruption>? _interrupted;

  // ---- Sua vez (L2) ------------------------------------------------------
  VideoTurn? _turn;
  String? _turnLine;
  TurnOutcome? _outcome;
  VideoTimeline? _branch;
  VideoClock _branchClock = const VideoClock();

  /// O ✓ do acerto fica na tela este tempo depois que o vídeo segue.
  static const sealHold = Duration(milliseconds: 1800);
  TurnResult? _sealed;
  String? _sealedSquare;
  String? _movedTo;
  DateTime? _sealedAt;

  bool _autoplayHeld = false;

  /// Não começa sozinho (leitor de tela ligado, Vídeo 37): a tela chama
  /// antes do roteiro chegar; o aluno toca play.
  void holdAutoplay() => _autoplayHeld = true;

  Future<void> start() async {
    emit(state.copyWith(status: LessonVideoStatus.loading));
    try {
      final script = await _scripts.script(scriptPath);
      final texts = await _scripts.texts(lessonId, language);
      final settings = await _videos.settings();
      final saved = await _videos.progress(lessonId, partId, stage);
      final (voice, clips) = await _loadVoice();
      final video = LessonVideoConverter.convert(
        script,
        texts,
        language: language,
        clips: clips,
      ).stage(stage);
      if (isClosed) return;
      _script = script;
      _texts = texts;
      _video = video;
      _pace = voice == VideoVoice.ready ? VideoPace.voice : VideoPace.reading;
      if (_pace == VideoPace.voice) await _prepareAudio(video);
      if (isClosed) return;
      _main = VideoTimeline.layout(
        video.lines,
        pace: _pace,
        rate: settings.rate,
      );
      final point = VideoResume.pointFrom(_main, saved);
      _resolved
        ..clear()
        ..addAll(point.resolved);
      _clock = VideoClock(anchor: point.at);
      _interrupted ??= _interruptions.interruptions.listen((_) => pause());
      emit(
        state.copyWith(
          status: LessonVideoStatus.ready,
          voice: voice,
          rate: settings.rate,
          captions: settings.captions,
          notice: point.notice,
          total: _main.total,
          chapters: _chapterStarts(video, _main),
          gates: [for (final g in _main.gates) g.at],
        ),
      );
      // Reabrindo no meio, fica pausado com o aviso (o aluno toca play).
      if (_autoplay && !_autoplayHeld && !point.notice) {
        play();
      } else {
        tick();
      }
    } on Object catch (error, stack) {
      debugPrint('Aula em vídeo não abriu: $error\n$stack');
      if (!isClosed) emit(state.copyWith(status: LessonVideoStatus.failed));
    }
  }

  static List<Duration> _chapterStarts(LessonVideo v, VideoTimeline t) => [
    for (final c in v.chapters)
      if (c.firstLine < t.lines.length) t.lines[c.firstLine].start,
  ];

  bool get _ready => _video != null && !isClosed;

  // ---- Controles ---------------------------------------------------------

  void play() {
    if (!_ready || state.waiting) return;
    if (_branch != null) {
      // Retoma a fala do lance (pausada por interrupção ou pelo botão).
      _branchClock = _branchClock.play(_now());
      _startTicking();
      tick();
      return;
    }
    if (state.ended) _clock = const VideoClock();
    if (state.notice) emit(state.copyWith(notice: false));
    _clock = _clock.play(_now());
    _startTicking();
    tick();
  }

  /// Glossário (livro do topo ou termo da fala, Vídeo 17/E8): pausa enquanto
  /// [away] estiver aberto e, na volta, continua só se tocava.
  Future<void> pauseWhile(Future<void> Function() away) async {
    final wasPlaying = state.playing;
    pause();
    await away();
    if (wasPlaying && !isClosed) play();
  }

  void pause() {
    if (!_ready) return;
    if (_branch != null) _branchClock = _branchClock.pause(_now());
    _clock = _clock.pause(_now());
    _stopTicking();
    tick();
    _save();
  }

  void toggle() => state.playing ? pause() : play();

  /// Vai para [t] (a barra); não passa da primeira pergunta sem resposta.
  void seek(Duration t) {
    if (!_ready || _branch != null) return;
    final to = _main.reachable(t, _resolved);
    _clock = _clock.seek(to, _now());
    // Caiu no meio de um lance: a peça já aparece na casa, sem andar.
    final landed = _main.frameAt(to, resolved: _resolved);
    _stillFen = landed.animating ? landed.fen : null;
    _voiceDirty = true;
    tick();
  }

  /// Os botões ±10 s.
  void skip(Duration delta) {
    if (_ready) seek(state.position + delta);
  }

  /// "Voltar ao início" (e "Recomeçar do início" do aviso): revê a etapa
  /// desde 0:00, tocando. As perguntas respondidas continuam respondidas.
  void restart() {
    if (!_ready) return;
    _clock = const VideoClock();
    _voiceDirty = true;
    unawaited(_videos.clearProgress(lessonId, partId, stage));
    play();
  }

  void toggleCaptions() {
    emit(state.copyWith(captions: !state.captions));
    _saveSettings();
  }

  /// A próxima velocidade (depois da última, volta à primeira), mantendo a
  /// fala e a fração em que está.
  void cycleRate() {
    const rates = VideoSettings.rates;
    final i = rates.indexOf(state.rate);
    setRate(rates[(i + 1) % rates.length]);
  }

  void setRate(double rate) {
    final video = _video;
    if (video == null) return;
    final now = _now();
    final anchor = _main.anchorAt(_clock.position(now));
    final next = VideoTimeline.layout(video.lines, pace: _pace, rate: rate);
    final mapped = anchor == null
        ? Duration.zero
        : next.timeOf(anchor.id, anchor.fraction) ?? Duration.zero;
    _main = next;
    _clock = _clock.seek(_main.reachable(mapped, _resolved), now);
    _voiceDirty = true;
    emit(
      state.copyWith(
        rate: rate,
        total: next.total,
        chapters: _chapterStarts(video, next),
        gates: [for (final g in next.gates) g.at],
      ),
    );
    tick();
    _saveSettings();
  }

  // ---- Persistência ------------------------------------------------------

  void _saveSettings() => unawaited(
    _videos.saveSettings(
      VideoSettings(captions: state.captions, rate: state.rate),
    ),
  );

  /// Guarda onde está (pausa, pergunta, interrupção, saída); no fim da etapa
  /// esquece, e ela reabre em 0:00.
  void _save() {
    if (_video == null) return;
    final t = _clock.position(_now());
    if (t >= _main.total) {
      unawaited(_videos.clearProgress(lessonId, partId, stage));
      return;
    }
    final progress = VideoResume.progressAt(_main, t, _resolved);
    if (progress != null) {
      unawaited(_videos.saveProgress(lessonId, partId, stage, progress));
    }
  }

  // ---- Relógio -----------------------------------------------------------

  void _startTicking() {
    _timer ??= _ticker(tickPeriod, (_) => tick());
  }

  void _stopTicking() {
    _timer?.cancel();
    _timer = null;
  }

  /// A posição em que a barra caiu no meio de um lance (não anima).
  String? _stillFen;

  /// Recalcula o quadro na hora atual (o tique; público para os testes).
  void tick() {
    if (!_ready) return;
    if (_tickBranch()) return;
    final raw = _clock.position(_now());
    final t = _main.reachable(raw, _resolved);
    final stop =
        t < raw || _main.gateAt(t, _resolved) != null || t >= _main.total;
    if (stop && _clock.playing) {
      // Chegou à pergunta ou ao fim: para ali.
      _clock = VideoClock(anchor: t);
      _stopTicking();
      _save();
    }
    var frame = _main.frameAt(t, resolved: _resolved);
    if (_stillFen != null) {
      if (frame.animating && frame.fen == _stillFen) {
        frame = frame.still();
      } else {
        _stillFen = null;
      }
    }
    emit(
      state.copyWith(
        frame: frame,
        position: t,
        reachable: _main.reachable(_main.total, _resolved),
        playing: _clock.playing,
        waiting: frame.atGate,
        ended: t >= _main.total,
        flip: _flipAt(frame.lineIndex),
        turn: () => _turnView(t) ?? _sealView(),
      ),
    );
    _syncVoice(_main, t, playing: _clock.playing);
  }

  /// O lance do aluno na pergunta (Vídeo 26–30): julga e toca o ramo.
  void onMove(String uci) {
    if (!_ready || !state.waiting || _branch != null) return;
    final turn = _turnAt(state.position);
    if (turn == null || turn.gate.legacy) return;
    _movedTo = uci.length >= 4 ? uci.substring(2, 4) : null;
    _play(turn.judge(uci));
  }

  /// "Ver a resposta" (Vídeo 27, a partir do 2º erro).
  void reveal() {
    if (!_ready || !state.waiting || _branch != null) return;
    final outcome = _turnAt(state.position)?.reveal();
    if (outcome != null) _play(outcome);
  }

  /// A vez na pergunta em [t] (a mesma enquanto a pergunta não muda).
  VideoTurn? _turnAt(Duration t) {
    final timed = _main.gateAt(t, _resolved);
    final gate = timed?.line.gate;
    if (timed == null || gate == null) return null;
    if (_turnLine != timed.line.id) {
      _turnLine = timed.line.id;
      _turn = VideoTurn(gate);
      _outcome = null;
    }
    return _turn;
  }

  /// O ✓ logo depois do acerto ou da alternativa (Vídeo 28).
  VideoTurnView? _sealView() {
    final at = _sealedAt;
    if (_sealed == null || at == null) return null;
    if (_now().difference(at) >= sealHold) {
      _sealed = null;
      _sealedAt = null;
      return null;
    }
    return VideoTurnView(last: _sealed, rightSquare: _sealedSquare);
  }

  VideoTurnView? _turnView(Duration t) {
    final turn = _turnAt(t);
    if (turn == null) return null;
    return VideoTurnView(
      movable: turn.movable,
      canReveal: turn.canReveal,
      wrongSquare: _outcome?.wrongSquare,
      last: _outcome?.result,
      legacy: turn.gate.legacy,
    );
  }

  void _play(TurnOutcome outcome) {
    _outcome = outcome;
    final lines = outcome.branch == null
        ? null
        : _video!.branches[outcome.branch];
    if (lines == null || lines.isEmpty) {
      _afterBranch();
      return;
    }
    _branch = VideoTimeline.layout(
      lines,
      pace: _pace,
      rate: state.rate,
      startFen: state.frame?.fen,
    );
    _branchClock = const VideoClock().play(_now());
    _startTicking();
    tick();
  }

  /// Toca o ramo; falso quando não há ramo (o tique segue na linha).
  bool _tickBranch() {
    final branch = _branch;
    if (branch == null) return false;
    final t = _branchClock.position(_now());
    if (t >= branch.total) {
      _branch = null;
      _branchClock = const VideoClock();
      _afterBranch();
      return true;
    }
    emit(
      state.copyWith(
        frame: branch.frameAt(t),
        playing: _branchClock.playing,
        waiting: false,
        turn: () => VideoTurnView(
          canReveal: _turn?.canReveal ?? false,
          wrongSquare: _outcome?.wrongSquare,
          last: _outcome?.result,
          inBranch: true,
        ),
      ),
    );
    _syncVoice(branch, t, playing: _branchClock.playing);
    return true;
  }

  /// Fim do ramo: segue o vídeo (certo, alternativa, resposta) ou volta a
  /// esperar na pergunta (erro, fora).
  void _afterBranch() {
    final outcome = _outcome;
    final timed = _main.gateAt(state.position, _resolved);
    if (outcome == null || timed == null) return;
    if (!outcome.resumes) {
      _stopTicking();
      tick();
      return;
    }
    _resolved.add(timed.line.id);
    if (outcome.result != TurnResult.revealed) {
      _sealed = outcome.result;
      _sealedSquare = _movedTo;
      _sealedAt = _now();
    }
    _turn = null;
    _turnLine = null;
    _outcome = null;
    final at = outcome.skipsRightLines
        ? _main.resumeAfterAlternative(timed.index)
        : state.position;
    _clock = VideoClock(anchor: at).play(_now());
    _startTicking();
    tick();
    _save();
  }

  bool _flipAt(int lineIndex) {
    var flip = false;
    for (final c in _video!.chapters) {
      if (c.firstLine > lineIndex) break;
      flip = c.flip;
    }
    return flip;
  }

  // ---- Voz ---------------------------------------------------------------

  /// A voz ao abrir: desligada, pronta (com os tempos das falas) ou sem o
  /// pacote. Pronta sem tempos (pacote antigo) conta como sem o pacote.
  Future<(VideoVoice, Map<String, VoiceClip>)> _loadVoice() async {
    final repo = _voice;
    if (repo == null || !await repo.voiceOn()) {
      return (VideoVoice.off, const <String, VoiceClip>{});
    }
    if (await repo.state(chapterId) is! VoicePackReady) {
      return (VideoVoice.missing, const <String, VoiceClip>{});
    }
    final clips = await repo.clips(chapterId);
    return clips.isEmpty
        ? (VideoVoice.missing, clips)
        : (VideoVoice.ready, clips);
  }

  /// Os arquivos de cada fala e o tocador (criado só com a voz pronta).
  Future<void> _prepareAudio(LessonVideo video) async {
    final repo = _voice!;
    final paths = {
      for (final l in video.lines) ?l.audio,
      for (final b in video.branches.values)
        for (final l in b) ?l.audio,
    };
    for (final path in paths) {
      final file = await repo.audioFile(chapterId, path);
      if (file != null) _files[path] = file;
    }
    final make = _audio;
    if (_player == null && make != null) {
      _player = await make();
      _audioInterrupted = _player!.interruptions.listen((_) => pause());
    }
  }

  /// A voz acompanha o relógio: toca a fala de [t] do ponto certo e cala
  /// fora da fala, pausado ou na pergunta. Volume do aparelho em zero não
  /// desliga a voz (a legenda segue igual).
  void _syncVoice(VideoTimeline timeline, Duration t, {required bool playing}) {
    final audio = _player;
    if (audio == null || _pace != VideoPace.voice) return;
    TimedLine? want;
    if (playing && t < timeline.total && timeline.lines.isNotEmpty) {
      final timed = timeline.lines[timeline.lineAt(t)];
      if (timed.line.audio != null &&
          _files.containsKey(timed.line.audio) &&
          t >= timed.voiceStart &&
          t < timed.voiceEnd) {
        want = timed;
      }
    }
    if (identical(want, _speaking) && !_voiceDirty) return;
    _voiceDirty = false;
    _speaking = want;
    if (want == null) {
      unawaited(audio.pause());
    } else {
      unawaited(
        audio.play(
          _files[want.line.audio]!,
          from: (t - want.voiceStart) * state.rate,
          rate: state.rate,
        ),
      );
    }
  }

  /// "Baixar a voz" e "Tentar de novo": baixa o pacote do capítulo e, pronto,
  /// passa a aula para o ritmo da voz no mesmo ponto da fala.
  Future<void> downloadVoice() async {
    final repo = _voice;
    if (repo == null || !_ready || state.voice == VideoVoice.downloading) {
      return;
    }
    emit(state.copyWith(voice: VideoVoice.downloading));
    final result = await repo.download(chapterId);
    if (!_ready) return;
    if (result is! VoicePackReady) {
      emit(state.copyWith(voice: VideoVoice.failed));
      return;
    }
    final clips = await repo.clips(chapterId);
    if (!_ready) return;
    if (clips.isEmpty) {
      emit(state.copyWith(voice: VideoVoice.failed));
      return;
    }
    final video = LessonVideoConverter.convert(
      _script!,
      _texts!,
      language: language,
      clips: clips,
    ).stage(stage);
    await _prepareAudio(video);
    if (!_ready) return;
    final now = _now();
    final anchor = _main.anchorAt(_clock.position(now));
    _video = video;
    _pace = VideoPace.voice;
    final next = VideoTimeline.layout(
      video.lines,
      pace: _pace,
      rate: state.rate,
    );
    final mapped = anchor == null
        ? Duration.zero
        : next.timeOf(anchor.id, anchor.fraction) ?? Duration.zero;
    _main = next;
    _clock = _clock.seek(_main.reachable(mapped, _resolved), now);
    _voiceDirty = true;
    emit(
      state.copyWith(
        voice: VideoVoice.ready,
        total: next.total,
        chapters: _chapterStarts(video, next),
        gates: [for (final g in next.gates) g.at],
      ),
    );
    tick();
  }

  @override
  Future<void> close() async {
    _stopTicking();
    await _interrupted?.cancel();
    await _audioInterrupted?.cancel();
    await _player?.dispose();
    _save();
    return super.close();
  }
}
