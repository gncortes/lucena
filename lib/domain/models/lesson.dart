import 'package:dartchess/dartchess.dart';

import 'game_setup.dart';
import 'journey.dart';
import '../use_cases/wiki_markup.dart';

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
  const Lesson({required this.id, required this.steps, this.parts = const []});

  /// Uma aula dividida em partes curtas (T51): os passos são os das partes,
  /// em ordem.
  Lesson.parted({required this.id, required this.parts})
    : steps = [for (final part in parts) ...part.steps];

  /// `pieces.rook`, `mates.queen`... Estável entre versões: o progresso é
  /// gravado por ele.
  final String id;

  /// Todos os passos, em ordem.
  final List<LessonStep> steps;

  /// As partes. Vazia: aula no formato antigo, lida como uma parte só
  /// ([sections]).
  final List<LessonPart> parts;

  /// O id da parte única de uma aula no formato antigo.
  static const wholeId = 'main';

  /// As partes, ou a aula inteira como uma parte só.
  List<LessonPart> get sections =>
      parts.isEmpty ? [LessonPart(id: wholeId, steps: steps)] : parts;

  /// A parte de id [id]. Nula se não há.
  LessonPart? part(String id) {
    for (final part in sections) {
      if (part.id == id) return part;
    }
    return null;
  }

  /// A parte que contém o passo de índice [step] (na aula inteira) e o
  /// índice dele dentro dela. Serve para ler um progresso antigo, gravado
  /// pelo índice na aula inteira.
  (LessonPart, int)? locate(int step) {
    var start = 0;
    for (final part in sections) {
      if (step < start + part.steps.length) return (part, step - start);
      start += part.steps.length;
    }
    return null;
  }

  /// Só os passos de [part], como uma aula: é o que a tela da lição toca.
  Lesson only(LessonPart part) => Lesson(id: id, steps: part.steps);
}

/// Uma parte curta de uma aula (T51): título e resumo vêm das falas
/// (`part.<id>.title`); termina numa prática do aluno.
class LessonPart {
  const LessonPart({required this.id, required this.steps});

  final String id;
  final List<LessonStep> steps;

  /// O tempo estimado, em minutos: uns 3 de pensar, mais meio minuto por
  /// conversa, uns segundos por lance mostrado e um minuto por prática.
  int get minutes {
    var seconds = 0;
    for (final step in steps) {
      seconds += switch (step) {
        ThinkStep() => ThinkStep.typicalSeconds,
        DemoStep(:final line) => 20 + 10 * line.length,
        MoveStep() || PlayStep() => 60,
        _ => 30,
      };
    }
    return (seconds / 60).ceil();
  }
}

/// Um passo da aula. O Viktor fala em todos; o que muda é o que o aluno faz
/// no tabuleiro.
sealed class LessonStep {
  const LessonStep({
    required this.id,
    required this.fen,
    this.ref,
    this.lines = const [],
  });

  /// Único dentro da aula; as falas são procuradas por `<aula>.<passo>`.
  final String id;

  /// A posição do tabuleiro no passo. Nula: o passo é só conversa, sem
  /// tabuleiro.
  final String? fen;

  /// O id de uma referência da aula (`EndgameLesson.references`) de onde vem
  /// a posição: a partida ou o estudo que a tela abre no Lichess. Nulo nas
  /// aulas da escola.
  final String? ref;

  /// As variantes citadas nas falas do passo que o JSON da aula descreve
  /// (hoje, para marcar a linha errada).
  final List<CitedLine> lines;

  /// A variante de lances [ucis] é uma linha errada da aula.
  bool wrongLine(List<String> ucis) =>
      lines.any((line) => line.wrong && line.matches(ucis));

  /// O lado do aluno, que fica embaixo: o lado que joga no FEN.
  Side get side =>
      fen?.split(' ').elementAtOrNull(1) == 'b' ? Side.black : Side.white;
}

