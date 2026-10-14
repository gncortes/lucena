import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/endgame_progress_migration.dart';

const _first = EndgameProgressMigration.firstId;
const _second = EndgameProgressMigration.secondId;

void main() {
  test('sem progresso da lição antiga, nada muda', () {
    const progress = EndgameProgress(
      lessons: {'rook.lucena': EndgameLessonProgress(lessonDone: true)},
    );
    expect(EndgameProgressMigration.apply(progress), same(progress));
    const empty = EndgameProgress();
    expect(EndgameProgressMigration.apply(empty), same(empty));
  });

  test('lição concluída: Parte 1 concluída, Parte 2 não concluída', () {
    const progress = EndgameProgress(
      lessons: {
        _first: EndgameLessonProgress(
          lessonDone: true,
          stars: {'e09': 1, 'e11': 2, 'e13': 2, 'e14': 3, 'e16': 1},
        ),
      },
    );
    final migrated = EndgameProgressMigration.apply(progress);
    final first = migrated.of(_first);
    final second = migrated.of(_second);
    expect(first.lessonDone, isTrue);
    expect(first.parts, EndgameProgressMigration.firstParts);
    expect(first.stars, {'e09': 1, 'e11': 2, 'e13': 2});
    expect(second.lessonDone, isFalse);
    expect(second.parts, EndgameProgressMigration.secondParts);
    expect(second.stars, {'e14': 3, 'e16': 1});
  });

  test('lição em andamento: cada capítulo vai para a parte dele', () {
    const progress = EndgameProgress(
      lessons: {
        _first: EndgameLessonProgress(
          parts: {'distant', 'diagonal', 'reserve', 'waiting'},
          stars: {'e09': 1},
        ),
      },
    );
    final migrated = EndgameProgressMigration.apply(progress);
    expect(migrated.of(_first).lessonDone, isFalse);
    expect(migrated.of(_first).parts, {'distant', 'diagonal'});
    expect(migrated.of(_second).parts, {'reserve', 'waiting'});
    expect(migrated.of(_second).lessonDone, isFalse);
  });

  test('o exercício aberto vai para a parte que tem o exercício', () {
    const inSecond = ExerciseCheckpoint(exerciseId: 'e15', turn: 2);
    const inFirst = ExerciseCheckpoint(exerciseId: 'e11', turn: 1);
    final a = EndgameProgressMigration.apply(
      const EndgameProgress(
        lessons: {_first: EndgameLessonProgress(exercise: inSecond)},
      ),
    );
    expect(a.of(_first).exercise, isNull);
    expect(a.of(_second).exercise, inSecond);
    expect(a.openExercise, (_second, inSecond));
    final b = EndgameProgressMigration.apply(
      const EndgameProgress(
        lessons: {_first: EndgameLessonProgress(exercise: inFirst)},
      ),
    );
    expect(b.of(_first).exercise, inFirst);
    expect(b.of(_second).exercise, isNull);
  });

  test('a lição aberta num capítulo da Parte 2 passa para a Parte 2', () {
    const progress = EndgameProgress(
      lessons: {
        _first: EndgameLessonProgress(parts: {'distant'}),
      },
      ongoing: LessonCheckpoint(
        lessonId: _first,
        step: 3,
        part: 'waiting',
        stepId: 'waiting',
        turn: 1,
      ),
    );
    final migrated = EndgameProgressMigration.apply(progress);
    expect(migrated.ongoing?.lessonId, _second);
    expect(migrated.ongoing?.part, 'waiting');
    expect(migrated.ongoing?.step, 3);
    expect(migrated.ongoing?.turn, 1);
  });

  test('a lição aberta num capítulo da Parte 1 continua nela', () {
    const progress = EndgameProgress(
      lessons: {
        _first: EndgameLessonProgress(parts: {'distant'}),
      },
      ongoing: LessonCheckpoint(lessonId: _first, step: 2, part: 'lateral'),
    );
    final migrated = EndgameProgressMigration.apply(progress);
    expect(migrated.ongoing?.lessonId, _first);
  });

  test('sem progresso gravado da lição, só o checkpoint é migrado', () {
    const progress = EndgameProgress(
      ongoing: LessonCheckpoint(lessonId: _first, step: 1, part: 'means'),
    );
    final migrated = EndgameProgressMigration.apply(progress);
    expect(migrated.ongoing?.lessonId, _second);
    expect(migrated.lessons, isEmpty);
  });

  test('é idempotente: com a Parte 2 gravada, nada muda', () {
    final once = EndgameProgressMigration.apply(
      const EndgameProgress(
        lessons: {
          _first: EndgameLessonProgress(lessonDone: true, stars: {'e14': 2}),
        },
      ),
    );
    final twice = EndgameProgressMigration.apply(once);
    expect(twice, same(once));
    expect(twice.of(_second).stars, {'e14': 2});
  });
}
