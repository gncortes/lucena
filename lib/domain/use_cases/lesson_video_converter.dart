import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/lesson_script.dart';
import '../models/lesson_video.dart';
import 'wiki_markup.dart';

/// Monta no aparelho a aula em vídeo de um capítulo a partir do roteiro
/// (`LessonScript`) e das falas (`ScriptTexts`): as etapas `ideia` (Teoria)
/// e `demos` (Demonstração), sem a prática. Porta em Dart do
/// `roteiro_para_video.py` do spike.
///
/// Cada fala procura o áudio gravado em [convert] (`clips`) pela chave do
/// texto ([audioKey]). Sem áudio, a fala fica sem arquivo e o vídeo a toca
/// no tempo de leitura; as palavras são repartidas pelo tamanho, para a
/// legenda surgir com a leitura.
///
/// Ids das falas: `<etapa>.<exemplo>.e.<n>` (entrada), `.p` (pergunta),
/// `.certo.<n>` (só do lance certo), `.l.<n>` (linha); ramos:
/// `.alt.<uci>`, `.err.<uci>`, `.fora`, `.revela`.
abstract final class LessonVideoConverter {
  /// As etapas que viram vídeo, na ordem.
  static const stages = ['ideia', 'demos'];

  /// A voz padrão do Viktor.
  static const defaultVoice = 'viktor';

  /// A pausa depois de cada fala: na Teoria mais longa (o `theoryVoicePause`
  /// de hoje).
  static const pauses = {
    'ideia': Duration(milliseconds: 900),
    'demos': Duration(milliseconds: 600),
  };

  /// Estimativa da duração sem áudio (só para repartir as palavras): ~14
  /// caracteres por segundo, no mínimo [minEstimate].
  static const msPerChar = 70;
  static const minEstimate = Duration(milliseconds: 1200);

  /// A chave do áudio de uma fala: `sha1(idioma \n voz \n texto)[:16]`, com o
  /// texto já sem a marcação dos nomes (o que a voz lê). Texto igual, áudio
  /// igual; texto mudou, áudio novo.
  static String audioKey(String language, String voice, String text) => sha1
      .convert(utf8.encode('$language\n$voice\n$text'))
      .toString()
      .substring(0, 16);

  /// O caminho do áudio no pacote do capítulo.
  static String audioPath(String language, String voice, String key) =>
      'audio/$language/$voice/$key.opus';

  static LessonVideo convert(
    LessonScript script,
    ScriptTexts texts, {
    required String language,
    String voice = defaultVoice,
    Map<String, VoiceClip> clips = const {},
  }) => _Converter(texts, language, voice, clips).run(script);
}

class _Converter {
  _Converter(this.texts, this.language, this.voice, this.clips);

  final ScriptTexts texts;
  final String language;
  final String voice;
  final Map<String, VoiceClip> clips;

  static const _outsideDefault = 'ini.fora';

  LessonVideo run(LessonScript script) {
    final lines = <VideoLine>[];
    final chapters = <VideoChapter>[];
    final branches = <String, List<VideoLine>>{};
    for (final stageId in LessonVideoConverter.stages) {
      for (final stage in script.stages.where((s) => s.id == stageId)) {
        for (final example in stage.examples) {
          if (example.isPractice) continue;
          _example(stageId, example, lines, chapters, branches);
        }
      }
    }
    return LessonVideo(
      lessonId: script.lessonId,
      partId: script.partId,
      language: language,
      chapters: chapters,
      lines: lines,
      branches: branches,
    );
  }

  void _example(
    String stage,
    ScriptExample example,
    List<VideoLine> lines,
    List<VideoChapter> chapters,
    Map<String, List<VideoLine>> branches,
  ) {
    final base = '$stage.${example.id}';
    chapters.add(
      VideoChapter(
        id: base,
        stage: stage,
        firstLine: lines.length,
        flip: example.flip,
      ),
    );
    lines.addAll(
      _lines('$base.e', example.entry, stage, exampleFen: example.fen),
    );
    var marks = _marksOf(lines.lastOrNull, chapterStart: chapters.last);
    final question = example.question;
    if (question != null) {
      final branchMarks = marks;
      List<VideoLine> branch(String id, List<ScriptStep> steps) =>
          branches[id] = _lines(id, steps, stage, marksBefore: branchMarks);
      final exits = <String, GateExit>{};
      for (final MapEntry(key: uci, value: steps)
          in question.alternatives.entries) {
        branch('$base.alt.$uci', steps);
        exits[uci] = GateExit('$base.alt.$uci', GateAfter.resume);
      }
      for (final MapEntry(key: uci, value: steps) in question.errors.entries) {
        branch('$base.err.$uci', steps);
        exits[uci] = GateExit('$base.err.$uci', GateAfter.retry);
      }
      final fen = example.questionFen;
      final outsideKey =
          question.outside ??
          (texts.has(_Converter._outsideDefault)
              ? _Converter._outsideDefault
              : null);
      String? outside;
      if (outsideKey != null) {
        outside = '$base.fora';
        branches[outside] = [
          _line(
            '$outside.1',
            ScriptStep(fen: fen, t: outsideKey),
            stage,
            marksBefore: marks,
          ),
        ];
      }
      branch('$base.revela', [question.reveal]);
      final right = _lines(
        '$base.certo',
        [question.rightStep],
        stage,
        marksBefore: marks,
      );
      lines.add(
        _line(
          '$base.p',
          ScriptStep(fen: fen, t: question.t),
          stage,
          marksBefore: marks,
          gate: VideoGate(
            pieces: question.pieces ?? const [],
            right: question.right,
            exits: exits,
            outside: outside,
            reveal: '$base.revela',
            back: question.back,
            rightLines: right.length,
            legacy:
                question.judge != ScriptJudge.lista ||
                question.free != null ||
                question.choices.isNotEmpty,
          ),
        ),
      );
      lines.addAll(right);
      marks = _marksOf(lines.last);
    }
    lines.addAll(_lines('$base.l', example.line, stage, marksBefore: marks));
  }

