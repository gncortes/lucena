import 'dart:convert';

/// Only codes, timestamps and counters. No board position or displayed text.
final class TrainingAnalyticsAttempt {
  TrainingAnalyticsAttempt({
    required this.started,
    required this.origin,
    this.cycleDay = 0,
    this.lessonId,
    this.correct = true,
    this.points,
    Map<String, int> hintCounts = const {},
  }) : hintCounts = Map.unmodifiable(hintCounts);
  final DateTime started;
  final String origin;
  final String? lessonId;
  final int cycleDay;
  final bool correct;
  final int? points;
  final Map<String, int> hintCounts;
  int get hints => hintCounts.values.fold(0, (sum, value) => sum + value);
  TrainingAnalyticsAttempt result({
    required bool correct,
    int hints = 0,
    int? points,
    String hintKey = 'meta',
  }) => TrainingAnalyticsAttempt(
    started: started,
    origin: origin,
    cycleDay: cycleDay,
    lessonId: lessonId,
    correct: this.correct && correct,
    points: points ?? this.points,
    hintCounts: {
      ...hintCounts,
      hintKey: hints > (hintCounts[hintKey] ?? 0)
          ? hints
          : hintCounts[hintKey] ?? 0,
    },
  );
  TrainingAnalyticsAttempt merge(TrainingAnalyticsAttempt other) {
    final first = started.isAfter(other.started) ? other : this;
    return TrainingAnalyticsAttempt(
      started: first.started,
      origin: first.origin,
      cycleDay: first.cycleDay,
      lessonId: first.lessonId ?? lessonId ?? other.lessonId,
      correct: correct && other.correct,
      points: other.points ?? points,
      hintCounts: {
        for (final key in {...hintCounts.keys, ...other.hintCounts.keys})
          key: (hintCounts[key] ?? 0) > (other.hintCounts[key] ?? 0)
              ? hintCounts[key]!
              : other.hintCounts[key] ?? 0,
      },
    );
  }

  Map<String, Object?> toJson() => {
    'started': started.toIso8601String(),
    'origin': origin,
    'cycleDay': cycleDay,
    'lessonId': lessonId,
    'correct': correct,
    'points': points,
    'hintCounts': hintCounts,
  };
  factory TrainingAnalyticsAttempt.fromJson(Map<String, dynamic> json) =>
      TrainingAnalyticsAttempt(
        started: DateTime.parse(json['started'] as String),
        origin: json['origin'] as String,
        cycleDay: json['cycleDay'] as int? ?? 0,
        lessonId: json['lessonId'] as String?,
        correct: json['correct'] as bool? ?? true,
        points: json['points'] as int?,
        hintCounts: (json['hintCounts'] as Map? ?? {}).cast<String, int>(),
      );
}

final class TrainingAnalyticsSegment {
  const TrainingAnalyticsSegment({
    required this.lessonId,
    required this.segmentId,
    required this.started,
    required this.origin,
    required this.total,
    required this.review,
    required this.mock,
    this.errors = 0,
    this.back = 0,
    this.forward = 0,
    this.notation = 0,
    this.hints = 0,
    this.finished,
  });
  final String lessonId, segmentId, origin;
  final DateTime started;
  final DateTime? finished;
  final int total, errors, back, forward, notation, hints;
  final bool review, mock;
  String get key => '$lessonId:$segmentId';
  TrainingAnalyticsSegment copyWith({
    int? errors,
    int? back,
    int? forward,
    int? notation,
    int? hints,
    DateTime? finished,
  }) => TrainingAnalyticsSegment(
    lessonId: lessonId,
    segmentId: segmentId,
    started: started,
    origin: origin,
    total: total,
    review: review,
    mock: mock,
    errors: errors ?? this.errors,
    back: back ?? this.back,
    forward: forward ?? this.forward,
    notation: notation ?? this.notation,
    hints: hints ?? this.hints,
    finished: finished ?? this.finished,
  );
  TrainingAnalyticsSegment merge(TrainingAnalyticsSegment other) => copyWith(
    errors: errors > other.errors ? errors : other.errors,
    back: back > other.back ? back : other.back,
    forward: forward > other.forward ? forward : other.forward,
    notation: notation > other.notation ? notation : other.notation,
    hints: hints > other.hints ? hints : other.hints,
    finished: finished ?? other.finished,
  );
  Map<String, Object?> toJson() => {
    'lessonId': lessonId,
    'segmentId': segmentId,
    'started': started.toIso8601String(),
    'origin': origin,
    'total': total,
    'review': review,
    'mock': mock,
    'errors': errors,
    'back': back,
    'forward': forward,
    'notation': notation,
    'hints': hints,
    'finished': finished?.toIso8601String(),
  };
  factory TrainingAnalyticsSegment.fromJson(Map<String, dynamic> json) =>
      TrainingAnalyticsSegment(
        lessonId: json['lessonId'] as String,
        segmentId: json['segmentId'] as String,
        started: DateTime.parse(json['started'] as String),
        origin: json['origin'] as String,
        total: json['total'] as int,
        review: json['review'] as bool,
        mock: json['mock'] as bool,
        errors: json['errors'] as int? ?? 0,
        back: json['back'] as int? ?? 0,
        forward: json['forward'] as int? ?? 0,
        notation: json['notation'] as int? ?? 0,
        hints: json['hints'] as int? ?? 0,
        finished: DateTime.tryParse(json['finished'] as String? ?? ''),
      );
}

/// Scoped to the frozen local day. Old-day contexts are discarded together.
final class TrainingAnalyticsState {
  TrainingAnalyticsState({
    this.date,
    Map<String, TrainingAnalyticsAttempt> attempts = const {},
    Map<String, TrainingAnalyticsSegment> segments = const {},
  }) : attempts = Map.unmodifiable(attempts),
       segments = Map.unmodifiable(segments);
  final String? date;
  final Map<String, TrainingAnalyticsAttempt> attempts;
  final Map<String, TrainingAnalyticsSegment> segments;
  TrainingAnalyticsState merge(TrainingAnalyticsState other) {
    if (date != other.date) return other;
    return TrainingAnalyticsState(
      date: date,
      attempts: {
        ...attempts,
        for (final entry in other.attempts.entries)
          entry.key: attempts[entry.key]?.merge(entry.value) ?? entry.value,
      },
      segments: {
        ...segments,
        for (final entry in other.segments.entries)
          entry.key: segments[entry.key]?.merge(entry.value) ?? entry.value,
      },
    );
  }

  bool same(TrainingAnalyticsState other) =>
      jsonEncode(toJson()) == jsonEncode(other.toJson());
  Map<String, Object?> toJson() => {
    'date': date,
    'attempts': attempts.map((k, v) => MapEntry(k, v.toJson())),
    'segments': segments.map((k, v) => MapEntry(k, v.toJson())),
  };
  factory TrainingAnalyticsState.fromJson(
    Map<String, dynamic> json,
  ) => TrainingAnalyticsState(
    date: json['date'] as String?,
    attempts: (json['attempts'] as Map? ?? {}).map(
      (k, v) => MapEntry(
        k as String,
        TrainingAnalyticsAttempt.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    ),
    segments: (json['segments'] as Map? ?? {}).map(
      (k, v) => MapEntry(
        k as String,
        TrainingAnalyticsSegment.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    ),
  );
}
