import '../use_cases/wiki_markup.dart';
import 'lesson_script.dart';

/// A aula em vídeo: as etapas de teoria (`ideia`) e demonstração (`demos`) de
/// uma parte de lição como uma sequência de falas do Viktor, cada uma com o
/// áudio, as palavras com tempo, o tabuleiro e as marcas. O tempo absoluto
/// não está aqui: sai de `VideoTimeline.layout`, que mede cada fala pelo
/// áudio (ou pelo tempo de leitura, sem som). Montada no aparelho pelo
/// `LessonVideoConverter` a partir do roteiro e das falas; o mesmo formato
/// (`formato: 1`) é lido em JSON.
class LessonVideo {
  const LessonVideo({
    required this.lessonId,
    required this.partId,
    required this.language,
    required this.chapters,
    required this.lines,
    this.branches = const {},
  });

  factory LessonVideo.fromJson(Map<String, dynamic> json) {
    final format = json['formato'];
    if (format != supportedFormat) {
      throw FormatException('formato de vídeo não suportado: $format');
    }
    return LessonVideo(
      lessonId: json['licao'] as String,
      partId: json['parte'] as String,
      language: json['idioma'] as String,
      chapters: [
        for (final c
            in (json['capitulos'] as List).cast<Map<String, dynamic>>())
          VideoChapter.fromJson(c),
      ],
      lines: VideoLine.list(json['falas']),
      branches: {
        for (final e
            in (json['ramos'] as Map<String, dynamic>? ?? const {}).entries)
          e.key: VideoLine.list(e.value),
      },
    );
  }

  static const supportedFormat = 1;

  final String lessonId;
  final String partId;
  final String language;
  final List<VideoChapter> chapters;

  /// A linha principal, na ordem.
  final List<VideoLine> lines;

  /// As falas que só tocam depois de um lance do aluno (erro, alternativa,
  /// lance fora, revelar a resposta), pelo id.
  final Map<String, List<VideoLine>> branches;

  /// Só a etapa [stage] (`ideia` ou `demos`): a barra e o tempo são da
  /// etapa. Os ramos da etapa começam pelo id dela (`<etapa>.<exemplo>…`).
  LessonVideo stage(String stage) {
    final own = [
      for (var i = 0; i < chapters.length; i++)
        if (chapters[i].stage == stage) i,
    ];
    final out = <VideoLine>[];
    final kept = <VideoChapter>[];
    for (final i in own) {
      final chapter = chapters[i];
      final end = i + 1 < chapters.length
          ? chapters[i + 1].firstLine
          : lines.length;
      kept.add(
        VideoChapter(
          id: chapter.id,
          stage: chapter.stage,
          firstLine: out.length,
          flip: chapter.flip,
        ),
      );
      out.addAll(lines.sublist(chapter.firstLine, end));
    }
    return LessonVideo(
      lessonId: lessonId,
      partId: partId,
      language: language,
      chapters: kept,
      lines: out,
      branches: {
        for (final e in branches.entries)
          if (e.key.startsWith('$stage.')) e.key: e.value,
      },
    );
  }

  /// Alguma fala tem arquivo de voz (senão o vídeo toca em modo leitura e a
  /// tela avisa que falta o áudio).
  bool get hasAudio =>
      lines.any((l) => l.audio != null) ||
      branches.values.any((b) => b.any((l) => l.audio != null));
}

/// Um exemplo do roteiro: um trecho da barra (marca na linha do tempo).
class VideoChapter {
  const VideoChapter({
    required this.id,
    required this.stage,
    required this.firstLine,
    this.flip = false,
  });

  factory VideoChapter.fromJson(Map<String, dynamic> json) => VideoChapter(
    id: json['id'] as String,
    stage: json['etapa'] as String,
    firstLine: json['fala'] as int,
    flip: json['vira'] as bool? ?? false,
  );

  final String id;

  /// `ideia` (teoria) ou `demos` (demonstração).
  final String stage;
  final int firstLine;
  final bool flip;
}

/// Uma palavra da fala: a posição no texto ([start], [end]) e quando é dita,
/// contada do começo do áudio da fala ([from], [to]).
class VideoWord {
  const VideoWord(this.start, this.end, this.from, this.to);

