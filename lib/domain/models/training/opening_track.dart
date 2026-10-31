final class OpeningTrack {
  OpeningTrack({
    required this.lessonId,
    required this.startedOn,
    Map<String, String> doneTrechos = const {},
    this.lastNewDate,
    Map<String, List<bool>> firstTry = const {},
    Map<String, List<int>> pendingMistakes = const {},
  }) : doneTrechos = Map.unmodifiable(doneTrechos),
       firstTry = Map.unmodifiable(
         firstTry.map((k, v) => MapEntry(k, List<bool>.unmodifiable(v))),
       ),
       pendingMistakes = Map.unmodifiable(
         pendingMistakes.map((k, v) => MapEntry(k, List<int>.unmodifiable(v))),
       );
  final String lessonId, startedOn;
  final String? lastNewDate;

  /// Segment -> last completed local date. The oldest segment is reviewed first.
  final Map<String, String> doneTrechos;
  final Map<String, List<bool>> firstTry;

  /// Segment -> zero-based student move indices penalized before completion.
  final Map<String, List<int>> pendingMistakes;

  OpeningTrack withMistake(String segment, int index) {
    if (index < 0) throw ArgumentError.value(index, 'index');
    final previous = pendingMistakes[segment] ?? const <int>[];
    if (previous.contains(index)) return this;
    return OpeningTrack(
      lessonId: lessonId,
      startedOn: startedOn,
      lastNewDate: lastNewDate,
      doneTrechos: doneTrechos,
      firstTry: firstTry,
      pendingMistakes: {
        ...pendingMistakes,
        segment: [...previous, index],
      },
    );
  }

  int get firmMoves => firstTry.values.expand((v) => v).where((v) => v).length;
  int get seenMoves => firstTry.values.expand((v) => v).length;
  Map<String, Object?> toJson() => {
    'lessonId': lessonId,
    'startedOn': startedOn,
    'lastNewDate': lastNewDate,
    'doneTrechos': doneTrechos,
    'firstTry': firstTry,
    'pendingMistakes': pendingMistakes,
  };
  factory OpeningTrack.fromJson(Map<String, dynamic> j) => OpeningTrack(
    lessonId: j['lessonId'] as String,
    startedOn: j['startedOn'] as String,
    lastNewDate: j['lastNewDate'] as String?,
    doneTrechos: (j['doneTrechos'] as Map).cast<String, String>(),
    firstTry: (j['firstTry'] as Map).map(
      (k, v) => MapEntry(k as String, (v as List).cast<bool>()),
    ),
    pendingMistakes: (j['pendingMistakes'] as Map? ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as List).cast<int>()),
    ),
  );
}
