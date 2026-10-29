import '../../models/training/day_goals.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'training_date.dart';

final class BuildDayGoals {
  const BuildDayGoals(this.now, this.config);
  final Now now;
  final TrainingCourseConfig config;

  TrainingState call(TrainingState state, TrainingResources resources) {
    final at = now();
    final date = trainingDate(at);
    if (state.day?.date == date) return state;
    final pendingGoals = <String, TrainingGoal>{
      for (final goal in [...state.deferredGoals, ...?state.day?.goals])
        if (!goal.done) goal.key: goal,
    }.values;
    if (!state.plan.studiesOn(at)) {
      return state.copyWith(
        day: DayGoals(date: date, studyDay: false, plan: state.plan),
        deferredGoals: pendingGoals,
      );
    }
    final quota = lessonsDue(state, at);
    final credits = state.offDayCredits;
    final lessons = <TrainingGoal>[
      for (final id in credits)
        TrainingGoal(kind: GoalKind.lesson, ref: id, done: true),
    ];
    final pending = pendingGoals
        .where((g) => !g.done && g.kind == GoalKind.lesson)
        .where((g) => !state.completedLessons.containsKey(g.ref))
        .toList();
    // Pending lessons retain their place without accumulating a missed day's quota.
    lessons.addAll(pending);
    final reserved = lessons.map((g) => g.ref).toSet();
    for (final lesson in resources.lessons.where((l) => l.visible)) {
      if (quota == 0 || lessons.length >= quota) break;
      if (state.completedLessons.containsKey(lesson.id) ||
          reserved.contains(lesson.id)) {
        continue;
      }
      lessons.add(TrainingGoal(kind: GoalKind.lesson, ref: lesson.id));
      reserved.add(lesson.id);
    }
    final hasLesson = lessons.isNotEmpty;
    return state.copyWith(
      day: DayGoals(
        date: date,
        plan: state.plan,
        studyDay: true,
        goals: [...lessons, ...config.followUps.build(state, resources, now)],
      ),
      lastLessonDate: hasLesson ? date : null,
      offDayCredits: [],
      deferredGoals: [],
    );
  }

  int lessonsDue(TrainingState state, DateTime at) {
    final option = config.option(state.plan.minutes);
    if (option.lessonsPerDay > 0) return option.lessonsPerDay;
    if (state.lastLessonDate == null) return 1;
    var cursor = civilDate(state.lastLessonDate!);
    var studies = 0;
    final today = trainingDate(at);
    // Construct civil midnights instead of adding 24 hours across DST.
    while (trainingDate(cursor).compareTo(today) < 0) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
      if (state.plan.studiesOn(cursor)) studies++;
    }
    return studies >= 2 ? 1 : 0;
  }
}
