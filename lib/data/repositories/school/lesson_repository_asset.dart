import 'dart:convert';

import 'package:dartchess/dartchess.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/lesson.dart';
import '../../services/asset_service.dart';
import 'lesson_repository.dart';

/// As aulas em `assets/lessons/course.json` e as falas em
/// `assets/lessons/<idioma>/lessons.json`.
class AssetLessonRepository implements LessonRepository {
  AssetLessonRepository(this._assets);

  static const coursePath = 'assets/lessons/course.json';
  static String textsPath(String language) =>
      'assets/lessons/$language/lessons.json';

  /// Os idiomas com falas. Outro idioma cai no inglês.
  static const languages = {'en', 'pt'};

  final AssetService _assets;
  Course? _course;
  final _texts = <String, LessonTexts>{};

  @override
  Future<Course> course() async =>
      _course ??= parseCourse(jsonDecode(await _assets.loadString(coursePath)));

  @override
  Future<LessonTexts> texts(String language) async {
    final english = await _load('en');
    if (language == 'en' || !languages.contains(language)) return english;
    return (await _load(language)).over(english);
  }

  Future<LessonTexts> _load(String language) async =>
      _texts[language] ??= LessonTexts.fromJson(
        jsonDecode(await _assets.loadString(textsPath(language)))
            as Map<String, dynamic>,
      );

  /// Lê o curso; passo de tipo desconhecido é ignorado, para dados novos não
  /// quebrarem versões antigas do app.
  static Course parseCourse(Object? json) {
    final modules = (json as Map<String, dynamic>)['modules'] as List;
    return Course(
      modules: [
        for (final module in modules.cast<Map<String, dynamic>>())
          CourseModule(
            id: module['id'] as String,
            lessons: [
              for (final lesson
                  in (module['lessons'] as List).cast<Map<String, dynamic>>())
                parseLesson(lesson),
            ],
          ),
      ],
    );
  }

  /// Uma aula (`id` e `steps`); passo de tipo desconhecido é ignorado.
  static Lesson parseLesson(Map<String, dynamic> lesson) => Lesson(
    id: lesson['id'] as String,
    steps: [
      for (final step in (lesson['steps'] as List).cast<Map<String, dynamic>>())
        ?_step(step),
    ],
  );

  /// As vezes do aluno de um passo de lance: os aceitos e a resposta. O
  /// lance ensinado (`teach`), quando vem, fica em primeiro entre os aceitos:
  /// é ele que a dica mostra e a quem a resposta combinada serve.
  static List<MoveTurn> parseLine(List<dynamic> line) => [
    for (final turn in line.cast<Map<String, dynamic>>())
      MoveTurn(
        accept: {
          if (turn['teach'] case final String teach) teach,
          for (final move in turn['accept'] as List) move as String,
        },
        reply: turn['reply'] as String?,
      ),
  ];

  static LessonStep? _step(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final fen = json['fen'] as String?;
    return switch (json['type']) {
      'talk' => TalkStep(
        id: id,
        fen: fen,
        arrows: [
          for (final arrow in json['arrows'] as List? ?? const [])
            if (arrow is String && arrow.length == 4)
              (arrow.substring(0, 2), arrow.substring(2)),
        ],
        marks: [
          for (final mark in json['marks'] as List? ?? const [])
            if (mark is String) mark,
        ],
        view: switch (json['side']) {
          'white' => Side.white,
          'black' => Side.black,
          _ => null,
        },
      ),
      'stars' when fen != null => StarsStep(
        id: id,
        fen: fen,
        stars: [for (final star in json['stars'] as List) star as String],
      ),
      'tap' when fen != null => TapStep(
        id: id,
        fen: fen,
        targets: [
          for (final target in json['targets'] as List) target as String,
        ],
        coordinates: json['coordinates'] != false,
      ),
      'move' when fen != null => MoveStep(
        id: id,
        fen: fen,
        line: parseLine(json['line'] as List),
      ),
      'play' when fen != null => PlayStep(
        id: id,
        fen: fen,
        goal: PlayGoal.fromCode(json['goal'] as String?),
        opponent:
            OpponentRef.tryParse(json['opponent'] as String?) ??
            const OpponentRef(kind: OpponentKind.stockfish),
      ),
      _ => null,
    };
  }
}
