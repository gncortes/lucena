import 'day_goals.dart';
import 'opening_track.dart';
import 'theme_cycle.dart';
import 'training_course.dart';
import 'training_plan.dart';

final class TrainingState {
  TrainingState({
    required this.course,
    required this.installSeed,
    this.plan = const TrainingPlan(),
    this.onboardingDone = false,
    this.tourSeen = false,
    this.tab = CourseGuideTab.lesson,
    this.day,
    this.lastLessonDate,
    this.lastActivityAt,
    Map<String, String> completedLessons = const {},
    Map<String, ThemeCycle> cycles = const {},
    Map<String, OpeningTrack> openings = const {},
    Iterable<String> offDayCredits = const [],
  }) : completedLessons = Map.unmodifiable(completedLessons),
       cycles = Map.unmodifiable(cycles),
       openings = Map.unmodifiable(openings),
       offDayCredits = List.unmodifiable(offDayCredits);
  final TrainingCourse course;
  final String installSeed;
  final TrainingPlan plan;
  final bool onboardingDone, tourSeen;
  final CourseGuideTab tab;
  final DayGoals? day;
  final String? lastLessonDate;
  final DateTime? lastActivityAt;
  final Map<String, String> completedLessons;
  final Map<String, ThemeCycle> cycles;
  final Map<String, OpeningTrack> openings;
  final List<String> offDayCredits;
  bool get mock => day?.goals.any((g) => g.mock) ?? false;
  TrainingState copyWith({
    TrainingPlan? plan,
    bool? onboardingDone,
    bool? tourSeen,
    CourseGuideTab? tab,
    DayGoals? day,
    String? lastLessonDate,
    DateTime? lastActivityAt,
    Map<String, String>? completedLessons,
    Map<String, ThemeCycle>? cycles,
    Map<String, OpeningTrack>? openings,
    Iterable<String>? offDayCredits,
  }) => TrainingState(
    course: course,
    installSeed: installSeed,
    plan: plan ?? this.plan,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    tourSeen: tourSeen ?? this.tourSeen,
    tab: tab ?? this.tab,
    day: day ?? this.day,
    lastLessonDate: lastLessonDate ?? this.lastLessonDate,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    completedLessons: completedLessons ?? this.completedLessons,
    cycles: cycles ?? this.cycles,
    openings: openings ?? this.openings,
    offDayCredits: offDayCredits ?? this.offDayCredits,
  );
  Map<String, Object?> toJson() => {
    'version': 1,
    'course': course.name,
    'installSeed': installSeed,
    'plan': plan.toJson(),
    'onboardingDone': onboardingDone,
    'tourSeen': tourSeen,
    'tab': tab.name,
    'day': day?.toJson(),
    'lastLessonDate': lastLessonDate,
    'lastActivityAt': lastActivityAt?.toIso8601String(),
    'completedLessons': completedLessons,
    'cycles': cycles.map((k, v) => MapEntry(k, v.toJson())),
    'openings': openings.map((k, v) => MapEntry(k, v.toJson())),
    'offDayCredits': offDayCredits,
  };
  factory TrainingState.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Unsupported training version');
    }
    return TrainingState(
      course: TrainingCourse.values.byName(j['course'] as String),
      installSeed: j['installSeed'] as String,
      plan: TrainingPlan.fromJson(Map<String, dynamic>.from(j['plan'] as Map)),
      onboardingDone: j['onboardingDone'] as bool,
      tourSeen: j['tourSeen'] as bool,
      tab: CourseGuideTab.values.byName(j['tab'] as String),
      day: j['day'] == null
          ? null
          : DayGoals.fromJson(Map<String, dynamic>.from(j['day'] as Map)),
      lastLessonDate: j['lastLessonDate'] as String?,
      lastActivityAt: j['lastActivityAt'] == null
          ? null
          : DateTime.parse(j['lastActivityAt'] as String),
      completedLessons: (j['completedLessons'] as Map).cast<String, String>(),
      cycles: (j['cycles'] as Map).map(
        (k, v) => MapEntry(
          k as String,
          ThemeCycle.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      openings: (j['openings'] as Map).map(
        (k, v) => MapEntry(
          k as String,
          OpeningTrack.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      offDayCredits: (j['offDayCredits'] as List).cast<String>(),
    );
  }
}