/// O Viktor explica; o tabuleiro, se há, só ilustra (setas e casas
/// marcadas). O aluno toca em "continuar".
class TalkStep extends LessonStep {
  const TalkStep({
    required super.id,
    super.lines,
    super.fen,
    super.ref,
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
    super.lines,
    required String super.fen,
    super.ref,
    required this.stars,
  });

  /// As casas com estrela.
  final List<String> stars;

  @override
  String get fen => super.fen!;
}

/// Ler o tabuleiro: o Viktor diz uma casa e o aluno toca nela, uma de cada
/// vez, na ordem de [targets]. Sem [coordinates], as letras e os números da
/// borda somem (o aluno já sabe achar a casa sem eles).
class TapStep extends LessonStep {
  const TapStep({
    required super.id,
    super.lines,
    required String super.fen,
    super.ref,
    required this.targets,
    this.coordinates = true,
  });

  /// As casas a tocar, em ordem (`e4`).
  final List<String> targets;
  final bool coordinates;

  @override
  String get fen => super.fen!;
}

/// Achar o lance certo. Cada vez do aluno aceita um ou mais lances (UCI) e
/// pode ter a resposta já combinada do outro lado.
class MoveStep extends LessonStep {
  const MoveStep({
    required super.id,
    super.lines,
    required String super.fen,
    super.ref,
    required this.line,
    this.mistakes = const {},
  });

  final List<MoveTurn> line;

  /// Os lances errados previstos (UCI), com a explicação e o passo a rever.
  final Map<String, StepMistake> mistakes;

  @override
  String get fen => super.fen!;
}

/// Uma variante citada numa fala, descrita no JSON da aula: os lances
/// (UCI) a partir da posição de onde ela sai e se é a linha errada.
class CitedLine {
  const CitedLine({required this.uci, this.wrong = false});

  final List<String> uci;
  final bool wrong;

  /// A variante [ucis] é esta: uma começa com a outra (a fala pode citar só
  /// o começo da linha, ou a linha inteira e mais).
  bool matches(List<String> ucis) {
    if (uci.isEmpty || ucis.isEmpty) return false;
    final length = uci.length < ucis.length ? uci.length : ucis.length;
    for (var i = 0; i < length; i++) {
      if (uci[i] != ucis[i]) return false;
    }
    return true;
  }
}

/// Um lance errado previsto num passo de lance, de jogar ou de pensar: a
/// fala que explica o erro ([say], chave das falas da aula) e o passo da
/// lição a rever ([review], id do passo; não vale no passo de pensar, em que
/// a explicação já abre). Sem [say], a fala genérica do app.
class StepMistake {
  const StepMistake({this.say, this.review});

  final String? say;
  final String? review;
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
    super.lines,
    required String super.fen,
    super.ref,
    this.goal = PlayGoal.mate,
    this.opponent = const OpponentRef(kind: OpponentKind.stockfish),
    this.mistakes = const {},
  });

  final PlayGoal goal;

  /// Os lances errados previstos (UCI), com a explicação e o passo a rever:
  /// o lance não é jogado e o Viktor explica.
  final Map<String, StepMistake> mistakes;

  /// Quem defende. Por padrão o Stockfish, a melhor defesa.
  final OpponentRef opponent;

  @override
  String get fen => super.fen!;
}

/// Pensar antes da explicação (T51): o aluno estuda a posição sozinho, o
/// tempo que quiser (um cronômetro conta para cima, T60), mexendo as peças à
/// vontade; as dicas, uma a uma, e "Ver explicação" ficam à mão desde o
/// começo.
class ThinkStep extends LessonStep {
  const ThinkStep({
    required super.id,
    super.lines,
    required String super.fen,
    super.ref,
    this.hints = 1,
    this.ask = ThinkAsk.plan,
    this.arrows = const [],
    this.marks = const [],
    this.view,
    this.accept = const {},
    this.refusals = const {},
    this.mistakes = const {},
  });

  /// O que o Viktor pede ao aluno: o melhor plano ou a sequência que ganha.
  final ThinkAsk ask;

