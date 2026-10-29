final class OpeningTrack {
  OpeningTrack({
    required this.lessonId,
    required this.startedOn,
    Map<String, String> doneTrechos = const {},
    this.lastNewDate,
    Map<String, List<bool>> firstTry = const {},
  }) : doneTrechos = Map.unmodifiable(doneTrechos),
       firstTry = Map.unmodifiable(
         firstTry.map((k, v) => MapEntry(k, List<bool>.unmodifiable(v))),
       );
  final String lessonId, startedOn;
  final String? lastNewDate;

  /// Segment -> last completed local date. The oldest segment is reviewed first.
  final Map<String, String> doneTrechos;
  final Map<String, List<bool>> firstTry;
  int get firmMoves => firstTry.values.expand((v) => v).where((v) => v).length;
  int get seenMoves => firstTry.values.expand((v) => v).length;
  Map<String, Object?> toJson() => {
    'lessonId': lessonId,
    'startedOn': startedOn,
    'lastNewDate': lastNewDate,
    'doneTrechos': doneTrechos,
    'firstTry': firstTry,
  };
  factory OpeningTrack.fromJson(Map<String, dynamic> j) => OpeningTrack(
    lessonId: j['lessonId'] as String,
    startedOn: j['startedOn'] as String,
    lastNewDate: j['lastNewDate'] as String?,
    doneTrechos: (j['doneTrechos'] as Map).cast<String, String>(),
    firstTry: (j['firstTry'] as Map).map(
      (k, v) => MapEntry(k as String, (v as List).cast<bool>()),
    ),
  );
}
