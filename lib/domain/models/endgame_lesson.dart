import 'endgame_position.dart';
import 'lesson.dart';

/// Correct-answer thresholds for chapter tests, independent of point weights.
abstract final class ChapterTestScores {
  static int passed(int total) => (total * 9 + 11) ~/ 12;
  static int good(int total) => (total * 10 + 11) ~/ 12;
  static int excellent(int total) => (total * 11 + 11) ~/ 12;
  static int gradeIndex(int correct, int total) {
    if (total <= 0) return 0;
    if (correct == total) return 4;
    if (correct >= excellent(total)) return 3;
    if (correct >= good(total)) return 2;
    if (correct >= passed(total)) return 1;
    return 0;
  }
}

/// As aulas de finais do Viktor: o passo seguinte da escola. Cada aula tem a
/// lição (os mesmos passos da escola), os exercícios com estrelas, a nota
/// mínima e o passo final, que leva ao final de verdade.
class EndgameTrail {
  const EndgameTrail({required this.modules});

  static const empty = EndgameTrail(modules: []);

  final List<EndgameModule> modules;

  /// Todas as aulas, na ordem da trilha.
  List<EndgameLesson> get lessons => [
    for (final module in modules) ...module.lessons,
  ];

  EndgameLesson? lesson(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  /// A aula depois de [id] na trilha. Nula na última.
  EndgameLesson? after(String id) {
    final all = lessons;
    final index = all.indexWhere((lesson) => lesson.id == id);
    return index >= 0 && index + 1 < all.length ? all[index + 1] : null;
  }
}

/// Um módulo da trilha (`mates`, `pawns`, `rook`...). O título vem das falas.
class EndgameModule {
  const EndgameModule({required this.id, required this.lessons});

  final String id;
  final List<EndgameLesson> lessons;
}

/// Uma aula de final.
class EndgameLesson {
  const EndgameLesson({
    required this.id,
    required this.module,
    required this.lesson,
    required this.exercises,
    required this.passScore,
    required this.keyPositions,
    this.practice,
    this.references = const [],
    this.inReview = false,
    this.failed = false,
  });

  /// `rook.lucena`, `mates.bishopKnight.deletang`... Estável: o progresso é gravado
  /// por ele.
  final String id;
  final String module;

  /// A lição: os passos, como numa aula da escola (o id é o da aula).
  final Lesson lesson;
  final List<Exercise> exercises;

  /// As estrelas necessárias para liberar o passo final.
  final int passScore;

  /// As posições-base, para o botão de informações.
  final List<KeyPosition> keyPositions;

  /// O treino final: o final de verdade.
  final Practice? practice;
  final List<Reference> references;

  /// A aula ainda está em revisão (abaixo da nota A): a tela avisa o aluno.
  final bool inReview;

  /// A revisão reprovou a aula: ela será refeita (o aluno vê o aviso).
  final bool failed;

  /// Todas as estrelas dos exercícios.
  int get maxScore =>
      exercises.fold(0, (total, exercise) => total + exercise.stars);

  /// A referência do `ref` de um passo ou de uma posição-base. Nula se [ref]
  /// é nulo ou não há. Ver [Reference.resolve].
  Reference? reference(String? ref) => Reference.resolve(references, ref);

  Exercise? exercise(String id) {
    for (final exercise in exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }
}

/// Um exercício: uma posição-chave com o lance (ou os lances) da técnica.
class Exercise {
  const Exercise({
    required this.id,
    required this.stars,
    required this.fen,
    required this.goal,
    required this.line,
    this.origin = 'own',
  });

  final String id;

  /// A dificuldade, de 1 a 3: o que o acerto de primeira vale.
  final int stars;
  final String fen;
  final PositionGoal goal;

  /// As vezes do aluno, com os lances aceitos e a resposta do outro lado.
  final List<MoveTurn> line;

  /// `own` ou o id da referência de onde a posição veio.
  final String origin;

  /// O passo de lance equivalente, para as regras e a tela da aula.
  MoveStep get step => MoveStep(id: id, fen: fen, line: line);
}

/// Uma posição-base da aula, com o crédito de quem a achou.
class KeyPosition {
  const KeyPosition({required this.id, required this.fen, this.ref});

  final String id;
  final String fen;

