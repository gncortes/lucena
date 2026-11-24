import 'dart:math';

import '../models/lesson_script.dart';
import '../models/lesson_video.dart';
import 'game_rules.dart';
import 'wiki_markup.dart';

/// Uma posição do tabuleiro a partir de um instante: o "keyframe". Cada um
/// traz o FEN inteiro, então o tabuleiro em qualquer t é o do último
/// keyframe até t (busca binária), sem rejogar nada.
class BoardKey {
  const BoardKey({
    required this.at,
    required this.fen,
    this.move,
    this.jump = false,
  });

  final Duration at;
  final String fen;

  /// O lance que leva a [fen] (anima a peça e fica destacado).
  final String? move;

  /// Corte: sem animar a peça, esmaece.
  final bool jump;
}

/// Uma fala posicionada no tempo.
class TimedLine {
  const TimedLine({
    required this.index,
    required this.line,
    required this.start,
    required this.voiceStart,
    required this.voiceEnd,
    required this.end,
  });

  final int index;
  final VideoLine line;

  /// Começo da fala: o tabuleiro muda aqui.
  final Duration start;

  /// A voz começa depois dos lances animarem.
  final Duration voiceStart;
  final Duration voiceEnd;

  /// Fim da pausa depois da voz: começo da próxima fala.
  final Duration end;

  Duration get voiceLength => voiceEnd - voiceStart;

  /// O instante em que o Viktor diz a palavra [word] (escala as palavras
  /// do áudio para a duração desta fala: velocidade ou tempo de leitura).
  Duration wordAt(int word) {
    final words = line.words;
    if (words.isEmpty || line.voice == Duration.zero) return voiceStart;
    final w = words[word.clamp(0, words.length - 1)];
    return voiceStart + _scale(w.from);
  }

  Duration _scale(Duration d) => Duration(
    microseconds:
        (d.inMicroseconds *
                voiceLength.inMicroseconds /
                line.voice.inMicroseconds)
            .round(),
  );

  /// As palavras da fala com o instante (na linha do tempo) em que o Viktor
  /// começa e termina cada uma.
  List<VideoWord> get timedWords => [
    for (final w in line.words)
      VideoWord(
        w.start,
        w.end,
        voiceStart + _scale(w.from),
        voiceStart + _scale(w.to),
      ),
  ];

  /// A palavra sendo dita em [t] (nula fora da voz).
  int? wordIndexAt(Duration t) {
    if (t < voiceStart || t >= voiceEnd || line.words.isEmpty) return null;
    final local = t - voiceStart;
    var found = 0;
    for (var i = 0; i < line.words.length; i++) {
      if (_scale(line.words[i].from) <= local) found = i;
    }
    return found;
  }
}

/// O que a tela mostra num instante.
class VideoFrame {
  const VideoFrame({
    required this.t,
    required this.lineIndex,
    required this.fen,
    required this.caption,
    this.lastMove,
    this.animating = false,
    this.marks = const [],
    this.arrows = const [],
    this.word,
    this.words = const [],
    this.links = const [],
    this.wordTimes = const [],
    this.previousCaption,
    this.previousWords = const [],
    this.speaking = false,
    this.spoken = false,
    this.atGate = false,
  });

  final Duration t;
  final int lineIndex;
  final String fen;
  final String? lastMove;

  /// A peça do [lastMove] ainda está andando.
  final bool animating;
  final List<String> marks;
  final List<ScriptArrow> arrows;

  /// A legenda: o texto da fala em curso.
  final String caption;

  /// A palavra sendo dita (destaque na legenda).
  final int? word;

  /// As palavras da legenda (trechos de [caption]).
  final List<VideoWord> words;

  /// Os nomes marcados da legenda (links), trechos de [caption].
  final List<WikiMark> links;

  /// As mesmas palavras com o instante na linha do tempo em que cada uma é
  /// dita (para a legenda que surge com a fala).
  final List<VideoWord> wordTimes;

  /// A fala anterior: a legenda fica com a última página dela até a primeira
  /// palavra desta (enquanto o lance acontece).
  final String? previousCaption;
  final List<VideoWord> previousWords;

  /// A voz está no ar (o áudio da fala deve estar tocando).
  final bool speaking;

