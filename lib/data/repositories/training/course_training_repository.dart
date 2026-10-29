import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';

abstract interface class TrainingRepository {
  Future<TrainingState> load(TrainingCourse course);
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  );
  Future<TrainingResources> resources(TrainingCourse course);
  Stream<TrainingState> get changes;
}
