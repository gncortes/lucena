import '../lesson_script.dart';
import 'training_course.dart';

final class TrainingLesson {
  const TrainingLesson({
    required this.id,
    required this.kind,
    required this.title,
    this.summary = '',
    this.group = '',
    this.groupId = '',
    this.partId = '',
    this.partTitle = '',
    this.visible = true,
  });
  final String id, title, summary, group, groupId, partId, partTitle;
  final TrainingLessonKind kind;
  final bool visible;
  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'summary': summary,
    'group': group,
    'groupId': groupId,
    'partId': partId,
    'partTitle': partTitle,
    'visible': visible,
  };
  factory TrainingLesson.fromJson(Map<String, dynamic> j) => TrainingLesson(
    id: j['id'] as String,
    kind: TrainingLessonKind.values.byName(j['kind'] as String),
    title: j['title'] as String,
    summary: j['summary'] as String? ?? '',
    group: j['group'] as String? ?? '',
    groupId: j['groupId'] as String? ?? '',
    partId: j['partId'] as String? ?? '',
    partTitle: j['partTitle'] as String? ?? '',
    visible: j['visible'] as bool? ?? true,
  );
}

final class TrainingExercise {
  TrainingExercise({
    required this.id,
    required this.stars,
    required this.fen,
    required Iterable<String> solution,
    Iterable<String> alternatives = const [],
    Map<int, List<String>> alternativesByPosition = const {},
    this.lastMove,
    this.mock = false,
  }) : assert(stars >= 1 && stars <= 3),
       solution = List.unmodifiable(solution),
       alternatives = List.unmodifiable(alternatives),
       alternativesByPosition = Map.unmodifiable(
         alternativesByPosition.map(
           (position, moves) =>
               MapEntry(position, List<String>.unmodifiable(moves)),
         ),
       );
  final String id, fen;
  final String? lastMove;
  final int stars;
  final bool mock;
  final List<String> solution, alternatives;

  /// Student turn, starting at one. Accepted branches have no exported reply.
  final Map<int, List<String>> alternativesByPosition;
  List<String> alternativesAt(int cursor) => [
    if (cursor == 0) ...alternatives,
    ...?alternativesByPosition[cursor ~/ 2 + 1],
  ];
  Map<String, Object?> toJson() => {
    'id': id,
    'estrelas': stars,
    'fen': fen,
    'ultimo': lastMove,
    'solucao': solution,
    'alternativas': alternatives,
    if (alternativesByPosition.isNotEmpty)
      'alternativas_por_posicao': alternativesByPosition.map(
        (position, moves) => MapEntry('$position', moves),
      ),
    'mock': mock,
  };
  factory TrainingExercise.fromJson(Map<String, dynamic> j) => TrainingExercise(
    id: j['id'] as String,
    stars: j['estrelas'] as int,
    fen: j['fen'] as String,
    lastMove: j['ultimo'] as String?,
    solution: (j['solucao'] as List).cast<String>(),
    alternatives: (j['alternativas'] as List? ?? []).cast<String>(),
    alternativesByPosition: (j['alternativas_por_posicao'] as Map? ?? {}).map(
      (position, moves) => MapEntry(
        int.parse(position as String),
        (moves as List).cast<String>(),
      ),
    ),
    mock: j['mock'] as bool? ?? false,
  );
}

final class OpeningTrecho {
  OpeningTrecho({
    required this.id,
    required this.title,
    Iterable<String> moves = const [],
    this.fen,
    this.source,
    this.stage,
    Map<String, dynamic>? example,
    this.black = false,
    this.mock = false,
  }) : moves = List.unmodifiable(moves),
       example = example == null ? null : _freezeJsonMap(example),
       script = example == null ? null : ScriptExample.fromJson(example);
  final String id, title;
  final String? fen, source, stage;
  final Map<String, dynamic>? example;
  final ScriptExample? script;
  final List<String> moves;
  final bool black, mock;
  Map<String, Object?> toJson() => {
    'id': id,
    'titulo': title,
    if (example == null) 'lances': moves,
    if (fen != null) 'fen': fen,
    if (source != null) 'fonte': source,
    if (stage != null) 'etapa': stage,
    if (example != null) 'exemplo': example,
    'cor': black ? 'pretas' : 'brancas',
    'mock': mock,
  };
  factory OpeningTrecho.fromJson(Map<String, dynamic> j) => OpeningTrecho(
    id: j['id'] as String,
    title: j['titulo'] as String,
    moves: (j['lances'] as List? ?? []).cast<String>(),
    fen: j['fen'] as String?,
    source: j['fonte'] as String?,
    stage: j['etapa'] as String?,
    example: j['exemplo'] as Map<String, dynamic>?,
    black: j['cor'] == 'pretas',
    mock: j['mock'] as bool? ?? false,
  );
}

Map<String, dynamic> _freezeJsonMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.unmodifiable(
      value.map((key, item) => MapEntry(key, _freezeJson(item))),
    );
Object? _freezeJson(Object? value) => switch (value) {
  Map<String, dynamic> map => _freezeJsonMap(map),
  List list => List<Object?>.unmodifiable(list.map(_freezeJson)),
  _ => value,
};