  // As casas marcadas na última fala (a marca que continua não espera a
  // palavra de novo); nada se a fala é de outro exemplo.
  static List<String> _marksOf(VideoLine? line, {VideoChapter? chapterStart}) {
    if (line == null) return const [];
    if (chapterStart != null && !line.id.startsWith('${chapterStart.id}.')) {
      return const [];
    }
    return [for (final m in line.marks) m.square];
  }

  List<VideoLine> _lines(
    String prefix,
    List<ScriptStep> steps,
    String stage, {
    List<String> marksBefore = const [],
    String? exampleFen,
  }) {
    final out = <VideoLine>[];
    var before = marksBefore;
    for (var n = 0; n < steps.length; n++) {
      final line = _line(
        '$prefix.${n + 1}',
        steps[n],
        stage,
        marksBefore: before,
        first: n == 0 && exampleFen != null,
        exampleFen: exampleFen,
      );
      before = [for (final m in line.marks) m.square];
      out.add(line);
    }
    return out;
  }

  VideoLine _line(
    String id,
    ScriptStep step,
    String stage, {
    List<String> marksBefore = const [],
    bool first = false,
    String? exampleFen,
    VideoGate? gate,
  }) {
    final marked = WikiMarkup.parse(texts.say(step.t));
    final text = marked.text;
    final key = LessonVideoConverter.audioKey(language, voice, text);
    final clip = clips[key];
    final Duration length;
    final List<VideoWord> words;
    if (clip != null) {
      length = clip.length;
      words = _wordsFromClip(text, clip);
    } else {
      length = Duration(
        milliseconds: max(
          LessonVideoConverter.minEstimate.inMilliseconds,
          text.length * LessonVideoConverter.msPerChar,
        ),
      );
      words = _estimatedWords(text, length);
    }
    final startsWithMove = first && step.move != null;
    return VideoLine(
      id: id,
      textKey: step.t,
      text: text,
      links: marked.marks,
      audio: clip == null
          ? null
          : LessonVideoConverter.audioPath(language, voice, key),
      voice: length,
      words: words,
      pause: LessonVideoConverter.pauses[stage] ?? Duration.zero,
      board: VideoBoard(
        fen: step.fen,
        move: step.move,
        seq: step.seq,
        jump: step.jump || (first && step.move == null),
        from: startsWithMove ? exampleFen : null,
      ),
      marks: [
        for (final square in step.marks)
          VideoMark(
            square,
            fromWord: marksBefore.contains(square)
                ? null
                : _wordCiting(text, words, square),
          ),
      ],
      arrows: step.arrows,
      gate: gate,
    );
  }

  static final _word = RegExp(r'\S+');
  static final _notSquare = RegExp('[^a-h1-8]');

  // As palavras repartidas pelo tamanho de cada uma.
  static List<VideoWord> _estimatedWords(String text, Duration length) {
    final found = _word.allMatches(text).toList();
    final total = found.fold(0, (sum, m) => sum + m.end - m.start);
    if (total == 0) return const [];
    final out = <VideoWord>[];
    var now = 0;
    for (var i = 0; i < found.length; i++) {
      final m = found[i];
      final last = i == found.length - 1;
      final end = last
          ? length.inMilliseconds
          : now + (length.inMilliseconds * (m.end - m.start) / total).round();
      out.add(
        VideoWord(
          m.start,
          m.end,
          Duration(milliseconds: now),
          Duration(milliseconds: end),
        ),
      );
      now = end;
    }
    return out;
  }

  // As palavras do alinhador casadas com as posições no texto; palavra que o
  // alinhador normalizou (pontuação, número) fica com a próxima do texto.
  static List<VideoWord> _wordsFromClip(String text, VoiceClip clip) {
    final out = <VideoWord>[];
    var cursor = 0;
    for (final w in clip.words) {
      final target = w.text.trim();
      var start = target.isEmpty ? -1 : text.indexOf(target, cursor);
      int end;
      if (start < 0) {
        final next = _word.firstMatch(text.substring(cursor));
        if (next == null) break;
        start = cursor + next.start;
        end = cursor + next.end;
      } else {
        end = start + target.length;
      }
      out.add(VideoWord(start, end, w.from, w.to));
      cursor = end;
    }
    return out;
  }

  // A primeira palavra que cita a casa (`e7`, `e7,`, `(e7)`).
  static int? _wordCiting(String text, List<VideoWord> words, String square) {
    for (var i = 0; i < words.length; i++) {
      final w = text
          .substring(words[i].start, words[i].end)
          .toLowerCase()
          .replaceAll(_notSquare, '');
      if (w == square) return i;
    }
    return null;
  }
}