  factory VideoWord.fromJson(List<dynamic> json) => VideoWord(
    json[0] as int,
    json[1] as int,
    Duration(milliseconds: json[2] as int),
    Duration(milliseconds: json[3] as int),
  );

  final int start;
  final int end;
  final Duration from;
  final Duration to;
}

/// O que o tabuleiro faz quando a fala começa.
class VideoBoard {
  const VideoBoard({
    required this.fen,
    this.move,
    this.seq = const [],
    this.jump = false,
    this.from,
  });

  factory VideoBoard.fromJson(Map<String, dynamic> json) => VideoBoard(
    fen: json['fen'] as String,
    move: json['lance'] as String?,
    seq: [for (final m in json['seq'] as List? ?? const []) m as String],
    jump: json['salto'] as bool? ?? false,
    from: json['de'] as String?,
  );

  /// A posição depois da fala começar (e dos lances dela).
  final String fen;
  final String? move;

  /// Lances rápidos depois de [move].
  final List<String> seq;

  /// Corte: a posição não segue a anterior.
  final bool jump;

  /// A posição de antes de [move], quando ela não é a da fala anterior
  /// (o exemplo começa com um lance).
  final String? from;

  List<String> get moves => [?move, ...seq];
}

/// Uma casa marcada; com [fromWord], só aparece quando o Viktor diz essa
/// palavra (a casa citada na fala).
class VideoMark {
  const VideoMark(this.square, {this.fromWord});

  factory VideoMark.fromJson(Map<String, dynamic> json) =>
      VideoMark(json['casa'] as String, fromWord: json['desde'] as int?);

  final String square;
  final int? fromWord;
}

/// O áudio de uma fala já gravado (o contrato do motor de voz, por chave):
/// a duração e o tempo de cada palavra, contado do começo do arquivo.
class VoiceClip {
  const VoiceClip({required this.length, this.words = const []});

  /// `{"ms": 10920, "palavras": [{"texto": "Esta", "ini": 0, "fim": 349}]}`.
  factory VoiceClip.fromJson(Map<String, dynamic> json) => VoiceClip(
    length: Duration(milliseconds: (json['ms'] as num).round()),
    words: [
      for (final w in (json['palavras'] as List? ?? const []).cast<Map>())
        (
          text: w['texto'] as String,
          from: Duration(milliseconds: (w['ini'] as num).round()),
          to: Duration(milliseconds: (w['fim'] as num).round()),
        ),
    ],
  );

  final Duration length;
  final List<({String text, Duration from, Duration to})> words;
}

/// O que o vídeo faz depois de um lance do aluno que não é o certo.
enum GateAfter {
  /// Toca o ramo e segue a linha principal (lance alternativo bom).
  resume,

  /// Toca o ramo e volta a esperar o lance (erro, lance fora).
  retry;

  static GateAfter parse(Object? value) =>
      value == 'segue' ? GateAfter.resume : GateAfter.retry;
}

class GateExit {
  const GateExit(this.branch, this.after);

  factory GateExit.fromJson(Map<String, dynamic> json) =>
      GateExit(json['ramo'] as String, GateAfter.parse(json['depois']));

  final String branch;
  final GateAfter after;
}

/// Um ponto de interação: no fim da voz da fala, o vídeo para e espera o
/// lance do aluno.
class VideoGate {
  const VideoGate({
    required this.pieces,
    required this.right,
    this.exits = const {},
    this.outside,
    this.reveal,
    this.back,
    this.rightLines = 0,
    this.legacy = false,
  });

  factory VideoGate.fromJson(Map<String, dynamic> json) => VideoGate(
    pieces: [for (final p in json['pecas'] as List? ?? const []) p as String],
    right: [for (final m in json['certos'] as List? ?? const []) m as String],
    exits: {
      for (final e
          in (json['saidas'] as Map<String, dynamic>? ?? const {}).entries)
        e.key: GateExit.fromJson(e.value as Map<String, dynamic>),
    },
    outside: json['fora'] as String?,
    reveal: json['revela'] as String?,
    back: json['volta'] as String?,
    rightLines: json['certo'] as int? ?? 0,
    legacy: json['antigo'] as bool? ?? false,
  );

