/// Uma semana do plano: capítulos inteiros, ou só revisão na última.
final class PlanWeek {
  PlanWeek({
    required this.start,
    required this.end,
    Iterable<String> chapterIds = const [],
    this.review = false,
  }) : chapterIds = List.unmodifiable(chapterIds);

  /// Datas civis `yyyy-MM-dd`, inclusive.
  final String start, end;
  final List<String> chapterIds;
  final bool review;

  Map<String, Object?> toJson() => {
    'start': start,
    'end': end,
    'chapters': chapterIds,
    'review': review,
  };

  factory PlanWeek.fromJson(Map<String, dynamic> j) => PlanWeek(
    start: j['start'] as String,
    end: j['end'] as String,
    chapterIds: (j['chapters'] as List).cast<String>(),
    review: j['review'] as bool? ?? false,
  );
}

/// Plano por capítulos inteiros (H-TRE-07). Sem torneio, [weeks] fica vazio e
/// [chapterIds] é a fila na ordem do curso.
final class StudyPlan {
  StudyPlan({
    required this.createdOn,
    Iterable<PlanWeek> weeks = const [],
    Iterable<String> chapterIds = const [],
    Iterable<String> deferredIds = const [],
    Iterable<String> dismissedLate = const [],
  }) : weeks = List.unmodifiable(weeks),
       chapterIds = List.unmodifiable(chapterIds),
       deferredIds = List.unmodifiable(deferredIds),
       dismissedLate = List.unmodifiable(dismissedLate);

  final String createdOn;
  final List<PlanWeek> weeks;

  /// Capítulos que entram no plano, na ordem do curso.
  final List<String> chapterIds;

  /// Capítulos que ficam para depois do torneio.
  final List<String> deferredIds;

  /// Capítulos atrasados em que o aluno tocou "Agora não" (por semana).
  final List<String> dismissedLate;

  StudyPlan copyWith({
    Iterable<PlanWeek>? weeks,
    Iterable<String>? chapterIds,
    Iterable<String>? deferredIds,
    Iterable<String>? dismissedLate,
  }) => StudyPlan(
    createdOn: createdOn,
    weeks: weeks ?? this.weeks,
    chapterIds: chapterIds ?? this.chapterIds,
    deferredIds: deferredIds ?? this.deferredIds,
    dismissedLate: dismissedLate ?? this.dismissedLate,
  );

  Map<String, Object?> toJson() => {
    'createdOn': createdOn,
    'weeks': weeks.map((w) => w.toJson()).toList(),
    'chapters': chapterIds,
    'deferred': deferredIds,
    'dismissedLate': dismissedLate,
  };

  static StudyPlan? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      return StudyPlan(
        createdOn: raw['createdOn'] as String,
        weeks: (raw['weeks'] as List).map(
          (w) => PlanWeek.fromJson(Map<String, dynamic>.from(w as Map)),
        ),
        chapterIds: (raw['chapters'] as List).cast<String>(),
        deferredIds: (raw['deferred'] as List).cast<String>(),
        dismissedLate: (raw['dismissedLate'] as List? ?? const [])
            .cast<String>(),
      );
    } on Object {
      return null;
    }
  }
}