  /// O id da referência do crédito.
  final String? ref;
}

/// O treino final da aula.
class Practice {
  const Practice({required this.fen, required this.goal, this.positionId});

  final String fen;
  final PositionGoal goal;

  /// O id no catálogo, quando o final está nele (é ele que liga a aula ao
  /// speedrun do final). Nulo: o treino abre o [fen] como posição avulsa.
  final String? positionId;
}

/// Uma referência da aula: livro, estudo, partida, tabela ou página.
class Reference {
  const Reference({required this.id, required this.kind, required this.fields});

  final String id;

  /// `book`, `study`, `game`, `tablebase`, `web` ou `player` (jogador: `name`,
  /// `initials`, `dates`, `url`).
  final String kind;

  /// Os campos do tipo (`author`, `title`, `publisher`, `year`, `url`...).
  final Map<String, String> fields;

  String? operator [](String field) => fields[field];

  String get title => switch (kind) {
    'game' => '${fields['white']} – ${fields['black']}',
    'player' => fields['name'] ?? id,
    _ => fields['title'] ?? id,
  };

  String? get url => fields['url'];

  /// As iniciais do jogador (`player`): o campo `initials` ou as primeiras
  /// letras do nome.
  String get initials {
    final given = fields['initials'];
    if (given != null && given.isNotEmpty) return given;
    final words = title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w.substring(0, 1).toUpperCase()).join();
  }

  /// Fontes de produção ficam nos dados para rastreabilidade, mas não são
  /// mostradas como referências ao aluno.
  bool get isLearnerFacing {
    final value = url;
    final uri = value == null ? null : Uri.tryParse(value);
    if (uri == null) return true;
    return !uri.host.endsWith('pgnmentor.com') &&
        !uri.path.toLowerCase().endsWith('.zip');
  }

  /// A referência que um `ref` de passo ou de posição-base aponta: `id`, ou
  /// `id#ply` quando a mesma partida aparece parada noutro lance (o ply troca
  /// o trecho da [url] depois do `#`). Nula sem [ref] ou sem a referência.
  static Reference? resolve(List<Reference> references, String? ref) {
    if (ref == null) return null;
    final hash = ref.indexOf('#');
    final id = hash < 0 ? ref : ref.substring(0, hash);
    final ply = hash < 0 ? null : ref.substring(hash + 1);
    for (final reference in references) {
      if (reference.id != id) continue;
      final url = reference.url;
      if (ply == null || url == null) return reference;
      final base = url.split('#').first;
      return Reference(
        id: reference.id,
        kind: reference.kind,
        fields: {...reference.fields, 'url': '$base#$ply'},
      );
    }
    return null;
  }
}

/// O que o aluno já fez numa aula de final.
class EndgameLessonProgress {
  const EndgameLessonProgress({
    this.lessonDone = false,
    this.approved = false,
    this.parts = const {},
    this.stars = const {},
    this.lastTestAnswers,
    this.exercise,
  });

  /// A lição inteira (todas as partes) foi concluída. Num progresso gravado
  /// antes das partes (T51), é o que diz que todas estão feitas.
  final bool lessonDone;

  /// A aula já estava aprovada antes de ganhar exercícios novos (T74): a
  /// aprovação vale mesmo com eles ainda sem resolver.
  final bool approved;

  /// As partes concluídas, pelo id.
  final Set<String> parts;

  /// As partes de [lesson] já feitas. Lição concluída no formato antigo:
  /// todas.
  Set<String> partsDone(EndgameLesson lesson) => lessonDone
      ? {for (final part in lesson.lesson.sections) part.id}
      : {
          for (final part in lesson.lesson.sections)
            if (parts.contains(part.id)) part.id,
        };

  /// As estrelas ganhas em cada exercício resolvido, pelo id dele.
  final Map<String, int> stars;

  /// Last completed chapter test. Current [stars] may belong to a retake;
  /// a missing key is unanswered, while false is an observed wrong answer.
  final Map<String, bool>? lastTestAnswers;

  Map<String, bool>? completedTestOf(EndgameLesson lesson) {
    final saved = lastTestAnswers;
    if (saved != null) return saved;
    // Only complete legacy runs can be migrated into a visible grade.
    if (lesson.exercises.isEmpty ||
        solvedOf(lesson) != lesson.exercises.length) {
      return null;
    }
    return {
      for (final exercise in lesson.exercises)
        exercise.id: stars[exercise.id] == exercise.stars,
    };
  }

