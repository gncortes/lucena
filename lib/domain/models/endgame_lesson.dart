import 'endgame_position.dart';
import 'lesson.dart';

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
    required this.practice,
    this.references = const [],
  });

  /// `rook.lucena`, `mates.bishopKnight.w`... Estável: o progresso é gravado
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
  final Practice practice;
  final List<Reference> references;

  /// Todas as estrelas dos exercícios.
  int get maxScore =>
      exercises.fold(0, (total, exercise) => total + exercise.stars);

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

  /// `book`, `study`, `game`, `tablebase` ou `web`.
  final String kind;

  /// Os campos do tipo (`author`, `title`, `publisher`, `year`, `url`...).
  final Map<String, String> fields;

  String? operator [](String field) => fields[field];

  String get title => switch (kind) {
    'game' => '${fields['white']} – ${fields['black']}',
    _ => fields['title'] ?? id,
  };

  String? get url => fields['url'];
}

/// O que o aluno já fez numa aula de final.
class EndgameLessonProgress {
  const EndgameLessonProgress({
    this.lessonDone = false,
    this.parts = const {},
    this.stars = const {},
    this.exercise,
  });

  /// A lição inteira (todas as partes) foi concluída. Num progresso gravado
  /// antes das partes (T51), é o que diz que todas estão feitas.
  final bool lessonDone;

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
    Set<String>? parts,
    Map<String, int>? stars,
    ExerciseCheckpoint? exercise,
    bool clearExercise = false,
  }) => EndgameLessonProgress(
    lessonDone: lessonDone ?? this.lessonDone,
    parts: parts ?? this.parts,
    stars: stars ?? this.stars,
    exercise: clearExercise ? null : exercise ?? this.exercise,
  );

  Map<String, dynamic> toJson() => {
    'lessonDone': lessonDone,
    'parts': parts.toList()..sort(),
    'stars': stars,
    'exercise': ?exercise?.toJson(),
  };

  static EndgameLessonProgress fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const EndgameLessonProgress();
    return EndgameLessonProgress(
      lessonDone: json['lessonDone'] as bool? ?? false,
      parts: {
        for (final part in json['parts'] as List? ?? const [])
          if (part is String) part,
      },
      stars: {
        for (final MapEntry(:key, :value)
            in (json['stars'] as Map<String, dynamic>? ?? const {}).entries)
          if (value is int) key: value,
      },
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
    this.open = true,
    this.startedAt,
  });

  final String exerciseId;

  /// Quando o exercício abriu: o cronômetro (T60) continua daqui.
  final DateTime? startedAt;

  /// O tabuleiro, quando já mudou desde o começo.
  final String? fen;
  final int turn;
  final int mistakes;
  final int hints;

  /// O exercício estava na tela quando o app fechou: o app reabre nele.
  final bool open;

  Map<String, dynamic> toJson() => {
    'exercise': exerciseId,
    'fen': ?fen,
    'turn': turn,
    'mistakes': mistakes,
    'hints': hints,
    'open': open,
    'startedAt': ?startedAt?.toUtc().toIso8601String(),
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
      open: json['open'] as bool? ?? false,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseCheckpoint &&
      other.exerciseId == exerciseId &&
      other.fen == fen &&
      other.turn == turn &&
      other.mistakes == mistakes &&
      other.hints == hints &&
      other.open == open &&
      other.startedAt == startedAt;

  @override
  int get hashCode =>
      Object.hash(exerciseId, fen, turn, mistakes, hints, open, startedAt);
}

/// O progresso em todas as aulas de finais.
class EndgameProgress {
  const EndgameProgress({this.lessons = const {}, this.ongoing});

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
      );

  EndgameProgress copyWith({
    Map<String, EndgameLessonProgress>? lessons,
    LessonCheckpoint? ongoing,
    bool clearOngoing = false,
  }) => EndgameProgress(
    lessons: lessons ?? this.lessons,
    ongoing: clearOngoing ? null : ongoing ?? this.ongoing,
  );

  Map<String, dynamic> toJson() => {
    'lessons': {
      for (final MapEntry(:key, :value) in lessons.entries) key: value.toJson(),
    },
    'ongoing': ?ongoing?.toJson(),
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
    );
  }
}