  /// Quem joga na posição (não o lado do aluno: na posição de Philidor,
  /// jogam as pretas e o aluno pensa pelas brancas).
  Side get turn =>
      fen.split(' ').elementAtOrNull(1) == 'b' ? Side.black : Side.white;

  /// Quanto um aluno costuma pensar numa posição, para a estimativa de tempo
  /// da parte ([LessonPart.minutes]).
  static const typicalSeconds = 180;

  /// Quantas dicas o passo tem (`<passo>.hint1`...).
  final int hints;

  /// Setas e casas que aparecem com a primeira dica.
  final List<(String, String)> arrows;
  final List<String> marks;
  final Side? view;

  /// Lances que resolvem a posição estudada, além do lance principal.
  final Set<String> accept;

  /// Lances naturais que não resolvem a posição e o número da dica que
  /// explica a variante.
  final Map<String, int> refusals;

  /// Os lances errados previstos (UCI): o lance abre a explicação, que
  /// começa pela fala [StepMistake.say] (por que ele perde).
  final Map<String, StepMistake> mistakes;

  @override
  String get fen => super.fen!;

  @override
  Side get side => view ?? super.side;
}

/// O que o Viktor pede num passo de pensar.
enum ThinkAsk {
  /// Sem sequência forçada: qual é o melhor plano.
  plan,

  /// Há uma sequência que ganha (ou salva) direto: qual é.
  line;

  static ThinkAsk fromCode(String? code) =>
      code == 'line' ? ThinkAsk.line : ThinkAsk.plan;
}

/// O professor joga (T51): o app faz os lances da [line], dos dois lados,
/// um de cada vez, e o Viktor explica cada um (`<passo>.m1`...).
class DemoStep extends LessonStep {
  const DemoStep({
    required super.id,
    super.lines,
    required String super.fen,
    super.ref,
    required this.line,
    this.view,
    this.wrong = false,
  });

  final List<DemoMove> line;
  final Side? view;

  /// A demonstração mostra a linha errada (o que não fazer): a tela avisa.
  final bool wrong;

  @override
  String get fen => super.fen!;

  @override
  Side get side => view ?? super.side;
}

/// Um lance da demonstração, com as setas e casas que o acompanham.
class DemoMove {
  const DemoMove({
    required this.uci,
    this.arrows = const [],
    this.marks = const [],
  });

  final String uci;
  final List<(String, String)> arrows;
  final List<String> marks;
}

/// O que conta como cumprir um [PlayStep].
enum PlayGoal {
  /// Dar xeque-mate.
  mate,

  /// Promover um peão (sem afogar o rei).
  promote,

  /// Segurar o empate: nas aulas de defesa (T51), o aluno defende contra a
  /// máquina.
  draw;

  static PlayGoal fromCode(String? code) => switch (code) {
    'promote' => PlayGoal.promote,
    'draw' => PlayGoal.draw,
    _ => PlayGoal.mate,
  };
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

  /// A fala de [key] só com o texto visível, sem a marcação dos nomes
  /// (`{{Andersson|ulf-andersson}}`): para títulos, resumos e o que não
  /// desenha o link. Nula se não há.
  String? plain(String key, [int index = 0]) {
    final text = say(key, index);
    return text == null ? null : WikiMarkup.plain(text);
  }

  String moduleTitle(String moduleId) => plain('module.$moduleId') ?? moduleId;

  String lessonTitle(String lessonId) => plain('$lessonId.title') ?? lessonId;

  String? lessonSummary(String lessonId) => plain('$lessonId.summary');

  /// O que o Viktor diz ao abrir o passo.
  String? step(String lessonId, String stepId) => say('$lessonId.$stepId');

  /// A dica depois de um erro no passo.
  String? hint(String lessonId, String stepId) => say('$lessonId.$stepId.hint');

  /// O que ele diz quando o passo é cumprido.
  String? done(String lessonId, String stepId) => say('$lessonId.$stepId.done');