  /// O exercício aberto quando o app fechou.
  final ExerciseCheckpoint? exercise;

  /// A nota: as estrelas ganhas nos exercícios que a aula tem hoje. A
  /// estrela de um exercício que saiu da aula fica gravada, mas não conta.
  int scoreOf(EndgameLesson lesson) {
    var total = 0;
    for (final exercise in lesson.exercises) {
      total += stars[exercise.id] ?? 0;
    }
    return total;
  }

  /// Quantos exercícios da aula já foram resolvidos.
  int solvedOf(EndgameLesson lesson) =>
      lesson.exercises.where((e) => stars.containsKey(e.id)).length;

  EndgameLessonProgress copyWith({
    bool? lessonDone,
    bool? approved,
    Set<String>? parts,
    Map<String, int>? stars,
    Map<String, bool>? lastTestAnswers,
    ExerciseCheckpoint? exercise,
    bool clearExercise = false,
  }) => EndgameLessonProgress(
    lessonDone: lessonDone ?? this.lessonDone,
    approved: approved ?? this.approved,
    parts: parts ?? this.parts,
    stars: stars ?? this.stars,
    lastTestAnswers: lastTestAnswers ?? this.lastTestAnswers,
    exercise: clearExercise ? null : exercise ?? this.exercise,
  );

  Map<String, dynamic> toJson() => {
    'lessonDone': lessonDone,
    if (approved) 'approved': true,
    'parts': parts.toList()..sort(),
    'stars': stars,
    'lastTestAnswers': ?lastTestAnswers,
    'exercise': ?exercise?.toJson(),
  };

  static EndgameLessonProgress fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const EndgameLessonProgress();
    return EndgameLessonProgress(
      lessonDone: json['lessonDone'] as bool? ?? false,
      approved: json['approved'] as bool? ?? false,
      parts: {
        for (final part in json['parts'] as List? ?? const [])
          if (part is String) part,
      },
      stars: {
        for (final MapEntry(:key, :value)
            in (json['stars'] as Map<String, dynamic>? ?? const {}).entries)
          if (value is int) key: value,
      },
      lastTestAnswers: json['lastTestAnswers'] is Map<String, dynamic>
          ? {
              for (final MapEntry(:key, :value)
                  in (json['lastTestAnswers'] as Map<String, dynamic>).entries)
                if (value is bool) key: value,
            }
          : null,
      exercise: ExerciseCheckpoint.fromJson(json['exercise']),
    );
  }
}

/// Onde o aluno parou num exercício: o tabuleiro, a vez e o que já custou.
class ExerciseCheckpoint {
  const ExerciseCheckpoint({
    required this.exerciseId,
    this.fen,
    this.turn = 0,
    this.mistakes = 0,
    this.hints = 0,
    this.hintTurn,
    this.open = true,
    this.startedAt,
    this.pausedAt,
    this.played = const [],
    this.wrongs = const [],
    this.firstMoveMistake = false,
  });

  final String exerciseId;

  /// Os lances jogados até agora (UCI), do aluno e do outro lado, na ordem:
  /// a lista de lances volta igual ao reabrir o exercício.
  final List<String> played;

  /// Os lances errados do aluno, como `vez:uci` (a vez é o índice, de 0).
  final List<String> wrongs;

  /// Errou o primeiro lance: o exercício não pontua mais.
  final bool firstMoveMistake;

  /// Quando o exercício abriu: o cronômetro (T60) continua daqui.
  final DateTime? startedAt;
  final DateTime? pausedAt;

  /// O tabuleiro, quando já mudou desde o começo.
  final String? fen;
  final int turn;
  final int mistakes;
  final int hints;
  final int? hintTurn;

  /// O exercício estava na tela quando o app fechou: o app reabre nele.
  final bool open;

  Map<String, dynamic> toJson() => {
    'exercise': exerciseId,
    'fen': ?fen,
    'turn': turn,
    'mistakes': mistakes,
    'hints': hints,
    'hintTurn': ?hintTurn,
    'open': open,
    'startedAt': ?startedAt?.toUtc().toIso8601String(),
    'pausedAt': ?pausedAt?.toUtc().toIso8601String(),
    if (played.isNotEmpty) 'played': played,
    if (wrongs.isNotEmpty) 'wrongs': wrongs,
    if (firstMoveMistake) 'firstMoveMistake': true,
  };

