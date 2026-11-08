/// Como o aluno disse onde mais erra.
enum DiagnosticMethod { test, questionnaire }

/// Nível dito em cada tema do questionário (H-TRE-06), do mais fraco ao mais forte.
enum TopicLevel { learning, practicing, mastered }

/// Estado salvo do teste e do questionário, gravado a cada resposta (G9).
final class TrainingDiagnostic {
  TrainingDiagnostic({
    this.method,
    Iterable<String> testChapterIds = const [],
    Iterable<bool> testAnswers = const [],
    Map<String, TopicLevel> topics = const {},
    this.finished = false,
  }) : testChapterIds = List.unmodifiable(testChapterIds),
       testAnswers = List.unmodifiable(testAnswers),
       topics = Map.unmodifiable(topics);

  final DiagnosticMethod? method;

  /// Um capítulo por posição do teste, na ordem em que aparecem.
  final List<String> testChapterIds;

  /// Acerto de cada posição já respondida ("Não sei" conta como erro).
  final List<bool> testAnswers;

  /// Questionário: área (id) -> nível.
  final Map<String, TopicLevel> topics;
  final bool finished;

  bool get testStarted => testChapterIds.isNotEmpty;
  int get testSize => testChapterIds.length;
  int get testAnswered => testAnswers.length;
  bool get testComplete => testStarted && testAnswered >= testSize;

  TrainingDiagnostic copyWith({
    DiagnosticMethod? method,
    Iterable<String>? testChapterIds,
    Iterable<bool>? testAnswers,
    Map<String, TopicLevel>? topics,
    bool? finished,
  }) => TrainingDiagnostic(
    method: method ?? this.method,
    testChapterIds: testChapterIds ?? this.testChapterIds,
    testAnswers: testAnswers ?? this.testAnswers,
    topics: topics ?? this.topics,
    finished: finished ?? this.finished,
  );

  Map<String, Object?> toJson() => {
    'method': method?.name,
    'testChapters': testChapterIds,
    'testAnswers': testAnswers,
    'topics': topics.map((k, v) => MapEntry(k, v.name)),
    'finished': finished,
  };

  static TrainingDiagnostic? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final method = raw['method'] as String?;
      return TrainingDiagnostic(
        method: method == null ? null : DiagnosticMethod.values.byName(method),
        testChapterIds: (raw['testChapters'] as List).cast<String>(),
        testAnswers: (raw['testAnswers'] as List).cast<bool>(),
        topics: (raw['topics'] as Map).map(
          (k, v) =>
              MapEntry(k as String, TopicLevel.values.byName(v as String)),
        ),
        finished: raw['finished'] as bool? ?? false,
      );
    } on Object {
      return null;
    }
  }
}
