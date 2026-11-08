import '../../models/star_challenge.dart';
import '../../models/training/day_goals.dart';
import '../../models/training/school_training_observations.dart';
import '../../models/training/school_training_progress.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import '../star_challenge_rules.dart';
import 'training_date.dart';

/// Reconciles only frozen goals with today's authoritative source observations.
/// Earlier play on the same civil day can qualify once a lesson unlocks a goal.
final class ReconcileSchoolTraining {
  const ReconcileSchoolTraining(this.now);
  final Now now;
  TrainingState call(
    TrainingState state,
    TrainingResources resources,
    SchoolTrainingObservations observations,
  ) {
    final at = now();
    final date = trainingDate(at.toLocal());
    final day = state.day;
    if (state.course != TrainingCourse.escola ||
        day == null ||
        day.date != date ||
        !day.studyDay) {
      return state;
    }
    final visible = resources.lessons
        .where((l) => l.visible)
        .map((l) => l.id)
        .toSet();
    final levels = {...state.school.pieceLevels};
    final advanced = {...state.school.pieceAdvancedOn};
    final bots = {...state.school.botsCompletedOn};
    var speedrun = state.school.speedrunCompletedOn;
    var changed = false;
    bool today(DateTime value) =>
        trainingDate(value.toLocal()) == date && !value.isAfter(at);
    final goals = <TrainingGoal>[];
    for (final goal in day.goals) {
      var done = false;
      if (!goal.done &&
          goal.kind == GoalKind.stars &&
          visible.contains(goal.ref) &&
          state.completedLessons.containsKey(goal.ref)) {
        final piece = ChallengePiece.byName(
          goal.ref.replaceFirst('pieces.', ''),
        );
        final level = ChallengeLevel.byName(goal.itemId ?? '');
        if (piece != null &&
            level != null &&
            level != ChallengeLevel.named &&
            advanced[piece.name] != date &&
            (levels[piece.name] ?? 0) == level.index) {
          done = observations.starRuns.any(
            (r) =>
                today(r.at) &&
                r.piece == piece &&
                r.level == level &&
                StarChallengeRules.earned(level, r.points) == level.stars,
          );
          if (done) {
            levels[piece.name] = level.stars;
            advanced[piece.name] = date;
          }
        }
      } else if (!goal.done &&
          goal.kind == GoalKind.bot &&
          visible.contains(goal.ref) &&
          state.completedLessons.containsKey(goal.ref)) {
        done = observations.botWins.any(
          (r) => today(r.at) && r.positionId == goal.itemId && r.rung == '1000',
        );
        if (done) bots[goal.ref] = date;
      } else if (!goal.done && goal.kind == GoalKind.speedrun) {
        final mates = resources.lessons
            .where((l) => l.visible && l.groupId == 'firstMates')
            .toList();
        done =
            mates.isNotEmpty &&
            mates.every((l) => state.completedLessons.containsKey(l.id)) &&
            observations.speedruns.any(
              (r) => today(r.at) && r.id == 'journey.mates',
            );
        if (done) speedrun = date;
      }
      changed |= done;
      goals.add(done ? goal.complete() : goal);
    }
    if (!changed) return state;
    return state.copyWith(
      day: day.copyWith(goals: goals),
      lastActivityAt: at,
      school: SchoolTrainingProgress(
        pieceLevels: levels,
        pieceAdvancedOn: advanced,
        botsCompletedOn: bots,
        speedrunCompletedOn: speedrun,
        speedrunOriginLesson: state.school.speedrunOriginLesson,
      ),
    );
  }
}
