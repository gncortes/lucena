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
  Future<void>? beforeResources;
  Object? writeError;

  /// Faz toda leitura do estado falhar, como um arquivo corrompido.
  Object? readError;
  int writes = 0;

  /// Gravações recusadas por [writeError] (para provar que não há laço).
  int failedWrites = 0;
  @override
  Stream<TrainingState> get changes => _changes.stream;
  TrainingState _read(TrainingCourse course) {
    if (readError case final error?) throw error;
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
  Future<TrainingResources> resources(TrainingCourse course) async {
    resourceReads++;
    await beforeResources;
    return content[course] ?? TrainingResources();
  }

  /// Quantas vezes a lista completa foi lida.
  int resourceReads = 0;

  /// A lista guardada da última abertura, por curso (nula: primeira vez).
  final Map<TrainingCourse, TrainingResources> outline = {};

  @override
  Future<TrainingResources?> cachedOutline(TrainingCourse course) async =>
      outline[course];

  @override
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  ) => transact(course, change);
  @override
  Future<TrainingState> transact(
    TrainingCourse course,
    FutureOr<TrainingState> Function(TrainingState) change,
  ) {
    final next = _pending.then((_) async {
      final before = _read(course);
      final state = await change(before);
      if (identical(before, state)) return before;
      if (state.course != course || state.installSeed != before.installSeed) {
        throw ArgumentError(
          'A transaction cannot change course or installation seed',
        );
      }
      if (writeError case final error?) {
        failedWrites++;
        throw error;
      }
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
