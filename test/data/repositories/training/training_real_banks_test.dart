@Tags(['private-content'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/play_training_exercise.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'training_repository_test.dart' show MemoryPreferences;

class _LocalTrainingContent extends LessonContentReader {
  @override
  Future<String> read(String path) async {
    final file = File(path);
    if (!await file.exists()) throw const LessonContentNotFound();
    return file.readAsString();
  }
}

void main() {
  test(
    'all current real banks are playable through the production reader',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repository = TrainingRepositoryLocal(
        MemoryPreferences(),
        LessonContentAssets(reader: _LocalTrainingContent()),
        installSeed: 'private-content-test',
      );
      addTearDown(repository.dispose);
      final resources = await repository.resources(TrainingCourse.pilares);
      expect(resources.banks, hasLength(63));
      final exercises = resources.banks.values.expand((bank) => bank).toList();
      expect(exercises, hasLength(882));
      expect(exercises.where((exercise) => exercise.mock), isEmpty);
      expect(resources.errorFeedback, contains('pilares.c1.knightFork'));
      expect(resources.errorFeedback['pilares.c1.knightFork'], hasLength(64));
      var laterAlternatives = 0;
      for (final exercise in exercises) {
        final rules = PlayTrainingExercise(exercise);
        var fen = exercise.fen;
        var cursor = 0;
        while (cursor < exercise.solution.length) {
          for (final alternative in exercise.alternativesAt(cursor)) {
            final accepted = rules.play(fen, cursor, alternative);
            expect(accepted.correct, true, reason: exercise.id);
            expect(accepted.done, true, reason: exercise.id);
            if (cursor > 0) laterAlternatives++;
          }
          final step = rules.play(fen, cursor, exercise.solution[cursor]);
          expect(step.correct, true, reason: exercise.id);
          fen = step.fen;
          cursor = step.cursor;
          if (step.done) break;
        }
      }
      expect(laterAlternatives, 14);
    },
  );
}
