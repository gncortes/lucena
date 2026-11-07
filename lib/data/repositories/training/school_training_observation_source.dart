import '../../../domain/models/training/school_training_observations.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/speedrun_score.dart';
import '../journey/journey_repository.dart';
import '../progress/progress_repository.dart';
import '../school/star_challenge_repository.dart';
import '../speedrun/speedrun_repository.dart';

/// Reads dated source records only. The follow-up use case decides qualification.
final class SchoolTrainingObservationSource {
  const SchoolTrainingObservationSource({
    required this.now,
    required this.stars,
    required this.progress,
    required this.speedruns,
    required this.journey,
  });
  final Now now;
  final StarChallengeRepository stars;
  final ProgressRepository progress;
  final SpeedrunRepository speedruns;
  final JourneyRepository journey;

  Future<SchoolTrainingObservations> read(TrainingState state) async {
    final at = now().toLocal();
    final midnight = DateTime(at.year, at.month, at.day);
    final runs = await stars.runsSince(midnight);
    final bots = <SchoolBotWin>[];
    final finishes = <SchoolSpeedrunFinish>[];
    for (final goal in state.day?.goals ?? []) {
      if (goal.done) continue;
      if (goal.kind == GoalKind.bot && goal.itemId != null) {
        final rung = goal.items['rung'];
        if (rung == null) continue;
        for (final attempt in await progress.attemptsForChallenge(
          '$rung/${goal.itemId}',
        )) {
          if (attempt.fulfilled && attempt.positionId == goal.itemId) {
            bots.add(
              SchoolBotWin(
                positionId: attempt.positionId,
                rung: rung,
                at: attempt.playedAt,
              ),
            );
          }
        }
      } else if (goal.kind == GoalKind.speedrun && goal.itemId != null) {
        final definition = (await journey.speedruns())
            .where((s) => s.id == goal.itemId)
            .firstOrNull;
        if (definition == null) continue;
        for (final attempt in await speedruns.attempts(goal.itemId!)) {
          final run = SpeedrunScore.run(definition, attempt);
          // An opened or abandoned-empty attempt is a visit, not a played run.
          if (run.inProgress || attempt.games.isEmpty) continue;
          final finishedAt = run.finishedAt ?? attempt.abandonedAt;
          if (finishedAt != null) {
            finishes.add(
              SchoolSpeedrunFinish(id: goal.itemId!, at: finishedAt),
            );
          }
        }
      }
    }
    return SchoolTrainingObservations(
      starRuns: runs,
      botWins: bots,
      speedruns: finishes,
    );
  }
}
