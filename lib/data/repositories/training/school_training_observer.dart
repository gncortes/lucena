import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/build_day_goals.dart';
import '../../../domain/use_cases/training/reconcile_school_training.dart';
import 'school_training_observation_source.dart';

/// Source observations are reconciled inside the repository's durable queue.
final class SchoolTrainingObserver {
  const SchoolTrainingObserver({required this.now, required this.source});
  final Now now;
  final SchoolTrainingObservationSource source;
  Future<TrainingState> call(
    TrainingState state,
    TrainingResources resources,
  ) async {
    final today = BuildDayGoals(now, TrainingCourseConfig.escola)(
      state,
      resources,
    );
    return ReconcileSchoolTraining(now)(
      today,
      resources,
      await source.read(today),
    );
  }
}
