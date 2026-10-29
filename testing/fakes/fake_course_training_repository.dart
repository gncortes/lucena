import 'dart:async';
import 'dart:convert';

import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';

final class FakeTrainingRepository implements TrainingRepository {
  FakeTrainingRepository({
    Map<TrainingCourse, TrainingState> states = const {},
    Map<TrainingCourse, TrainingResources> content = const {},
  }) : content = Map.of(content) {
    for (final entry in states.entries) {
      saved[entry.key] = jsonEncode(entry.value.toJson());
    }
  }
  final Map<TrainingCourse, String> saved = {};
  final Map<TrainingCourse, TrainingResources> content;
  final _changes = StreamController<TrainingState>.broadcast();
  Future<void> _pending = Future.value();
  Future<void>? beforeSave;
  Object? writeError;
  int writes = 0;
  @override
  Stream<TrainingState> get changes => _changes.stream;
  TrainingState _read(TrainingCourse course) {
    final raw = saved[course];
    return raw == null
        ? TrainingState(course: course, installSeed: 'fake-installation')
        : TrainingState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<TrainingState> load(TrainingCourse course) async {
    await _pending;
    return _read(course);
  }

  @override
  Future<TrainingResources> resources(TrainingCourse course) async =>
      content[course] ?? TrainingResources();
  @override
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  ) {
    final next = _pending.then((_) async {
      final before = _read(course);
      final state = change(before);
      if (identical(before, state)) return before;
      if (writeError case final error?) throw error;
      await beforeSave;
      saved[course] = jsonEncode(state.toJson());
      writes++;
      _changes.add(state);
      return state;
    });
    _pending = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<void> dispose() => _changes.close();
}