  /// A [number]-ésima dica (de 1 em diante) de um passo de pensar.
  String? thinkHint(String lessonId, String stepId, int number) =>
      say('$lessonId.$stepId.hint$number');

  /// A fala do [number]-ésimo lance (de 1 em diante) de uma demonstração.
  String? demoMove(String lessonId, String stepId, int number) =>
      say('$lessonId.$stepId.m$number');

  /// O título e o resumo de uma parte.
  String? partTitle(String lessonId, String partId) =>
      plain('$lessonId.part.$partId.title');
  String? partSummary(String lessonId, String partId) =>
      plain('$lessonId.part.$partId.summary');

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

/// The student's last answer at a decision point (move, play or think step):
/// enough to ask the repository for the same explanation again when the app
/// reopens.
class LessonAttempt {
  const LessonAttempt({
    required this.step,
    required this.id,
    required this.kind,
    required this.fen,
    required this.turn,
    required this.uci,
    required this.incorrect,
  });

  /// Index of the step where the answer was given.
  final int step;

  /// Id of that step and its kind (`move`, `play`, `think`).
  final String id;
  final String kind;

  /// Position before the answer, the student's turn number and the move.
  final String fen;
  final int turn;
  final String uci;
  final bool incorrect;

  Map<String, dynamic> toJson() => {
    'step': step,
    'id': id,
    'kind': kind,
    'fen': fen,
    'turn': turn,
    'uci': uci,
    'incorrect': incorrect,
  };

  static LessonAttempt? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final (step, id, kind, fen, turn, uci) = (
      json['step'],
      json['id'],
      json['kind'],
      json['fen'],
      json['turn'],
      json['uci'],
    );
    if (step is! int ||
        id is! String ||
        kind is! String ||
        fen is! String ||
        turn is! int ||
        uci is! String) {
      return null;
    }
    return LessonAttempt(
      step: step,
      id: id,
      kind: kind,
      fen: fen,
      turn: turn,
      uci: uci,
      incorrect: json['incorrect'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LessonAttempt &&
      other.step == step &&
      other.id == id &&
      other.kind == kind &&
      other.fen == fen &&
      other.turn == turn &&
      other.uci == uci &&
      other.incorrect == incorrect;

  @override
  int get hashCode => Object.hash(step, id, kind, fen, turn, uci, incorrect);
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
    this.part,
    this.stepId,
    this.stepStartedAt,
    this.stepPausedAt,
    this.hintsShown = 0,
    this.mistakes = 0,
    this.demoMove = 0,
    this.demoPlaying = false,
    this.reviewReturn,
    this.attempt,
    this.failed = false,
    this.reviewStep,
    this.attemptedSan,
    this.thinkMistake,
    this.solutionSeen = false,
  });

  final String lessonId;

  /// The student asked for the solution of the failed step (T65 §4): the app
  /// reopens on the "solution seen" screen.
  final bool solutionSeen;

  /// The last answer at this step (T65 §7): with it the explanation of a
  /// wrong move comes back after the app is closed.
  final LessonAttempt? attempt;

  /// The step was failed (wrong move with the 2×2 footer).
  final bool failed;

  /// The earlier step the wrong move points to ("Rever a ideia").
  final String? reviewStep;

  /// The wrong move, numbered (`1.Kd2`), in a move step and in a think step.
  final String? attemptedSan;
  final String? thinkMistake;

  /// A parte aberta (aula em partes, T51). Nula: checkpoint da aula inteira
  /// ([step] conta desde o começo da aula); numa aula de finais, a parte é
  /// achada por `Lesson.locate`.
  final String? part;

  /// Identifica o passo que abriu o cronômetro. Evita reutilizar a duração
  /// de um checkpoint antigo se a posição desse passo mudou na aula.
  final String? stepId;

  /// Quando o passo em andamento abriu: o cronômetro do passo (T60) continua
  /// daqui ao reabrir o app.
  final DateTime? stepStartedAt;

