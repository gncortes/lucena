import '../../use_cases/now.dart';
import '../../use_cases/training/pilares_follow_ups.dart';
import 'day_goals.dart';
import 'training_content.dart';
import 'training_course.dart';
import 'training_resources.dart';
import 'training_state.dart';

abstract interface class TrainingFollowUps {
  List<TrainingGoal> build(
    TrainingState state,
    TrainingResources resources,
    Now now,
  );
  TrainingState lessonCompleted(
    TrainingState state,
    TrainingLesson lesson,
    String date,
  );
}

typedef TrainingPlanOption = ({int minutes, int lessonsPerDay});

/// All course variation lives here or in its follow-up strategy. Views share this
/// contract and do not branch on TrainingCourse.
final class TrainingCourseConfig {
  const TrainingCourseConfig({
    required this.course,
    required this.indexSource,
    required this.planOptions,
    required this.followUps,
    required this.sections,
    this.defaultMinutes = 30,
    this.titleKey = 'trainingPilaresTitle',
    this.lessonMinutes = 30,
    this.hasHelp = true,
    this.hasLevelTest = false,
    this.doubleRequiresExtraLesson = true,
    this.firstInfoKey = 'trainingFirstInfo',
    this.doubleOfferBodyKey = 'trainingDoubleOfferBody',
    this.dayOffInfoKey = 'trainingDayOffInfo',
    this.allDoneSpeechKey = 'trainingAllDoneViktor',
    this.progressKind = TrainingProgressKind.mastery,
    this.tipsKeys = const [],
    this.welcomeKeys = const [],
    this.planLabelKeys = const {
      15: 'trainingPlanTime15',
      30: 'trainingPlanTime30',
      60: 'trainingPlanTime60',
      120: 'trainingPlanTime120',
      240: 'trainingPlanTime240',
    },
    this.planRecommendationKeys = const {
      15: 'trainingPlanReco15',
      30: 'trainingPlanReco30',
      60: 'trainingPlanReco60',
      120: 'trainingPlanReco120',
      240: 'trainingPlanReco240',
    },
    this.planExtraRecommendationKeys = const {240: 'trainingPlanRecoMore'},
  });
  final TrainingCourse course;
  final String indexSource;
  final String titleKey;
  final List<TrainingPlanOption> planOptions;
  final TrainingFollowUps followUps;
  final List<GoalSection> sections;
  final int defaultMinutes, lessonMinutes;
  final bool hasHelp;
  final bool hasLevelTest;
  final bool doubleRequiresExtraLesson;
  final String firstInfoKey,
      doubleOfferBodyKey,
      dayOffInfoKey,
      allDoneSpeechKey;
  final TrainingProgressKind progressKind;
  final List<String> tipsKeys, welcomeKeys;
  final Map<int, String> planLabelKeys, planRecommendationKeys;
  final Map<int, String> planExtraRecommendationKeys;
  TrainingPlanOption option(int minutes) =>
      planOptions.firstWhere((o) => o.minutes == minutes);
  static const pilares = TrainingCourseConfig(
    course: TrainingCourse.pilares,
    hasLevelTest: true,
    indexSource: 'assets/courses/pilares/index.json',
    followUps: PilaresFollowUps(),
    planOptions: [
      (minutes: 15, lessonsPerDay: 0),
      (minutes: 30, lessonsPerDay: 1),
      (minutes: 60, lessonsPerDay: 1),
      (minutes: 120, lessonsPerDay: 1),
      (minutes: 240, lessonsPerDay: 2),
    ],
    sections: [
      GoalSection.lessons,
      GoalSection.reinforce,
      GoalSection.exercises,
      GoalSection.openings,
    ],
    tipsKeys: [
      'courseGuideTips1',
      'courseGuideTips2',
      'courseGuideTips3',
      'courseGuideTips4',
    ],
    welcomeKeys: ['courseGuideWelcomeTitle', 'courseGuideWelcomeBody'],
  );
}
