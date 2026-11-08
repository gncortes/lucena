import '../../models/training/day_goals.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'goal/plan_status.dart';
import 'goal_minutes.dart';
import 'training_date.dart';
import 'opening_trecho_rules.dart';

final class BuildDayGoals {
  const BuildDayGoals(this.now, this.config);
  final Now now;
  final TrainingCourseConfig config;

  TrainingState call(TrainingState state, TrainingResources resources) {
    state = config.followUps.reconcile(state, resources, now);
    final at = now();
    final date = trainingDate(at);
    if (state.day?.date == date) {
      return _reconcileScriptedOpenings(
        _completeMissingLessons(state, resources, at),
        resources,
      );
    }
    // Treino por meta: o dia que fecha todas as metas conta como estudado.
    final closing = state.day;
    if (closing != null &&
        closing.allDone &&
        !state.studiedDates.contains(closing.date)) {
      state = state.copyWith(
        studiedDates: [...state.studiedDates, closing.date],
      );
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
        // A lição que o acesso não abre (demo) não volta como meta.
        .where((g) => !resources.lockedLessons.contains(g.ref))
        .toList();
    // Pending lessons retain their place without accumulating a missed day's quota.
    lessons.addAll(pending);
    lessons.addAll(_courseLessons(state, resources, date, quota, lessons));
    final followUps = config.followUps.build(state, resources, now);
    if (quota > 0) {
      lessons.addAll(
        _lessonsToFillPlan(state, resources, date, lessons, followUps),
      );
    }
    final hasLesson = lessons.isNotEmpty;
    return state.copyWith(
      day: DayGoals(
        date: date,
        plan: state.plan,
        studyDay: true,
        goals: [...lessons, ...followUps],
        lessonsLocked: resources.lockedLessons.isNotEmpty,
      ),
      lastLessonDate: hasLesson ? date : null,
      offDayCredits: [],
      deferredGoals: [],
    );
  }

  /// Dia sem exercício nem abertura (os primeiros dias de curso, em que nenhum
  /// tema tem ciclo ainda): a lição da cota sozinha vale menos que o plano
  /// (15 min contra 30), então entra mais uma lição, na ordem do curso, para o
  /// dia só fechar com o tempo do plano. Com exercícios no dia, o plano é
  /// "uma lição nova por dia, mais os exercícios" e nada entra. Só vale para o
  /// curso com [TrainingCourseConfig.fillsPlanMinutes].
  List<TrainingGoal> _lessonsToFillPlan(
    TrainingState state,
    TrainingResources resources,
    String date,
    List<TrainingGoal> lessons,
    List<TrainingGoal> followUps,
  ) {
    if (!config.fillsPlanMinutes || followUps.isNotEmpty) return const [];
    final total = GoalMinutes(config).ofGoals(lessons);
    if (total >= state.plan.minutes) return const [];
    return _courseLessons(state, resources, date, lessons.length + 1, lessons);
  }

  /// The next lessons in course order, up to [quota] counting [taken].
  List<TrainingGoal> _courseLessons(
    TrainingState state,
    TrainingResources resources,
    String date,
    int quota,
    List<TrainingGoal> taken,
  ) {
    final added = <TrainingGoal>[];
    final reserved = taken.map((g) => g.ref).toSet();
    final byId = {for (final l in resources.lessons) l.id: l};
    final ordered = [
      for (final id in lessonOrderForPlan(state, resources, date))
        if (byId[id] case final l? when l.visible || !l.published) l,
    ];
    for (final lesson in ordered) {
      if (!lesson.inCourseOrder) continue;
      if (!lesson.published) break;
      if (quota == 0 || taken.length + added.length >= quota) break;
      if (state.completedLessons.containsKey(lesson.id) ||
          reserved.contains(lesson.id) ||
          resources.lockedLessons.contains(lesson.id)) {
        continue;
      }
      added.add(TrainingGoal(kind: GoalKind.lesson, ref: lesson.id));
      reserved.add(lesson.id);
    }
    return added;
  }

  /// O dia que nasceu com lições trancadas (demo do Pilares) e sem lição
  /// ganha a lição quando o acesso abre no meio do dia (compra ou
  /// restauração). O que já foi feito hoje fica; só a lição entra.
  TrainingState _completeMissingLessons(
    TrainingState state,
    TrainingResources resources,
    DateTime at,
  ) {
    final day = state.day!;
    if (!day.lessonsLocked || resources.lockedLessons.isNotEmpty) return state;
    // O acesso abriu: o dia deixa de ser da demo, com ou sem lição nova.
    final opened = state.copyWith(day: day.copyWith(lessonsLocked: false));
    if (!day.studyDay ||
        day.goals.any(
          (g) => g.kind == GoalKind.lesson || g.kind == GoalKind.extraLesson,
        ) ||
        state.lastLessonDate == day.date) {
      return opened;
    }
    final added = _courseLessons(
      state,
      resources,
      day.date,
      lessonsDue(state, at),
      const [],
    );
    if (added.isEmpty) return opened;
    return opened.copyWith(
      day: opened.day!.copyWith(goals: [...added, ...day.goals]),
      lastLessonDate: day.date,
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
            !bank.any(
              (item) =>
                  (item.script != null || item.lines.isNotEmpty) && !item.mock,
            ) ||
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
