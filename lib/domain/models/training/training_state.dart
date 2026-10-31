import 'day_goals.dart';
import 'training_analytics_state.dart';
import 'school_training_progress.dart';
import 'opening_track.dart';
import 'theme_cycle.dart';
import 'training_course.dart';
import 'training_plan.dart';

const _keepAnalyticsReminder = Object();

/// Provenance for reversible, pre-onboarding history only. No account identity.
/// Snapshot strings are immutable and cover only tracks created by bootstrap.
final class TrainingBootstrapImport {
  const TrainingBootstrapImport({
    required this.version,
    required this.completedOn,
    this.cycleJson,
    this.openingJson,
  });
  final String version, completedOn;
  final String? cycleJson, openingJson;
  Map<String, Object?> toJson() => {
    'version': version,
    'completedOn': completedOn,
    'cycleJson': cycleJson,
    'openingJson': openingJson,
  };
  factory TrainingBootstrapImport.fromJson(Map<String, dynamic> json) =>
      TrainingBootstrapImport(
        version: json['version'] as String,
        completedOn: json['completedOn'] as String,
        cycleJson: json['cycleJson'] as String?,
        openingJson: json['openingJson'] as String?,
      );
}

final class TrainingState {
  TrainingState({
    required this.course,
    required this.installSeed,
    this.plan = const TrainingPlan(),
    this.onboardingDone = false,
    this.tourSeen = false,
    this.tab = CourseGuideTab.lesson,
    this.openingProfile = 'solido',
    this.openingProfileStartPart = '',
    this.day,
    this.lastLessonDate,
    this.lastActivityAt,
    this.analyticsReminderAt,
    this.analyticsReminderShownAt,
    Map<String, String> completedLessons = const {},
    Map<String, ThemeCycle> cycles = const {},
    Map<String, OpeningTrack> openings = const {},
    Iterable<String> offDayCredits = const [],
    Iterable<TrainingGoal> deferredGoals = const [],
    SchoolTrainingProgress? school,
    TrainingAnalyticsState? analytics,
    Map<String, TrainingBootstrapImport> bootstrapImports = const {},
  }) : completedLessons = Map.unmodifiable(completedLessons),
       cycles = Map.unmodifiable(cycles),
       openings = Map.unmodifiable(openings),
       offDayCredits = List.unmodifiable(offDayCredits),
       deferredGoals = List.unmodifiable(deferredGoals),
       school = school ?? SchoolTrainingProgress(),
       analytics = analytics ?? TrainingAnalyticsState(),
       bootstrapImports = Map.unmodifiable(bootstrapImports);
  final TrainingCourse course;
  final String installSeed;
  final TrainingPlan plan;
  final bool onboardingDone, tourSeen;
  final CourseGuideTab tab;
  final String openingProfile;
  final String openingProfileStartPart;
  final DayGoals? day;
  final String? lastLessonDate;
  final DateTime? lastActivityAt;
  final DateTime? analyticsReminderAt, analyticsReminderShownAt;
  final Map<String, String> completedLessons;
  final Map<String, ThemeCycle> cycles;
  final Map<String, OpeningTrack> openings;
  final List<String> offDayCredits;

