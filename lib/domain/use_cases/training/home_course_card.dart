import '../../models/training/day_goals.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';

enum HomeCourseStatus { lesson, exercise, opening, challenge, done, dayOff }

enum HomeCourseDestination { lesson, exercise, trecho, challenge, lessonTab }

final class HomeCourseCard {
  const HomeCourseCard(this.status, this.destination, this.ref, {this.goal});
  final HomeCourseStatus status;
  final HomeCourseDestination destination;
  final String ref;
  final TrainingGoal? goal;
}

HomeCourseCard? homeCourseCard(
  TrainingState state,
  TrainingResources resources,
) {
  if (!state.onboardingDone || state.day == null) return null;
  final nextLesson = resources.lessons
      .where((l) => l.visible && !state.completedLessons.containsKey(l.id))
      .firstOrNull;
  final day = state.day!;
  if (!day.studyDay || day.allDone) {
    return nextLesson == null
        ? null
        : HomeCourseCard(
            day.studyDay ? HomeCourseStatus.done : HomeCourseStatus.dayOff,
            HomeCourseDestination.lessonTab,
            nextLesson.id,
          );
  }
  final goal = day.next!;
  return switch (goal.kind) {
    GoalKind.lesson || GoalKind.extraLesson || GoalKind.redo => HomeCourseCard(
      HomeCourseStatus.lesson,
      HomeCourseDestination.lesson,
      goal.ref,
      goal: goal,
    ),
    GoalKind.exercise || GoalKind.reinforce => HomeCourseCard(
      HomeCourseStatus.exercise,
      HomeCourseDestination.exercise,
      goal.ref,
      goal: goal,
    ),
    GoalKind.openings => HomeCourseCard(
      HomeCourseStatus.opening,
      HomeCourseDestination.trecho,
      goal.items.entries
          .firstWhere(
            (entry) =>
                state.openings[entry.key]?.doneTrechos[entry.value] != day.date,
          )
          .key,
      goal: goal,
    ),
    _ => HomeCourseCard(
      HomeCourseStatus.challenge,
      HomeCourseDestination.challenge,
      goal.ref,
      goal: goal,
    ),
  };
}

/// The last completed goal wins when both courses have been started.
TrainingState? latestTrainingCourse(Iterable<TrainingState> states) {
  final active = states.where((s) => s.onboardingDone).toList();
  active.sort((a, b) {
    final at = a.lastActivityAt, bt = b.lastActivityAt;
    if (at == null) {
      return bt == null ? a.course.index.compareTo(b.course.index) : 1;
    }
    return bt == null ? -1 : bt.compareTo(at);
  });
  return active.firstOrNull;
}
