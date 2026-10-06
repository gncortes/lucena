import 'package:dartchess/dartchess.dart';

import 'game_setup.dart';
import 'journey.dart';

/// A Escola do Viktor: as aulas do iniciante, em módulos, na ordem em que se
/// aprende. As falas de cada passo ficam à parte, por idioma ([LessonTexts]).
class Course {
  const Course({required this.modules});

  final List<CourseModule> modules;

  /// Todas as aulas, na ordem da trilha.
  List<Lesson> get lessons => [for (final module in modules) ...module.lessons];

  /// A aula de id [id]. Nula se não há.
  Lesson? lesson(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  /// O módulo de uma aula.
  CourseModule? moduleOf(String lessonId) {
    for (final module in modules) {
      if (module.lessons.any((lesson) => lesson.id == lessonId)) return module;
    }
    return null;
  }
}

/// Um módulo da trilha ("As peças", "Primeiros mates"...).
class CourseModule {
  const CourseModule({required this.id, required this.lessons});

  /// `pieces`, `firstMates`... O título vem de [LessonTexts.moduleTitle].
  final String id;
  final List<Lesson> lessons;
}

/// Uma aula: uma conversa com o Viktor, passo a passo.
class Lesson {
  const Lesson({required this.id, required this.steps});

  /// `pieces.rook`, `mates.queen`... Estável entre versões: o progresso é
  /// gravado por ele.
  final String id;
  final List<LessonStep> steps;
}

/// Um passo da aula. O Viktor fala em todos; o que muda é o que o aluno faz
/// no tabuleiro.
sealed class LessonStep {
  const LessonStep({required this.id, required this.fen});

  /// Único dentro da aula; as falas são procuradas por `<aula>.<passo>`.
  final String id;

  /// A posição do tabuleiro no passo. Nula: o passo é só conversa, sem
  /// tabuleiro.
  final String? fen;

  /// O lado do aluno, que fica embaixo: o lado que joga no FEN.
  Side get side =>
      fen?.split(' ').elementAtOrNull(1) == 'b' ? Side.black : Side.white;
}

/// O Viktor explica; o tabuleiro, se há, só ilustra (setas e casas
/// marcadas). O aluno toca em "continuar".
class TalkStep extends LessonStep {
  const TalkStep({
    required super.id,
    super.fen,
    this.arrows = const [],
    this.marks = const [],
    this.view,
  });

  /// Setas, cada uma `de` → `para` (`d4`, `d8`).
  final List<(String, String)> arrows;

  /// Casas marcadas com um círculo (`e4`).
  final List<String> marks;

  /// De que lado o tabuleiro é visto. Nulo: do lado que joga no FEN. Serve
  /// para mostrar do lado do aluno uma posição em que joga o outro lado.
  final Side? view;

  @override
  Side get side => view ?? super.side;
}

/// Aprender o movimento: levar a peça às estrelas, em qualquer ordem. O
/// outro lado não joga.
class StarsStep extends LessonStep {
  const StarsStep({
    required super.id,
    required String super.fen,
    required this.stars,
  });

  /// As casas com estrela.
  final List<String> stars;

  @override
  String get fen => super.fen!;
}

/// Achar o lance certo. Cada vez do aluno aceita um ou mais lances (UCI) e
/// pode ter a resposta já combinada do outro lado.
class MoveStep extends LessonStep {
  const MoveStep({
    required super.id,
    required String super.fen,
    required this.line,
  });

  final List<MoveTurn> line;

  @override
  String get fen => super.fen!;
}

/// Uma vez do aluno num [MoveStep].
class MoveTurn {
  const MoveTurn({required this.accept, this.reply});

  /// Os lances aceitos, em UCI (`d1d7`, `e7e8q`).
  final Set<String> accept;

  /// A resposta do outro lado, em UCI. Nula: o passo acaba aqui (é a última
  /// vez) ou o aluno joga de novo.
  final String? reply;
}

/// Terminar a posição contra a máquina, sem relógio, até cumprir o objetivo.
class PlayStep extends LessonStep {
  const PlayStep({
    required super.id,
    required String super.fen,
    this.goal = PlayGoal.mate,
    this.opponent = const OpponentRef(kind: OpponentKind.stockfish),
  });

  final PlayGoal goal;

  /// Quem defende. Por padrão o Stockfish, a melhor defesa.
  final OpponentRef opponent;

  @override
  String get fen => super.fen!;
}

/// O que conta como cumprir um [PlayStep].
enum PlayGoal {
  /// Dar xeque-mate.
  mate,

  /// Promover um peão (sem afogar o rei).
  promote;

  static PlayGoal fromCode(String? code) =>
      code == 'promote' ? PlayGoal.promote : PlayGoal.mate;
}

/// As falas do Viktor num idioma: as dos passos das aulas, do tour e as de
/// incentivo. Cada chave pode ter uma fala ou uma lista para sortear.
class LessonTexts {
  const LessonTexts(this._texts);