  /// Pending work retained through days off; never shown as today's goals.
  final List<TrainingGoal> deferredGoals;
  final SchoolTrainingProgress school;
  final TrainingAnalyticsState analytics;
  final Map<String, TrainingBootstrapImport> bootstrapImports;
  bool get mock => day?.goals.any((g) => g.mock) ?? false;
  TrainingState copyWith({
    String? openingProfile,
    String? openingProfileStartPart,
    TrainingPlan? plan,
    bool? onboardingDone,
    bool? tourSeen,
    CourseGuideTab? tab,
    DayGoals? day,
    String? lastLessonDate,
    DateTime? lastActivityAt,
    Object? analyticsReminderAt = _keepAnalyticsReminder,
    Object? analyticsReminderShownAt = _keepAnalyticsReminder,
    Map<String, String>? completedLessons,
    Map<String, ThemeCycle>? cycles,
    Map<String, OpeningTrack>? openings,
    Iterable<String>? offDayCredits,
    Iterable<TrainingGoal>? deferredGoals,
    SchoolTrainingProgress? school,
    TrainingAnalyticsState? analytics,
    Map<String, TrainingBootstrapImport>? bootstrapImports,
  }) => TrainingState(
    course: course,
    installSeed: installSeed,
    plan: plan ?? this.plan,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    tourSeen: tourSeen ?? this.tourSeen,
    tab: tab ?? this.tab,
    openingProfile: openingProfile ?? this.openingProfile,
    openingProfileStartPart:
        openingProfileStartPart ?? this.openingProfileStartPart,
    day: day ?? this.day,
    lastLessonDate: lastLessonDate ?? this.lastLessonDate,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    analyticsReminderAt: identical(analyticsReminderAt, _keepAnalyticsReminder)
        ? this.analyticsReminderAt
        : analyticsReminderAt as DateTime?,
    analyticsReminderShownAt:
        identical(analyticsReminderShownAt, _keepAnalyticsReminder)
        ? this.analyticsReminderShownAt
        : analyticsReminderShownAt as DateTime?,
    completedLessons: completedLessons ?? this.completedLessons,
    cycles: cycles ?? this.cycles,
    openings: openings ?? this.openings,
    offDayCredits: offDayCredits ?? this.offDayCredits,
    deferredGoals: deferredGoals ?? this.deferredGoals,
    school: school ?? this.school,
    analytics: analytics ?? this.analytics,
    bootstrapImports: bootstrapImports ?? this.bootstrapImports,
  );
  Map<String, Object?> toJson() => {
    'openingProfile': openingProfile,
    'openingProfileStartPart': openingProfileStartPart,
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
    'analyticsReminderAt': analyticsReminderAt?.toIso8601String(),
    'analyticsReminderShownAt': analyticsReminderShownAt?.toIso8601String(),
    'completedLessons': completedLessons,
    'cycles': cycles.map((k, v) => MapEntry(k, v.toJson())),
    'openings': openings.map((k, v) => MapEntry(k, v.toJson())),
    'offDayCredits': offDayCredits,
    'deferredGoals': deferredGoals.map((g) => g.toJson()).toList(),
    'school': school.toJson(),
    'analytics': analytics.toJson(),
    'bootstrapImports': bootstrapImports.map((k, v) => MapEntry(k, v.toJson())),
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
      openingProfile: j['openingProfile'] as String? ?? 'solido',
      openingProfileStartPart: j['openingProfileStartPart'] as String? ?? '',
      day: j['day'] == null
          ? null
          : DayGoals.fromJson(Map<String, dynamic>.from(j['day'] as Map)),
      lastLessonDate: j['lastLessonDate'] as String?,
      analyticsReminderAt: DateTime.tryParse(
        j['analyticsReminderAt'] as String? ?? '',
      ),
      analyticsReminderShownAt: DateTime.tryParse(
        j['analyticsReminderShownAt'] as String? ?? '',
      ),
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
      deferredGoals: (j['deferredGoals'] as List? ?? const []).map(
        (g) => TrainingGoal.fromJson(Map<String, dynamic>.from(g as Map)),
      ),
      analytics: TrainingAnalyticsState.fromJson(
        Map<String, dynamic>.from(j['analytics'] as Map? ?? const {}),
      ),
      school: SchoolTrainingProgress.fromJson(
        Map<String, dynamic>.from(j['school'] as Map? ?? const {}),
      ),
      bootstrapImports: (j['bootstrapImports'] as Map? ?? const {}).map(
        (k, v) => MapEntry(
          k as String,
          TrainingBootstrapImport.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
    );
  }
}
