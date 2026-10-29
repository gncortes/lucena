import '../../models/training/day_goals.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'training_date.dart';
import 'opening_trecho_rules.dart';

final class BuildDayGoals {
  const BuildDayGoals(this.now, this.config);
  final Now now;
  final TrainingCourseConfig config;

  TrainingState call(TrainingState state, TrainingResources resources) {
    final at = now();
    final date = trainingDate(at);
    if (state.day?.date == date) {
      return _reconcileScriptedOpenings(state, resources);
    }
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

  /// A private content refresh can replace legacy IDs during a frozen day.
  /// Only missing pending segments migrate; the calendar and stored history stay.
  TrainingState _reconcileScriptedOpenings(
    TrainingState state,
    TrainingResources resources,
  ) {
    final day = state.day!;
    var changed = false;
    final goals = <TrainingGoal>[];
    for (final goal in day.goals) {
      if (goal.kind != GoalKind.openings || goal.done) {
        goals.add(goal);
        continue;
      }
      final items = Map<String, String>.of(goal.items);
      var replaced = false;
      for (final entry in goal.items.entries) {
        final bank = resources.openings[entry.key];
        final track = state.openings[entry.key];
        if (bank == null ||
            track == null ||
            !bank.any((item) => item.script != null && !item.mock) ||
            bank.any((item) => item.id == entry.value)) {
          continue;
        }
        // Completing any old segment today already consumed this opening's slot.
        final completedToday = track.doneTrechos.entries
            .where((done) => done.value == day.date)
            .firstOrNull;
        final id =
            completedToday?.key ??
            OpeningTrechoRules(now).next(track, bank)?.id;
        if (id != null && id != entry.value) {
          items[entry.key] = id;
          replaced = true;
        }
      }
      if (!replaced) {
        goals.add(goal);
        continue;
      }
      changed = true;
      goals.add(
        TrainingGoal(
          kind: goal.kind,
          ref: goal.ref,
          itemId: goal.itemId,
          stars: goal.stars,
          hintUsed: goal.hintUsed,
          exerciseError: goal.exerciseError,
          items: items,
          done: items.entries.every(
            (entry) =>
                state.openings[entry.key]?.doneTrechos[entry.value] == day.date,
          ),
          mock: items.entries.any(
            (entry) =>
                resources.openings[entry.key]?.any(
                  (item) => item.id == entry.value && item.mock,
                ) ??
                false,
          ),
        ),
      );
    }
    return changed ? state.copyWith(day: day.copyWith(goals: goals)) : state;
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
