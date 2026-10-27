import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/school_progress_repository.dart';
import 'package:lucena/data/repositories/school/lesson_repository.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _UnusedLessons implements LessonRepository {
  @override
  Future<Course> course() => throw UnimplementedError();
  @override
  Future<LessonTexts> texts(String language) => throw UnimplementedError();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('grava e lê as aulas feitas e o passo em andamento', () async {
    final repository = LocalSchoolProgressRepository(PreferencesService());
    expect((await repository.load()).completed, isEmpty);

    const ongoing = LessonCheckpoint(
      lessonId: 'mates.queen',
      step: 3,
      fen: '8/8/8/8/8/1k6/8/K6Q w - - 0 1',
      moves: ['h1h2', 'b3c3'],
      part: 'part',
      stepId: 'ideia/ex1',
      scriptExample: 1,
      scriptTrack: 'alt:h1h2',
      scriptHead: 2,
      scriptEnd: 4,
      demoPlaying: true,
    );
    await repository.save(
      const SchoolProgress(completed: {'pieces.rook'}, ongoing: ongoing),
    );
    final loaded = await repository.load();
    expect(loaded.completed, {'pieces.rook'});
    expect(loaded.ongoing, ongoing);

    await repository.save(const SchoolProgress(completed: {'pieces.rook'}));
    expect((await repository.load()).ongoing, isNull);
  });

  test(
    'saída aguarda checkpoints pendentes e preserva cursor ao fechar',
    () async {
      final repository = LocalSchoolProgressRepository(PreferencesService());
      final source = SchoolLessonSource(_UnusedLessons(), repository);
      const first = LessonCheckpoint(
        lessonId: 'test',
        step: 0,
        scriptExample: 0,
        scriptTrack: 'entrada',
        scriptHead: 0,
        scriptEnd: 1,
      );
      const last = LessonCheckpoint(
        lessonId: 'test',
        step: 1,
        scriptExample: 1,
        scriptTrack: 'main',
        scriptHead: 2,
        scriptEnd: 3,
      );
      final writes = [
        source.saveCheckpoint(first),
        source.saveCheckpoint(last),
      ];
      await source.leave();
      await Future.wait(writes);
      expect((await repository.load()).ongoing, last.copyWith(open: false));
    },
  );
}
