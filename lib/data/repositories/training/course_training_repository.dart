import 'dart:async';

import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';

abstract interface class TrainingRepository {
  Future<TrainingState> load(TrainingCourse course);
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  );
  Future<TrainingState> transact(
    TrainingCourse course,
    FutureOr<TrainingState> Function(TrainingState) change,
  );
  Future<TrainingResources> resources(TrainingCourse course);
  Stream<TrainingState> get changes;
}

/// Default for compositions that have not enabled course training.
final class NoTrainingRepository implements TrainingRepository {
  const NoTrainingRepository();
  @override
  Stream<TrainingState> get changes => const Stream.empty();
  @override
  Future<TrainingResources> resources(TrainingCourse course) async =>
      TrainingResources();
  @override
  Future<TrainingState> load(TrainingCourse course) async =>
      TrainingState(course: course, installSeed: 'disabled');
  @override
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  ) => Future.error(StateError('Course training is not configured'));
  @override
  Future<TrainingState> transact(
    TrainingCourse course,
    FutureOr<TrainingState> Function(TrainingState) change,
  ) async {
    final before = await load(course);
    final after = await change(before);
    if (identical(before, after)) return before;
    throw StateError('Course training is not configured');
  }
}
