// A aula em vídeo (L1, tela): a Teoria ou a Demonstração de um capítulo
// tocam como um vídeo gerado na hora (tabuleiro, marcas, legenda), com barra
// para voltar a qualquer ponto. O relógio manda (`VideoClock` + `Now`): em
// cada tique o view model calcula o quadro (`VideoTimeline.frameAt`).
//
// Escopo do L1: modo leitura (sem áudio; a voz entra no L4), sem resposta às
// perguntas (o vídeo para na pergunta; o L2 trata o lance) e sem persistência
// (preferências e progresso entram no L3).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/school/lesson_script_repository.dart';
import '../../../domain/models/lesson_video.dart';
import '../../../domain/models/lesson_video_progress.dart';
import '../../../domain/use_cases/lesson_video_converter.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/video_clock.dart';
import '../../../domain/use_cases/video_timeline.dart';

/// O tique periódico (nos testes, nenhum: o teste chama [LessonVideoCubit.tick]).
typedef VideoTicker = Timer? Function(
  Duration period,
  void Function(Timer) callback,
);

enum LessonVideoStatus { loading, ready, failed }

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
    this.chapters = const [],
    this.gates = const [],
  });

  final LessonVideoStatus status;

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

  /// Começo de cada exemplo e cada pergunta (marcas na barra).
  final List<Duration> chapters;
  final List<Duration> gates;

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
    List<Duration>? chapters,
    List<Duration>? gates,
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
    chapters: chapters ?? this.chapters,
    gates: gates ?? this.gates,
  );
}

class LessonVideoCubit extends Cubit<LessonVideoState> {
  LessonVideoCubit({
    required this._scripts,
    required this._now,
    required this.lessonId,
    required this.partId,
    required this.scriptPath,
    this.stage = 'ideia',
    this.language = 'pt',
    this._autoplay = true,
    VideoTicker? ticker,
  }) : _ticker = ticker ?? Timer.periodic,
       super(const LessonVideoState());

  final LessonScriptRepository _scripts;
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
  late VideoTimeline _main;
  VideoClock _clock = const VideoClock();
  final _resolved = <String>{};
  Timer? _timer;

  Future<void> start() async {
    emit(state.copyWith(status: LessonVideoStatus.loading));
    try {
      final script = await _scripts.script(scriptPath);
      final texts = await _scripts.texts(lessonId, language);
      final video = LessonVideoConverter.convert(
        script,
        texts,
        language: language,
      ).stage(stage);
      if (isClosed) return;
      _video = video;
      _main = VideoTimeline.layout(
        video.lines,
        pace: VideoPace.reading,
        rate: state.rate,
      );
      _clock = const VideoClock();
      emit(
        state.copyWith(
          status: LessonVideoStatus.ready,
          total: _main.total,
          chapters: _chapterStarts(video, _main),
          gates: [for (final g in _main.gates) g.at],
        ),
      );
      if (_autoplay) {
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
    if (state.ended) _clock = const VideoClock();
    _clock = _clock.play(_now());
    _startTicking();
    tick();
  }

  void pause() {
    if (!_ready) return;
    _clock = _clock.pause(_now());
    _stopTicking();
    tick();
  }

  void toggle() => state.playing ? pause() : play();

  /// Vai para [t] (a barra); não passa da primeira pergunta sem resposta.
  void seek(Duration t) {
    if (!_ready) return;
    _clock = _clock.seek(_main.reachable(t, _resolved), _now());
    tick();
  }

  /// Os botões ±10 s.
  void skip(Duration delta) {
    if (_ready) seek(state.position + delta);
  }

  /// "Voltar ao início": revê a etapa desde 0:00, tocando.
  void restart() {
    if (!_ready) return;
    _clock = const VideoClock();
    play();
  }

  void toggleCaptions() => emit(state.copyWith(captions: !state.captions));

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
    final next = VideoTimeline.layout(
      video.lines,
      pace: VideoPace.reading,
      rate: rate,
    );
    final mapped = anchor == null
        ? Duration.zero
        : next.timeOf(anchor.id, anchor.fraction) ?? Duration.zero;
    _main = next;
    _clock = _clock.seek(_main.reachable(mapped, _resolved), now);
    emit(
      state.copyWith(
        rate: rate,
        total: next.total,
        chapters: _chapterStarts(video, next),
        gates: [for (final g in next.gates) g.at],
      ),
    );
    tick();
  }

  // ---- Relógio -----------------------------------------------------------

  void _startTicking() {
    _timer ??= _ticker(tickPeriod, (_) => tick());
  }

  void _stopTicking() {
    _timer?.cancel();
    _timer = null;
  }

  /// Recalcula o quadro na hora atual (o tique; público para os testes).
  void tick() {
    if (!_ready) return;
    final raw = _clock.position(_now());
    final t = _main.reachable(raw, _resolved);
    final stop =
        t < raw || _main.gateAt(t, _resolved) != null || t >= _main.total;
    if (stop && _clock.playing) {
      // Chegou à pergunta ou ao fim: para ali.
      _clock = VideoClock(anchor: t);
      _stopTicking();
    }
    final frame = _main.frameAt(t, resolved: _resolved);
    emit(
      state.copyWith(
        frame: frame,
        position: t,
        reachable: _main.reachable(_main.total, _resolved),
        playing: _clock.playing,
        waiting: frame.atGate,
        ended: t >= _main.total,
        flip: _flipAt(frame.lineIndex),
      ),
    );
  }

  bool _flipAt(int lineIndex) {
    var flip = false;
    for (final c in _video!.chapters) {
      if (c.firstLine > lineIndex) break;
      flip = c.flip;
    }
    return flip;
  }

  @override
  Future<void> close() {
    _stopTicking();
    return super.close();
  }
}
