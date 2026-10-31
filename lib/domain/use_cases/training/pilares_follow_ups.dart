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
        TrainingExercise? item;
        if (cycle.phase == ThemePhase.reinforce) {
          final seen = cycle.reinforceDays.map((d) => d.exerciseId).toSet();
          final id = cycle.reinforcement
              .where((id) => !seen.contains(id))
              .firstOrNull;
          item = bank.where((e) => e.id == id).firstOrNull;
        } else if (cycle.phase == ThemePhase.cycle) {
          item = const ExercisePicker()(
            bank: bank,
            cycle: cycle,
            installSeed: state.installSeed,
          );
        }
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
                    g.itemId == item!.id,
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
