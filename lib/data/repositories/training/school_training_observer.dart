import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/star_challenge_rules.dart';
import '../../../domain/use_cases/training/build_day_goals.dart';
import '../../../domain/use_cases/training/reconcile_school_training.dart';
import '../../../domain/use_cases/training/training_analytics.dart';
import '../../../domain/use_cases/training/training_date.dart';
import 'school_training_observation_source.dart';

/// Shared production/E2E composition. Authoritative source records determine
/// completion; telemetry is attached to the same durable training write.
final class SchoolTrainingObserver {
  const SchoolTrainingObserver({
    required this.now,
    required this.source,
    this.analytics,
  });
  final Now now;
  final SchoolTrainingObservationSource source;
  final TrainingAnalytics? analytics;

  Future<TrainingState> call(
    TrainingState state,
    TrainingResources resources,
  ) async {
    final today = BuildDayGoals(now, TrainingCourseConfig.escola)(
      state,
      resources,
    );
    final observations = await source.read(today);
    await analytics?.restore(state.course, state: state);
    final result = ReconcileSchoolTraining(now)(today, resources, observations);
    if (identical(result, today)) return result;
    for (final goal in result.day!.goals) {
      if (!goal.done ||
          today.day!.goals.any((g) => g.key == goal.key && g.done)) {
        continue;
      }
      int? points;
      if (goal.kind == GoalKind.stars) {
        final qualifying =
            observations.starRuns
                .where(
                  (r) =>
                      'pieces.${r.piece.name}' == goal.ref &&
                      r.level.name == goal.itemId &&
                      trainingDate(r.at.toLocal()) == result.day!.date &&
                      !r.at.isAfter(now()) &&
                      StarChallengeRules.earned(r.level, r.points) ==
                          r.level.stars,
                )
                .toList()
              ..sort((a, b) => a.at.compareTo(b.at));
        points = qualifying.firstOrNull?.points;
      }
      analytics?.result(state.course, goal.key, correct: true, points: points);
    }
    return analytics?.attach(result) ?? result;
  }
}
