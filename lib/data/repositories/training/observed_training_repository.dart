import 'dart:async';

import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import 'course_training_repository.dart';

typedef TrainingObserver = Future<TrainingState> Function(
  TrainingState state,
  TrainingResources resources,
);

/// Observations and the requested command share the underlying durable queue.
/// A goal unlocked by the command can consume an earlier qualifying run today.
final class ObservedTrainingRepository implements TrainingRepository {
  ObservedTrainingRepository(
    this.inner, {
    Map<TrainingCourse, TrainingObserver> observers = const {},
  }) : observers = Map.unmodifiable(observers);
  final TrainingRepository inner;
  final Map<TrainingCourse, TrainingObserver> observers;
  @override
  Stream<TrainingState> get changes => inner.changes;
  @override
  Future<TrainingResources> resources(TrainingCourse course) =>
      inner.resources(course);
  @override
  Future<TrainingState> load(TrainingCourse course) =>
      observers.containsKey(course)
      ? transact(course, (s) => s)
      : inner.load(course);
  @override
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  ) => transact(course, change);
  @override
  Future<TrainingState> transact(
    TrainingCourse course,
    FutureOr<TrainingState> Function(TrainingState) change,
  ) => inner.transact(course, (before) async {
    final observer = observers[course];
    TrainingResources? data;
    Future<TrainingState> observe(TrainingState state) async {
      if (!state.onboardingDone || observer == null) return state;
      data ??= await resources(course);
      final observed = await observer(state, data!);
      if (observed.course != state.course ||
          observed.installSeed != state.installSeed) {
        throw StateError('Observation changed training identity');
      }
      return observed;
    }

    final observed = await observe(before);
    return observe(await change(observed));
  });
}
