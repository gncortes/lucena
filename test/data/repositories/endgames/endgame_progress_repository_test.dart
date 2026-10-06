import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late LocalEndgameProgressRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repository = LocalEndgameProgressRepository(PreferencesService());
  });

  test('vazio antes de gravar', () async {
    final progress = await repository.load();
    expect(progress.lessons, isEmpty);
    expect(progress.ongoing, isNull);
    expect(progress.openExercise, isNull);
  });

  test('grava e lê a lição, as estrelas e o exercício aberto', () async {
    const exercise = ExerciseCheckpoint(
      exerciseId: 'e02',
      fen: '8/8/8/8/8/8/8/K6k w - - 0 1',
      turn: 1,
      mistakes: 1,
      hints: 1,
    );
    await repository.save(
      const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1},
            exercise: exercise,
          ),
        },
        ongoing: LessonCheckpoint(lessonId: 'rook.philidor', step: 2),
      ),
    );
    final loaded = await repository.load();
    final lucena = loaded.of('rook.lucena');
    expect(lucena.lessonDone, isTrue);
    expect(lucena.stars, {'e01': 1});
    expect(lucena.exercise, exercise);
    expect(loaded.openExercise, ('rook.lucena', exercise));
    expect(loaded.ongoing?.lessonId, 'rook.philidor');
    expect(loaded.ongoing?.step, 2);
  });

  test('o exercício fechado pelo voltar não reabre o app nele', () async {
    await repository.save(
      const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            exercise: ExerciseCheckpoint(exerciseId: 'e01', open: false),
          ),
        },
      ),
    );
    expect((await repository.load()).openExercise, isNull);
  });

  test('dado corrompido vira progresso vazio', () async {
    await PreferencesService().setString(
      LocalEndgameProgressRepository.key,
      '{oops',
    );
    expect((await repository.load()).lessons, isEmpty);
  });
}
