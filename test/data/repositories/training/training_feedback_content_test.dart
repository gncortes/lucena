import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/play_training_exercise.dart';

import 'training_repository_test.dart' show MemoryContent, MemoryPreferences;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test('accepted later student move ends the exported branch successfully', () {
    final exercise = TrainingExercise.fromJson({
      'id': 'synthetic',
      'estrelas': 1,
      'fen': GameRules.initial.fen,
      'solucao': ['e2e4', 'e7e5', 'g1f3'],
      'alternativas_por_posicao': {
        '2': ['b1c3'],
      },
    });
    final rules = PlayTrainingExercise(exercise);
    final first = rules.play(exercise.fen, 0, 'e2e4');
    final accepted = rules.play(first.fen, first.cursor, 'b1c3');
    expect(accepted.done, true);
    expect(accepted.correct, true);
    expect(accepted.lastMove, 'b1c3');
    expect(TrainingExercise.fromJson(exercise.toJson()).alternativesAt(2), [
      'b1c3',
    ]);
  });

  test(
    'optional feedback is read separately and preserves the question',
    () async {
      final content = MemoryContent();
      content.files['assets/courses/pilares/index.json'] = jsonEncode({
        'partes': [
          {
            'id': 'p1',
            'titulo': 'Parte',
            'capitulos': [
              {
                'id': 'c1',
                'titulo': 'Capítulo',
                'aulas': [
                  {'id': 'lesson', 'tipo': 'tema', 'titulo': 'Aula'},
                ],
              },
            ],
          },
        ],
      });
      content.files['assets/lessons/treino/lesson.json'] = jsonEncode({
        'exercicios': [
          TrainingExercise(
            id: 'e',
            stars: 1,
            fen: GameRules.initial.fen,
            solution: ['e2e4'],
          ).toJson(),
        ],
      });
      final repository = TrainingRepositoryLocal(
        MemoryPreferences(),
        LessonContentAssets(reader: content),
        installSeed: 'feedback',
      );
      addTearDown(repository.dispose);
      var resources = await repository.resources(TrainingCourse.pilares);
      expect(resources.banks['lesson'], hasLength(1));
      expect(resources.errorFeedback, isEmpty);
      const text = 'Texto sintético. Qual recurso você pode procurar?';
      content.files['assets/lessons/treino/pt/lesson.json'] = jsonEncode({
        'e.1.d2d4': text,
      });
      resources = await repository.resources(TrainingCourse.pilares);
      expect(resources.errorFeedback['lesson']!['e.1.d2d4'], text);
      expect(
        () => resources.errorFeedback['lesson']!['x'] = 'x',
        throwsUnsupportedError,
      );
    },
  );
}
