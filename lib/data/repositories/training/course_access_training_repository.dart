import 'dart:async';

import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/demo_goals.dart';
import '../lesson_ad/course_access_repository.dart';
import 'course_training_repository.dart';

/// O conteúdo do treino com o acesso de hoje: na demonstração do Pilares, as
/// lições de fora do Capítulo 1 chegam trancadas e a meta do dia as pula.
final class CourseAccessTrainingRepository implements TrainingRepository {
  CourseAccessTrainingRepository(this.inner, this.access);
  final TrainingRepository inner;
  final CourseAccessRepository access;

  @override
  Stream<TrainingState> get changes => inner.changes;
  @override
  Future<TrainingResources> resources(TrainingCourse course) async =>
      DemoGoals.forAccess(course, access.access, await inner.resources(course));
  @override
  Future<TrainingResources?> cachedOutline(TrainingCourse course) async {
    final cached = await inner.cachedOutline(course);
    return cached == null
        ? null
        : DemoGoals.forAccess(course, access.access, cached);
  }

  @override
  Future<TrainingState> load(TrainingCourse course) => inner.load(course);
  @override
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  ) => inner.update(course, change);
  @override
  Future<TrainingState> transact(
    TrainingCourse course,
    FutureOr<TrainingState> Function(TrainingState) change,
  ) => inner.transact(course, change);
}