  /// A voz da fala já terminou (a legenda fica toda dita).
  final bool spoken;

  /// Parado no ponto de interação: espera o lance do aluno.
  final bool atGate;
}

/// Como medir cada fala.
enum VideoPace {
  /// Pelo áudio (dividido pela velocidade).
  voice,

  /// Sem som ou sem áudio: tempo de leitura do texto.
  reading,
}

/// A linha do tempo de uma sequência de falas (a principal ou um ramo). Só
/// contas: sem relógio, sem Flutter. `frameAt` é pura: buscar (seek) é só
/// chamar com outro t.
class VideoTimeline {
  VideoTimeline._(this.lines, this.keys, this.total, this.pace);

  /// Monta a linha do tempo. [startFen] é a posição antes da primeira fala
  /// (num ramo, a da pergunta).
  factory VideoTimeline.layout(
    List<VideoLine> lines, {
    VideoPace pace = VideoPace.voice,
    double rate = 1,
    String? startFen,
  }) {
    final timed = <TimedLine>[];
    final keys = <BoardKey>[];
    var t = Duration.zero;
    var fen = startFen ?? (lines.isEmpty ? '' : lines.first.board.fen);
    keys.add(BoardKey(at: t, fen: fen));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final start = t;
      final board = line.board;
      if (board.from != null) {
        keys.add(BoardKey(at: t, fen: board.from!, jump: true));
        fen = board.from!;
      }
      if (board.moves.isEmpty) {
        if (board.fen != fen) {
          keys.add(BoardKey(at: t, fen: board.fen, jump: true));
        }
      } else if (board.jump) {
        keys.add(
          BoardKey(at: t, fen: board.fen, move: board.moves.last, jump: true),
        );
      } else {
        final steps = _steps(fen, board);
        for (var k = 0; k < steps.length; k++) {
          keys.add(BoardKey(at: t, fen: steps[k].fen, move: steps[k].move));
          t += k == 0 ? moveTime : seqTime;
        }
      }
      fen = board.fen;
      final voiceStart = t;
      final voice = switch (pace) {
        VideoPace.voice when line.audio != null && line.voice > Duration.zero =>
          line.voice * (1 / rate),
        _ => readingTime(line.text),
      };
      final voiceEnd = voiceStart + voice;
      t = voiceEnd + line.pause;
      timed.add(
        TimedLine(
          index: i,
          line: line,
          start: start,
          voiceStart: voiceStart,
          voiceEnd: voiceEnd,
          end: t,
        ),
      );
    }
    return VideoTimeline._(timed, keys, t, pace);
  }

  /// Tempo de uma peça andando (o lance da fala).
  static const moveTime = Duration(milliseconds: 400);

  /// Cada lance rápido de uma sequência.
  static const seqTime = Duration(milliseconds: 300);

  /// Sem voz ou sem áudio: o tempo de ler o texto (o ritmo do
  /// `theoryReadTime`), com teto de [maxReading] (Gabriel, 23/11/2026).
  static Duration readingTime(String text) => Duration(
    milliseconds: min(
      max(2500, text.length * 65) * 3 ~/ 2,
      maxReading.inMilliseconds,
    ),
  );

  /// O teto do tempo de leitura de uma fala.
  static const maxReading = Duration(seconds: 8);

  // As posições de cada lance da fala; um lance que não se joga (posição
  // incompleta, dado errado) corta direto para o FEN da fala.
  static List<({String fen, String move})> _steps(
    String before,
    VideoBoard board,
  ) {
    final moves = board.moves;
    if (moves.length == 1) return [(fen: board.fen, move: moves.single)];
    final out = <({String fen, String move})>[];
    var position = GameRules.fromFen(before);
    for (var i = 0; i < moves.length; i++) {
      final last = i == moves.length - 1;
      final replay = position == null
          ? null
          : GameRules.replay(position, [moves[i]]);
      if (last || replay == null || replay.last == null) {
        out.add((fen: board.fen, move: moves.last));
        break;
      }
      position = replay.position;
      out.add((fen: position.fen, move: moves[i]));
    }
    return out;
  }

  final List<TimedLine> lines;
  final List<BoardKey> keys;
  final Duration total;
  final VideoPace pace;

  /// Alguma fala toca o áudio (voz ligada e arquivo presente).
  bool get hasVoice =>
      pace == VideoPace.voice && lines.any((l) => l.line.audio != null);

  Duration _clampT(Duration t) =>
      t < Duration.zero ? Duration.zero : (t > total ? total : t);

  /// A fala em curso em [t] (a última, no fim).
  int lineAt(Duration t) {
    if (lines.isEmpty) return -1;
    t = _clampT(t);
    var lo = 0, hi = lines.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (lines[mid].start <= t) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  int _keyAt(Duration t) {
    var lo = 0, hi = keys.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (keys[mid].at <= t) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// O instante em que o vídeo para no ponto de interação da fala [index].
  Duration gateTime(int index) => lines[index].voiceEnd;

  /// Os pontos de interação, em ordem: (fala, instante).
  Iterable<({int line, Duration at})> get gates sync* {
    for (final l in lines) {
      if (l.line.gate != null) yield (line: l.index, at: l.voiceEnd);
    }
  }

  /// [t] limitado pelo primeiro ponto de interação ainda sem resposta: o
  /// vídeo (e a barra) não passa dele. [resolved]: ids das falas com
  /// pergunta já respondida.
  Duration reachable(Duration t, Set<String> resolved) {
    t = _clampT(t);
    for (final g in gates) {
      if (g.at > t) break;
      if (!resolved.contains(lines[g.line].line.id)) return g.at;
    }
    return t;
  }

  /// O ponto de interação sem resposta em que [t] está parado, se houver.
  TimedLine? gateAt(Duration t, Set<String> resolved) {
    for (final g in gates) {
      final line = lines[g.line];
      if (g.at == t && !resolved.contains(line.line.id)) return line;
    }
    return null;
  }

  /// O estado da tela em [t]. Pura: o mesmo t dá o mesmo quadro.
  VideoFrame frameAt(Duration t, {Set<String> resolved = const {}}) {
    t = _clampT(t);
    final index = lineAt(t);
    final key = keys[_keyAt(t)];
    if (index < 0) {
      return VideoFrame(t: t, lineIndex: -1, fen: key.fen, caption: '');
    }
    final timed = lines[index];
    final line = timed.line;
    final marks = [
      for (final m in line.marks)
        if (m.fromWord == null || timed.wordAt(m.fromWord!) <= t) m.square,
    ];
    return VideoFrame(
      t: t,
      lineIndex: index,
      fen: key.fen,
      lastMove: key.move,
      animating: key.move != null && !key.jump && t - key.at < moveTime,
      marks: marks,
      arrows: line.arrows,
      caption: line.text,
      word: timed.wordIndexAt(t),
      words: line.words,
      links: line.links,
      wordTimes: timed.timedWords,
      previousCaption: index > 0 ? lines[index - 1].line.text : null,
      previousWords: index > 0 ? lines[index - 1].line.words : const [],
      speaking: t >= timed.voiceStart && t < timed.voiceEnd,
      spoken: t >= timed.voiceEnd,
      atGate: gateAt(t, resolved) != null,
    );
  }

  /// Onde a linha principal retoma depois da alternativa boa da pergunta da
  /// fala [index]: depois das falas que são só do lance certo.
  Duration resumeAfterAlternative(int index) {
    final gate = lines[index].line.gate;
    final next = index + 1 + (gate?.rightLines ?? 0);
    return next < lines.length ? lines[next].start : total;
  }

  /// A fala em [t] e quanto dela já passou (0 a 1): a posição que vale em
  /// qualquer ritmo (velocidade, sem som).
  ({String id, double fraction})? anchorAt(Duration t) {
    final index = lineAt(t);
    if (index < 0) return null;
    final l = lines[index];
    final span = l.end - l.start;
    final fraction = span == Duration.zero
        ? 0.0
        : ((t - l.start).inMicroseconds / span.inMicroseconds).clamp(0.0, 1.0);
    return (id: l.line.id, fraction: fraction);
  }

  /// O instante da fala [id] na fração [fraction]; nulo se a fala não existe.
  Duration? timeOf(String id, double fraction) {
    for (final l in lines) {
      if (l.line.id != id) continue;
      final span = (l.end - l.start).inMicroseconds;
      return l.start + Duration(microseconds: (span * fraction).round());
    }
    return null;
  }
}
