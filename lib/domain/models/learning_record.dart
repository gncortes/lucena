/// Observed actions only. Missing dates never inherit legacy progress dates.
/// firstStartedAt is the first execution checkpoint observed for this account
/// and content fingerprint; it is not a visit to a completion screen.
class LearningRecord {
  const LearningRecord({
    required this.kind,
    required this.unitId,
    required this.version,
    this.firstStartedAt,
    this.contentCompletedAt,
    this.testPassedAt,
    this.lastActivityAt,
    this.exerciseStars = const {},
  });
  final String kind;
  final String unitId;
  final String version;

  /// Best observed result of each exercise in this exact content revision.
  /// Legacy stars/approval are never copied into this map.
  final Map<String, int> exerciseStars;
  final DateTime? firstStartedAt,
      contentCompletedAt,
      testPassedAt,
      lastActivityAt;
  String get key => [kind, unitId, version].map(Uri.encodeComponent).join('|');
  Map<String, Object?> toJson() => {
    'kind': kind,
    'unitId': unitId,
    'version': version,
    'firstStartedAt': ?firstStartedAt?.toUtc().toIso8601String(),
    'contentCompletedAt': ?contentCompletedAt?.toUtc().toIso8601String(),
    'testPassedAt': ?testPassedAt?.toUtc().toIso8601String(),
    'lastActivityAt': ?lastActivityAt?.toUtc().toIso8601String(),
    if (exerciseStars.isNotEmpty) 'exerciseStars': exerciseStars,
  };
  static List<LearningRecord> parse(Object? json) => [
    if (json is List)
      for (final item in json)
        if (item is Map &&
            item['kind'] is String &&
            item['unitId'] is String &&
            item['version'] is String)
          LearningRecord(
            kind: item['kind'] as String,
            unitId: item['unitId'] as String,
            version: item['version'] as String,
            firstStartedAt: _date(item['firstStartedAt']),
            contentCompletedAt: _date(item['contentCompletedAt']),
            testPassedAt: _date(item['testPassedAt']),
            lastActivityAt: _date(item['lastActivityAt']),
            exerciseStars: {
              if (item['exerciseStars'] is Map)
                for (final entry in (item['exerciseStars'] as Map).entries)
                  if (entry.key is String &&
                      entry.value is int &&
                      (entry.value as int) >= 0)
                    entry.key as String: entry.value as int,
            },
          ),
  ];
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
  static DateTime? _min(DateTime? a, DateTime? b) => a == null
      ? b
      : b == null || a.isBefore(b)
      ? a
      : b;
  static DateTime? _max(DateTime? a, DateTime? b) => a == null
      ? b
      : b == null || a.isAfter(b)
      ? a
      : b;
  static List<LearningRecord> merge(
    Iterable<LearningRecord> a,
    Iterable<LearningRecord> b,
  ) {
    final records = <String, LearningRecord>{};
    for (final record in [...a, ...b]) {
      final before = records[record.key];
      records[record.key] = before == null
          ? record
          : LearningRecord(
              kind: record.kind,
              unitId: record.unitId,
              version: record.version,
              firstStartedAt: _min(
                before.firstStartedAt,
                record.firstStartedAt,
              ),
              contentCompletedAt: _min(
                before.contentCompletedAt,
                record.contentCompletedAt,
              ),
              testPassedAt: _min(before.testPassedAt, record.testPassedAt),
              lastActivityAt: _max(
                before.lastActivityAt,
                record.lastActivityAt,
              ),
              exerciseStars: {
                for (final key in {
                  ...before.exerciseStars.keys,
                  ...record.exerciseStars.keys,
                })
                  key:
                      (before.exerciseStars[key] ?? 0) >
                          (record.exerciseStars[key] ?? 0)
                      ? before.exerciseStars[key]!
                      : record.exerciseStars[key] ?? 0,
              },
            );
    }
    return records.values.toList()..sort((a, b) => a.key.compareTo(b.key));
  }
}
