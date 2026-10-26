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
          'rook.cutOff': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1},
            exercise: exercise,
          ),
        },
        ongoing: LessonCheckpoint(
          lessonId: 'rook.philidor',
          step: 2,
          part: 'part',
          stepId: 'demos/ex2',
          scriptExample: 1,
          scriptTrack: 'main',
          scriptHead: 2,
          scriptEnd: 3,
          demoPlaying: true,
        ),
      ),
    );
    final loaded = await repository.load();
    final cutOff = loaded.of('rook.cutOff');
    expect(cutOff.lessonDone, isTrue);
    expect(cutOff.stars, {'e01': 1});
    expect(cutOff.exercise, exercise);
    expect(loaded.openExercise, ('rook.cutOff', exercise));
    expect(loaded.ongoing?.lessonId, 'rook.philidor');
    expect(loaded.ongoing?.step, 2);
    expect(loaded.ongoing?.scriptExample, 1);
    expect(loaded.ongoing?.scriptTrack, 'main');
    expect(loaded.ongoing?.scriptHead, 2);
    expect(loaded.ongoing?.scriptEnd, 3);
    expect(loaded.ongoing?.demoPlaying, isTrue);
  });

  test('o exercício fechado pelo voltar não reabre o app nele', () async {
    await repository.save(
      const EndgameProgress(
        lessons: {
          'rook.cutOff': EndgameLessonProgress(
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

  test(
    'T74: o progresso da oposição antes da divisão é migrado e regravado',
    () async {
      await PreferencesService().setString(
        LocalEndgameProgressRepository.key,
        '{"lessons":{"pawns.distantOpposition":{"lessonDone":true,'
        '"parts":[],"stars":{"e09":1,"e14":3}}}}',
      );
      final loaded = await repository.load();
      expect(loaded.of('pawns.distantOpposition').lessonDone, isTrue);
      expect(loaded.of('pawns.distantOpposition').stars, {'e09': 1});
      expect(loaded.of('pawns.waitingMoves').lessonDone, isFalse);
      expect(loaded.of('pawns.waitingMoves').stars, {'e14': 3});
      final saved = await PreferencesService().getString(
        LocalEndgameProgressRepository.key,
      );
      expect(saved, contains('pawns.waitingMoves'));
      final again = await repository.load();
      expect(again.of('pawns.waitingMoves').stars, {'e14': 3});
    },
  );
}