  /// Quando o app foi para o segundo plano com o passo aberto (T65): o
  /// cronômetro fica parado desde então. Nulo: o cronômetro anda.
  final DateTime? stepPausedAt;

  /// Quantas dicas do passo `think` já apareceram.
  final int hintsShown;

  /// Attempts already made at the position, including before a review detour.
  final int mistakes;

  /// Quantos lances da demonstração já foram jogados.
  final int demoMove;

  final bool demoPlaying;

  /// Exact interactive position to resume after reviewing an earlier point.
  final LessonCheckpoint? reviewReturn;

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
    part: part,
    stepId: stepId,
    stepStartedAt: stepStartedAt,
    stepPausedAt: stepPausedAt,
    hintsShown: hintsShown,
    mistakes: mistakes,
    demoMove: demoMove,
    demoPlaying: demoPlaying,
    reviewReturn: reviewReturn,
    attempt: attempt,
    failed: failed,
    reviewStep: reviewStep,
    attemptedSan: attemptedSan,
    thinkMistake: thinkMistake,
    solutionSeen: solutionSeen,
  );

  Map<String, dynamic> toJson() => {
    'lesson': lessonId,
    'step': step,
    'fen': ?fen,
    'collected': collected,
    'turn': turn,
    'moves': moves,
    'open': open,
    'part': ?part,
    'stepId': ?stepId,
    'stepStartedAt': ?stepStartedAt?.toUtc().toIso8601String(),
    'stepPausedAt': ?stepPausedAt?.toUtc().toIso8601String(),
    if (hintsShown > 0) 'hintsShown': hintsShown,
    if (mistakes > 0) 'mistakes': mistakes,
    if (demoMove > 0) 'demoMove': demoMove,
    'demoPlaying': demoPlaying,
    'reviewReturn': ?reviewReturn?.toJson(),
    'attempt': ?attempt?.toJson(),
    if (failed) 'failed': true,
    'reviewStep': ?reviewStep,
    'attemptedSan': ?attemptedSan,
    'thinkMistake': ?thinkMistake,
    if (solutionSeen) 'solutionSeen': true,
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
      part: json['part'] as String?,
      stepId: json['stepId'] as String?,
      stepStartedAt: DateTime.tryParse(json['stepStartedAt'] as String? ?? ''),
      stepPausedAt: DateTime.tryParse(json['stepPausedAt'] as String? ?? ''),
      hintsShown: json['hintsShown'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      demoMove: json['demoMove'] as int? ?? 0,
      demoPlaying: json['demoPlaying'] as bool? ?? false,
      reviewReturn: LessonCheckpoint.fromJson(json['reviewReturn']),
      attempt: LessonAttempt.fromJson(json['attempt']),
      failed: json['failed'] as bool? ?? false,
      reviewStep: json['reviewStep'] as String?,
      attemptedSan: json['attemptedSan'] as String?,
      thinkMistake: json['thinkMistake'] as String?,
      solutionSeen: json['solutionSeen'] as bool? ?? false,
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
      other.open == open &&
      other.part == part &&
      other.stepId == stepId &&
      other.stepStartedAt?.toUtc() == stepStartedAt?.toUtc() &&
      other.hintsShown == hintsShown &&
      other.mistakes == mistakes &&
      other.demoMove == demoMove &&
      other.reviewReturn == reviewReturn &&
      other.attempt == attempt &&
      other.failed == failed &&
      other.reviewStep == reviewStep &&
      other.attemptedSan == attemptedSan &&
      other.thinkMistake == thinkMistake &&
      other.solutionSeen == solutionSeen;

  @override
  int get hashCode => Object.hash(
    lessonId,
    step,
    fen,
    Object.hashAll(collected),
    turn,
    Object.hashAll(moves),
    open,
    part,
    stepId,
    stepStartedAt?.toUtc(),
    hintsShown,
    mistakes,
    demoMove,
    reviewReturn,
    Object.hash(
      attempt,
      failed,
      reviewStep,
      attemptedSan,
      thinkMistake,
      solutionSeen,
    ),
  );

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