  final Map<String, List<String>> _texts;

  static const empty = LessonTexts({});

  /// As falas de [key]; vazia se não há.
  List<String> all(String key) => _texts[key] ?? const [];

  /// A fala de [key] (a [index]-ésima, se é uma lista, dando a volta). Nula
  /// se não há.
  String? say(String key, [int index = 0]) {
    final texts = all(key);
    if (texts.isEmpty) return null;
    return texts[index % texts.length];
  }

  String moduleTitle(String moduleId) => say('module.$moduleId') ?? moduleId;

  String lessonTitle(String lessonId) => say('$lessonId.title') ?? lessonId;

  String? lessonSummary(String lessonId) => say('$lessonId.summary');

  /// O que o Viktor diz ao abrir o passo.
  String? step(String lessonId, String stepId) => say('$lessonId.$stepId');

  /// A dica depois de um erro no passo.
  String? hint(String lessonId, String stepId) => say('$lessonId.$stepId.hint');

  /// O que ele diz quando o passo é cumprido.
  String? done(String lessonId, String stepId) => say('$lessonId.$stepId.done');

  /// Junta [fallback] por baixo: chave que falta aqui vem dele.
  LessonTexts over(LessonTexts fallback) =>
      LessonTexts({...fallback._texts, ..._texts});

  /// As falas como no JSON (`{"chave": ["fala", "fala"]}`).
  Map<String, dynamic> toJson() => {..._texts};

  /// Lê o JSON `{"chave": "fala"}` ou `{"chave": ["fala", "fala"]}`.
  static LessonTexts fromJson(Map<String, dynamic> json) => LessonTexts({
    for (final MapEntry(:key, :value) in json.entries)
      if (value is String)
        key: [value]
      else if (value is List)
        key: [
          for (final text in value)
            if (text is String) text,
        ],
  });
}

/// O que o aluno já fez na escola.
class SchoolProgress {
  const SchoolProgress({this.completed = const {}, this.ongoing});

  /// As aulas concluídas.
  final Set<String> completed;

  /// A aula aberta quando o app fechou, no passo em que parou.
  final LessonCheckpoint? ongoing;

  /// Fez ao menos uma aula com o Viktor: é aluno dele.
  bool get isStudent => completed.isNotEmpty;

  SchoolProgress copyWith({
    Set<String>? completed,
    LessonCheckpoint? ongoing,
    bool clearOngoing = false,
  }) => SchoolProgress(
    completed: completed ?? this.completed,
    ongoing: clearOngoing ? null : ongoing ?? this.ongoing,
  );
}

/// Onde o aluno parou dentro de uma aula: o passo e o tabuleiro dele.
class LessonCheckpoint {
  const LessonCheckpoint({
    required this.lessonId,
    required this.step,
    this.fen,
    this.collected = const [],
    this.turn = 0,
    this.moves = const [],
    this.open = true,
  });

  final String lessonId;

  /// O índice do passo.
  final int step;

  /// O tabuleiro do passo, quando já mudou desde o começo dele.
  final String? fen;

  /// As estrelas já pegas (num [StarsStep]).
  final List<String> collected;

  /// A vez do aluno (num [MoveStep]).
  final int turn;

  /// Os lances jogados desde o começo do passo, em UCI (num [PlayStep]).
  final List<String> moves;

  /// A aula estava na tela quando o app fechou: o app reabre nela. Sair da
  /// aula pelo voltar guarda o passo, mas o app abre na tela inicial.
  final bool open;

  LessonCheckpoint copyWith({bool? open}) => LessonCheckpoint(
    lessonId: lessonId,
    step: step,
    fen: fen,
    collected: collected,
    turn: turn,
    moves: moves,
    open: open ?? this.open,
  );

  Map<String, dynamic> toJson() => {
    'lesson': lessonId,
    'step': step,
    'fen': ?fen,
    'collected': collected,
    'turn': turn,
    'moves': moves,
    'open': open,
  };

  static LessonCheckpoint? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final lesson = json['lesson'];
    final step = json['step'];
    if (lesson is! String || step is! int) return null;
    return LessonCheckpoint(
      lessonId: lesson,
      step: step,
      fen: json['fen'] as String?,
      collected: [
        for (final square in json['collected'] as List? ?? const [])
          if (square is String) square,
      ],
      turn: json['turn'] as int? ?? 0,
      moves: [
        for (final move in json['moves'] as List? ?? const [])
          if (move is String) move,
      ],
      open: json['open'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LessonCheckpoint &&
      other.lessonId == lessonId &&
      other.step == step &&
      other.fen == fen &&
      _sameList(other.collected, collected) &&
      other.turn == turn &&
      _sameList(other.moves, moves) &&
      other.open == open;

  @override
  int get hashCode => Object.hash(
    lessonId,
    step,
    fen,
    Object.hashAll(collected),
    turn,
    Object.hashAll(moves),
    open,
  );

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
