import 'training_course.dart';

final class ThemeDay {
  const ThemeDay({
    required this.date,
    required this.exerciseId,
    required this.stars,
    required this.correct,
    this.hint = false,
    this.mock = false,
    this.phase = ThemePhase.cycle,
    this.elapsedMs,
  });
  final String date, exerciseId;
  final int stars;

  /// Recorded attempt duration. Legacy history has no measured time.
  final int? elapsedMs;
  final bool correct, hint, mock;
  final ThemePhase phase;
  bool get earned => correct && !hint;
  Map<String, Object?> toJson() => {
    'date': date,
    'exerciseId': exerciseId,
    'stars': stars,
    'correct': correct,
    'hint': hint,
    'mock': mock,
    'phase': phase.name,
    if (elapsedMs != null) 'elapsedMs': elapsedMs,
  };
  factory ThemeDay.fromJson(Map<String, dynamic> j) => ThemeDay(
    elapsedMs: j['elapsedMs'] as int?,
    date: j['date'] as String,
    exerciseId: j['exerciseId'] as String,
    stars: j['stars'] as int,
    correct: j['correct'] as bool,
    hint: j['hint'] as bool,
    mock: j['mock'] as bool,
    phase: ThemePhase.values.byName(j['phase'] as String),
  );
}

final class ThemeCycle {
  ThemeCycle({
    required this.lessonId,
    required this.startedOn,
    this.phase = ThemePhase.cycle,
    this.level = 1,
    this.hadError = false,
    this.streak = 0,
    Iterable<ThemeDay> days = const [],
    Iterable<String> reinforcement = const [],
  }) : days = List.unmodifiable(days),
       reinforcement = List.unmodifiable(reinforcement);
  final String lessonId, startedOn;
  final ThemePhase phase;
  final int level, streak;
  final bool hadError;
  final List<ThemeDay> days;

  /// Frozen remaining bank when reinforcement begins, in delivery order.
  final List<String> reinforcement;
  List<ThemeDay> get cycleDays =>
      days.where((d) => d.phase == ThemePhase.cycle).toList(growable: false);
  List<ThemeDay> get reinforceDays => days
      .where((d) => d.phase == ThemePhase.reinforce)
      .toList(growable: false);
  Set<String> get seen => days.map((d) => d.exerciseId).toSet();
  int get score =>
      (cycleDays.where((d) => d.earned).fold(0, (n, d) => n + d.stars) *
              100 /
              15)
          .round();
  int get reinforceScore => reinforceDays.isEmpty
      ? 0
      : (reinforceDays.where((d) => d.earned).length *
                100 /
                reinforceDays.length)
            .round();
  ThemeCycle copyWith({
    ThemePhase? phase,
    int? level,
    bool? hadError,
    int? streak,
    Iterable<ThemeDay>? days,
    Iterable<String>? reinforcement,
  }) => ThemeCycle(
    lessonId: lessonId,
    startedOn: startedOn,
    phase: phase ?? this.phase,
    level: level ?? this.level,
    hadError: hadError ?? this.hadError,
    streak: streak ?? this.streak,
    days: days ?? this.days,
    reinforcement: reinforcement ?? this.reinforcement,
  );
  Map<String, Object?> toJson() => {
    'lessonId': lessonId,
    'startedOn': startedOn,
    'phase': phase.name,
    'level': level,
    'hadError': hadError,
    'streak': streak,
    'days': days.map((d) => d.toJson()).toList(),
    'reinforcement': reinforcement,
  };
  factory ThemeCycle.fromJson(Map<String, dynamic> j) => ThemeCycle(
    lessonId: j['lessonId'] as String,
    startedOn: j['startedOn'] as String,
    phase: ThemePhase.values.byName(j['phase'] as String),
    level: j['level'] as int,
    hadError: j['hadError'] as bool,
    streak: j['streak'] as int,
    days: (j['days'] as List).map(
      (d) => ThemeDay.fromJson(Map<String, dynamic>.from(d as Map)),
    ),
    reinforcement: (j['reinforcement'] as List).cast<String>(),
  );
}