  static ExerciseCheckpoint? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final exercise = json['exercise'];
    if (exercise is! String) return null;
    return ExerciseCheckpoint(
      exerciseId: exercise,
      fen: json['fen'] as String?,
      turn: json['turn'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      hints: json['hints'] as int? ?? 0,
      hintTurn: json['hintTurn'] as int?,
      open: json['open'] as bool? ?? false,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      pausedAt: DateTime.tryParse(json['pausedAt'] as String? ?? ''),
      played: [...?(json['played'] as List?)?.whereType<String>()],
      wrongs: [...?(json['wrongs'] as List?)?.whereType<String>()],
      firstMoveMistake: json['firstMoveMistake'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseCheckpoint &&
      _sameList(other.played, played) &&
      _sameList(other.wrongs, wrongs) &&
      other.firstMoveMistake == firstMoveMistake &&
      other.exerciseId == exerciseId &&
      other.fen == fen &&
      other.turn == turn &&
      other.mistakes == mistakes &&
      other.hints == hints &&
      other.hintTurn == hintTurn &&
      other.open == open &&
      other.startedAt == startedAt &&
      other.pausedAt == pausedAt;

  @override
  int get hashCode => Object.hash(
    exerciseId,
    fen,
    turn,
    mistakes,
    hints,
    hintTurn,
    open,
    startedAt,
    pausedAt,
    Object.hashAll(played),
    Object.hashAll(wrongs),
    firstMoveMistake,
  );

  static bool _sameList(List<String> a, List<String> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);
}

/// O progresso em todas as aulas de finais.
class EndgameProgress {
  const EndgameProgress({
    this.lessons = const {},
    this.ongoing,
    this.chaptersMigrated = true,
  });

  /// O progresso já está na estrutura de capítulos da T76 (`diagonal` em
  /// `pawns.keySquares`, `means` na Parte 1, `e17` na Parte 2). Progresso novo
  /// nasce migrado; o gravado antes não traz o campo (ver
  /// `EndgameProgressMigration`).
  final bool chaptersMigrated;

  /// Por id de aula.
  final Map<String, EndgameLessonProgress> lessons;

  /// A lição aberta quando o app fechou (os passos, como na escola).
  final LessonCheckpoint? ongoing;

  /// O exercício que estava na tela quando o app fechou, com a aula dele.
  /// Nulo se não há.
  (String, ExerciseCheckpoint)? get openExercise {
    for (final MapEntry(:key, :value) in lessons.entries) {
      final exercise = value.exercise;
      if (exercise != null && exercise.open) return (key, exercise);
    }
    return null;
  }

  EndgameLessonProgress of(String lessonId) =>
      lessons[lessonId] ?? const EndgameLessonProgress();

  EndgameProgress withLesson(String lessonId, EndgameLessonProgress progress) =>
      EndgameProgress(
        lessons: {...lessons, lessonId: progress},
        ongoing: ongoing,
        chaptersMigrated: chaptersMigrated,
      );

  EndgameProgress copyWith({
    Map<String, EndgameLessonProgress>? lessons,
    LessonCheckpoint? ongoing,
    bool clearOngoing = false,
    bool? chaptersMigrated,
  }) => EndgameProgress(
    lessons: lessons ?? this.lessons,
    ongoing: clearOngoing ? null : ongoing ?? this.ongoing,
    chaptersMigrated: chaptersMigrated ?? this.chaptersMigrated,
  );

  Map<String, dynamic> toJson() => {
    'lessons': {
      for (final MapEntry(:key, :value) in lessons.entries) key: value.toJson(),
    },
    'ongoing': ?ongoing?.toJson(),
    if (chaptersMigrated) 'chapters': true,
  };

  static EndgameProgress fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const EndgameProgress();
    return EndgameProgress(
      lessons: {
        for (final MapEntry(:key, :value)
            in (json['lessons'] as Map<String, dynamic>? ?? const {}).entries)
          key: EndgameLessonProgress.fromJson(value),
      },
      ongoing: LessonCheckpoint.fromJson(json['ongoing']),
      chaptersMigrated: json['chapters'] as bool? ?? false,
    );
  }
}
