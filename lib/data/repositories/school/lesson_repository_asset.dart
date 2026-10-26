import 'dart:convert';

import 'package:dartchess/dartchess.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/variation_tree.dart';
import '../../services/asset_service.dart';
import '../../services/scoped_asset_cache.dart';
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
  late final _cache = ScopedAssetCache(_assets);

  @override
  Future<Course> course() => _cache.load(
    coursePath,
    () async => parseCourse(jsonDecode(await _assets.loadString(coursePath))),
  );

  @override
  Future<LessonTexts> texts(String language) =>
      _cache.load(('texts', language), () => _loadTexts(language));

  Future<LessonTexts> _loadTexts(String language) async {
    final english = await _load('en');
    if (language == 'en' || !languages.contains(language)) return english;
    return (await _load(language)).over(english);
  }

  Future<LessonTexts> _load(String language) => _cache.load(
    textsPath(language),
    () async => LessonTexts.fromJson(
      jsonDecode(await _assets.loadString(textsPath(language)))
          as Map<String, dynamic>,
    ),
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

  /// Uma aula (`id` e `steps`, ou `parts` com os passos de cada parte);
  /// passo de tipo desconhecido é ignorado.
  static Lesson parseLesson(Map<String, dynamic> lesson) {
    final id = lesson['id'] as String;
    List<LessonStep> steps(List<dynamic> json) => [
      for (final step in json.cast<Map<String, dynamic>>()) ?_step(step),
    ];
    final parts = lesson['parts'];
    if (parts is List) {
      return Lesson.parted(
        id: id,
        parts: [
          for (final part in parts.cast<Map<String, dynamic>>())
            LessonPart(
              id: part['id'] as String,
              steps: steps(part['steps'] as List? ?? const []),
              script: part['roteiro'] as String?,
            ),
        ],
      );
    }
    return Lesson(
      id: id,
      steps: steps(lesson['steps'] as List),
      script: lesson['roteiro'] as String?,
    );
  }

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
    final ref = json['ref'] as String?;
    final lines = _lines(json['lines']);
    return switch (json['type']) {
      'talk' => TalkStep(
        id: id,
        fen: fen,
        ref: ref,
        lines: lines,
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
      'think' when fen != null => ThinkStep(
        id: id,
        fen: fen,
        ref: ref,
        lines: lines,
        hints: json['hints'] as int? ?? 1,
        ask: ThinkAsk.fromCode(json['ask'] as String?),
        arrows: _arrows(json['arrows']),
        marks: _marks(json['marks']),
        view: _side(json['side']),
        accept: _moves(json['accept']),
        refusals: _refusals(json['refusals']),
        mistakes: _mistakes(json['mistakes']),
      ),
      'demo' when fen != null => DemoStep(
        id: id,
        fen: fen,
        ref: ref,
        lines: lines,
        view: _side(json['side']),
        wrong: json['wrong'] == true,
        line: [
          for (final move
              in (json['line'] as List).cast<Map<String, dynamic>>())
            DemoMove(
              uci: move['uci'] as String,
              arrows: _arrows(move['arrows']),
              marks: _marks(move['marks']),
            ),
        ],
      ),
      'stars' when fen != null => StarsStep(
        id: id,
        fen: fen,
        ref: ref,
        lines: lines,
        stars: [for (final star in json['stars'] as List) star as String],
      ),
      'tap' when fen != null => TapStep(
        id: id,
        fen: fen,
        ref: ref,
        lines: lines,
        targets: [
          for (final target in json['targets'] as List) target as String,
        ],
        coordinates: json['coordinates'] != false,
      ),
      'move' when fen != null => MoveStep(
        id: id,
        fen: fen,
        ref: ref,
        lines: lines,
        line: parseLine(json['line'] as List),
        mistakes: _mistakes(json['mistakes']),
      ),
      'play' when fen != null => PlayStep(
        id: id,
        fen: fen,
        ref: ref,
        lines: lines,
        goal: PlayGoal.fromCode(json['goal'] as String?),
        opponent:
            OpponentRef.tryParse(json['opponent'] as String?) ??
            const OpponentRef(kind: OpponentKind.stockfish),
        mistakes: _mistakes(json['mistakes']),
      ),
      _ => null,
    };
  }

  static List<(String, String)> _arrows(Object? json) => [
    for (final arrow in json as List? ?? const [])
      if (arrow is String && arrow.length == 4)
        (arrow.substring(0, 2), arrow.substring(2)),
  ];

  static List<String> _marks(Object? json) => [
    for (final mark in json as List? ?? const [])
      if (mark is String) mark,
  ];

  static Side? _side(Object? json) => switch (json) {
    'white' => Side.white,
    'black' => Side.black,
    _ => null,
  };

  static Set<String> _moves(Object? json) => {
    for (final move in json as List? ?? const [])
      if (move is String) move,
  };

  /// `"lines": [{"uci": "e3e4 e6e7", "wrong": true}]`: os lances separados
  /// por espaço (ou numa lista).
  static List<CitedLine> _lines(Object? json) => [
    for (final line in json as List? ?? const [])
      if (line is Map)
        if (switch (line['uci']) {
              final String text => text.split(RegExp(r'\s+')),
              final List list => [
                for (final move in list)
                  if (move is String) move,
              ],
              _ => const <String>[],
            }
            case final uci when uci.any((move) => move.isNotEmpty))
          CitedLine(
            uci: [
              for (final move in uci)
                if (move.isNotEmpty) move,
            ],
            wrong: line['wrong'] == true,
            branches: _branches(line['branches']),
          ),
  ];

  /// `"branches": [{"id":"g4","at":2,"uci":["g3g4","f7g6"],
  /// "glyphs":["?",null],"result":"draw"}]`.
  static List<CitedBranch> _branches(Object? json) => [
    for (final branch in json as List? ?? const [])
      if (branch is Map && branch['id'] is String && branch['at'] is int)
        if (switch (branch['uci']) {
              final String text => text.split(RegExp(r'\s+')),
              final List list => [for (final m in list) ?(m as String?)],
              _ => const <String>[],
            }.where((move) => move.isNotEmpty).toList()
            case final uci when uci.isNotEmpty)
          CitedBranch(
            id: branch['id'] as String,
            at: branch['at'] as int,
            uci: uci,
            glyphs: [
              for (final glyph in branch['glyphs'] as List? ?? const [])
                glyph is String && glyph.isNotEmpty ? glyph : null,
            ],
            result: VariationResult.parse(branch['result']),
          ),
  ];

  /// `"mistakes": {"e3e4": {"say": "step.w1.e3e4", "review": "opp"}}`.
  static Map<String, StepMistake> _mistakes(Object? json) => {
    for (final MapEntry(:key, :value) in (json as Map? ?? const {}).entries)
      if (key is String && value is Map)
        key: StepMistake(
          say: value['say'] as String?,
          review: value['review'] as String?,
        ),
  };

  static Map<String, int> _refusals(Object? json) => {
    for (final MapEntry(:key, :value) in (json as Map? ?? const {}).entries)
      if (key is String && value is int) key: value,
  };
}
