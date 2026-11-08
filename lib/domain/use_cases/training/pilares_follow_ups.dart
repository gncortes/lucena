import '../../models/training/day_goals.dart';
import '../../models/training/opening_track.dart';
import '../../models/training/theme_cycle.dart';
import '../../models/training/training_content.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'exercise_picker.dart';
import 'opening_trecho_rules.dart';
import 'training_date.dart';
import 'opening_parts.dart';

final class PilaresFollowUps implements TrainingFollowUps {
  const PilaresFollowUps();

  TrainingExercise? _nextExercise(
    ThemeCycle cycle,
    TrainingResources resources,
    String seed,
  ) {
    final bank = resources.banks[cycle.lessonId] ?? [];
    if (cycle.phase == ThemePhase.reinforce) {
      final seen = cycle.reinforceDays.map((d) => d.exerciseId).toSet();
      for (final id in cycle.reinforcement.where((id) => !seen.contains(id))) {
        final item = bank.where((e) => e.id == id).firstOrNull;
        if (item != null) return item;
      }
      return null;
    }
    if (cycle.phase != ThemePhase.cycle) return null;
    return const ExercisePicker()(bank: bank, cycle: cycle, installSeed: seed);
  }

  @override
  TrainingState reconcile(
    TrainingState state,
    TrainingResources resources,
    Now now,
  ) {
    final cycles = {...state.cycles};
    final converted = <String>{};
    for (final cycle in state.cycles.values) {
      if ((cycle.phase == ThemePhase.cycle ||
              cycle.phase == ThemePhase.reinforce) &&
          _nextExercise(cycle, resources, state.installSeed) == null) {
        // Missing content is not evidence of mastery. Keep attempts and the
        // frozen bank until the existing redo action starts a new cycle.
        cycles[cycle.lessonId] = cycle.copyWith(phase: ThemePhase.redo);
        converted.add(cycle.lessonId);
      }
    }
    var changed = converted.isNotEmpty;
    TrainingGoal reconcileGoal(TrainingGoal goal) {
      final cycle = cycles[goal.ref];
      if (goal.done ||
          (goal.kind != GoalKind.exercise && goal.kind != GoalKind.reinforce) ||
          cycle == null) {
        return goal;
      }
      if (cycle.phase == ThemePhase.redo) {
        changed = true;
        return TrainingGoal(kind: GoalKind.redo, ref: goal.ref);
      }
      if (resources.banks[goal.ref]?.any((item) => item.id == goal.itemId) ??
          false) {
        return goal;
      }
      final item = _nextExercise(cycle, resources, state.installSeed);
      if (item == null) return goal;
      changed = true;
      return TrainingGoal(
        kind: goal.kind,
        ref: goal.ref,
        itemId: item.id,
        stars: item.stars,
        mock: item.mock,
      );
    }

    final deferred = state.deferredGoals.map(reconcileGoal).toList();
    final day = state.day;
    final goals = day?.goals.map(reconcileGoal).toList() ?? <TrainingGoal>[];
    if (day?.date == trainingDate(now()) && day!.studyDay) {
      for (final id in converted) {
        if (cycles[id]!.startedOn.compareTo(day.date) < 0 &&
            resources.lessons.any((l) => l.id == id && l.visible) &&
            !goals.any(
              (g) =>
                  g.ref == id &&
                  (g.kind == GoalKind.exercise ||
                      g.kind == GoalKind.reinforce ||
                      g.kind == GoalKind.redo),
            )) {
          goals.add(TrainingGoal(kind: GoalKind.redo, ref: id));
        }
      }
      // Moving a deferred exercise into today's redo consumes that queue entry.
      final redoKeys = goals
          .where((goal) => goal.kind == GoalKind.redo)
          .map((goal) => goal.key)
          .toSet();
      final before = deferred.length;
      deferred.removeWhere((goal) => !goal.done && redoKeys.contains(goal.key));
      changed |= deferred.length != before;
    }
    return changed
        ? state.copyWith(
            cycles: cycles,
            day: day?.copyWith(goals: goals),
            deferredGoals: deferred,
          )
        : state;
  }

  @override
  TrainingState lessonCompleted(
    TrainingState state,
    TrainingLesson lesson,
    String date,
  ) {
    return switch (lesson.kind) {
      TrainingLessonKind.theme => state.copyWith(
        cycles: {
          ...state.cycles,
          lesson.id: ThemeCycle(lessonId: lesson.id, startedOn: date),
        },
      ),
      TrainingLessonKind.opening =>
        state.openings.keys.any(
              (id) =>
                  id == lesson.id ||
                  openingProfileForLesson(lesson.id) != null &&
                      id.split('.').last.replaceAll(RegExp(r'\d+$'), '') ==
                          lesson.id
                              .split('.')
                              .last
                              .replaceAll(RegExp(r'\d+$'), ''),
            )
            ? state
            : state.copyWith(
                openings: {
                  ...state.openings,
                  lesson.id: OpeningTrack(lessonId: lesson.id, startedOn: date),
                },
              ),
      _ => state,
    };
  }

  @override
  List<TrainingGoal> build(
    TrainingState state,
    TrainingResources resources,
    Now now,
  ) {
    final date = trainingDate(now());
    final reinforce = <TrainingGoal>[], exercises = <TrainingGoal>[];
    for (final lesson in resources.lessons.where((l) => l.visible)) {
      final cycle = state.cycles[lesson.id];
      if (cycle == null || cycle.startedOn.compareTo(date) >= 0) continue;
      final bank = resources.banks[lesson.id];
      if (cycle.phase == ThemePhase.redo) {
        reinforce.add(TrainingGoal(kind: GoalKind.redo, ref: lesson.id));
      } else if (bank != null && bank.isNotEmpty) {
        final item = _nextExercise(cycle, resources, state.installSeed);
        if (item != null) {
          final kind = cycle.phase == ThemePhase.reinforce
              ? GoalKind.reinforce
              : GoalKind.exercise;
          final pending = [...?state.day?.goals, ...state.deferredGoals]
              .where(
                (g) =>
                    !g.done &&
                    g.kind == kind &&
                    g.ref == lesson.id &&
                    g.itemId == item.id,
              )
              .firstOrNull;
          final goal = TrainingGoal(
            kind: kind,
            ref: lesson.id,
            itemId: item.id,
            stars: item.stars,
            mock: item.mock,
            hintUsed: pending?.hintUsed ?? false,
          );
          (cycle.phase == ThemePhase.reinforce ? reinforce : exercises).add(
            goal,
          );
        }
      }
    }
    final segments = <String, String>{};
    var mock = false;
    final rules = OpeningTrechoRules(now);
    for (final entry in activeOpeningTracks(state, resources)) {
      final lessonId = entry.key;
      final track = entry.value;
      if (track.startedOn.compareTo(date) >= 0) continue;
      final next = rules.next(track, resources.openings[lessonId] ?? []);
      if (next != null) {
        segments[lessonId] = next.id;
        mock |= next.mock;
      }
    }
    return [
      ...reinforce,
      ...exercises,
      if (segments.isNotEmpty)
        TrainingGoal(
          kind: GoalKind.openings,
          ref: 'openings',
          items: segments,
          mock: mock,
        ),
    ];
  }
}