  /// As peças que o aluno pode mover (casas).
  final List<String> pieces;

  /// Os lances certos (UCI): o vídeo segue.
  final List<String> right;

  /// Lances com ramo próprio (alternativos e erros conhecidos).
  final Map<String, GateExit> exits;

  /// O ramo de qualquer outro lance (volta a esperar).
  final String? outside;

  /// O ramo de "ver a resposta" (depois segue).
  final String? reveal;

  /// A chave da fala de quando volta a esperar.
  final String? back;

  /// Quantas falas logo depois da pergunta são só do lance certo. A
  /// alternativa boa toca o ramo dela e volta à linha principal depois delas
  /// (Gabriel, 23/11/2026).
  final int rightLines;

  /// A pergunta não é de lista (juiz KPK, jogo livre ou botões de resposta):
  /// o vídeo não a julga e passa a vez ao fluxo atual da lição (fora do
  /// escopo da aula em vídeo, README do spike, risco 5).
  final bool legacy;

  /// O que fazer com o lance [uci]; nulo = certo (segue a linha principal).
  GateExit? exitFor(String uci) {
    if (right.contains(uci)) return null;
    final known = exits[uci];
    if (known != null) return known;
    final branch = outside;
    return GateExit(branch ?? '', GateAfter.retry);
  }
}

/// Uma fala do Viktor.
class VideoLine {
  const VideoLine({
    required this.id,
    required this.textKey,
    required this.text,
    required this.voice,
    required this.board,
    this.audio,
    this.words = const [],
    this.links = const [],
    this.pause = Duration.zero,
    this.marks = const [],
    this.arrows = const [],
    this.gate,
  });

  factory VideoLine.fromJson(Map<String, dynamic> json) => VideoLine(
    id: json['id'] as String,
    textKey: json['t'] as String,
    text: json['texto'] as String,
    audio: json['audio'] as String?,
    voice: Duration(milliseconds: json['ms'] as int? ?? 0),
    words: [
      for (final w in json['palavras'] as List? ?? const [])
        VideoWord.fromJson(w as List),
    ],
    links: [
      for (final l in (json['links'] as List? ?? const []).cast<List>())
        WikiMark(
          start: l[0] as int,
          end: l[1] as int,
          text: (json['texto'] as String).substring(l[0] as int, l[1] as int),
          key: l[2] as String,
        ),
    ],
    pause: Duration(milliseconds: json['depois'] as int? ?? 0),
    board: VideoBoard.fromJson(json['tabuleiro'] as Map<String, dynamic>),
    marks: [
      for (final m in json['marcas'] as List? ?? const [])
        VideoMark.fromJson(m as Map<String, dynamic>),
    ],
    arrows: [
      for (final a in (json['setas'] as List? ?? const []).cast<Map>())
        ScriptArrow(a['de'] as String, a['para'] as String, a['cor'] as String),
    ],
    gate: json['vez'] == null
        ? null
        : VideoGate.fromJson(json['vez'] as Map<String, dynamic>),
  );

  static List<VideoLine> list(Object? json) => [
    for (final l in (json as List? ?? const []).cast<Map<String, dynamic>>())
      VideoLine.fromJson(l),
  ];

  final String id;
  final String textKey;
  final String text;

  /// O arquivo de áudio (caminho no pacote do capítulo); nulo = sem áudio
  /// (toca no tempo de leitura).
  final String? audio;

  /// A duração do áudio na velocidade 1,0 (ou a estimativa, sem áudio: só
  /// serve para repartir as palavras no tempo de leitura).
  final Duration voice;
  final List<VideoWord> words;

  /// Os nomes marcados (`{{texto|chave}}`), nas posições de [text], que já
  /// vem sem a marcação.
  final List<WikiMark> links;

  /// O silêncio depois da voz.
  final Duration pause;
  final VideoBoard board;
  final List<VideoMark> marks;
  final List<ScriptArrow> arrows;
  final VideoGate? gate;
}
