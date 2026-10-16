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

  test('aprovada antes: a Parte 1 continua aprovada, a Parte 2 não', () {
    const progress = EndgameProgress(
      lessons: {
        _first: EndgameLessonProgress(
          lessonDone: true,
          stars: {'e09': 1, 'e11': 2, 'e13': 2, 'e14': 2, 'e15': 1, 'e16': 1},
        ),
      },
    );
    final migrated = EndgameProgressMigration.apply(progress);
    final first = migrated.of(_first);
    final second = migrated.of(_second);
    expect(first.approved, isTrue);
    expect(first.lessonDone, isTrue);
    expect(first.stars, {'e09': 1, 'e11': 2, 'e13': 2});
    expect(second.approved, isFalse);
    expect(second.stars, {'e14': 2, 'e15': 1, 'e16': 1});
    expect(EndgameLessonProgress.fromJson(first.toJson()).approved, isTrue);
  });

  test('não aprovada antes: nenhuma das partes fica aprovada', () {
    const progress = EndgameProgress(
      lessons: {
        _first: EndgameLessonProgress(
          lessonDone: true,
          stars: {'e09': 1, 'e11': 2, 'e13': 2, 'e14': 1},
        ),
      },
    );
    final migrated = EndgameProgressMigration.apply(progress);
    expect(migrated.of(_first).approved, isFalse);
    expect(migrated.of(_second).approved, isFalse);
    const lowScore = EndgameProgress(
      lessons: {
        _first: EndgameLessonProgress(
          lessonDone: true,
          stars: {'e09': 0, 'e11': 1, 'e13': 1, 'e14': 1, 'e15': 1, 'e16': 1},
        ),
      },
    );
    expect(
      EndgameProgressMigration.apply(lowScore).of(_first).approved,
      isFalse,
    );
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

  group('capítulos da T76', () {
    const keySquares = EndgameProgressMigration.keySquaresId;

    test('progresso novo e já migrado ficam como estão', () {
      const fresh = EndgameProgress(
        lessons: {
          _first: EndgameLessonProgress(parts: {'lateral'}),
          _second: EndgameLessonProgress(parts: {'waiting'}),
        },
      );
      expect(EndgameProgressMigration.apply(fresh), same(fresh));
    });

    test('lição tudo concluída: diagonal vai para as casas-chave', () {
      const old = EndgameProgress(
        chaptersMigrated: false,
        lessons: {
          _first: EndgameLessonProgress(
            lessonDone: true,
            approved: true,
            stars: {'e09': 1, 'e17': 1, 'e18': 2},
          ),
          _second: EndgameLessonProgress(lessonDone: true),
        },
      );
      final migrated = EndgameProgressMigration.apply(old);
      expect(migrated.chaptersMigrated, isTrue);
      expect(migrated.of(keySquares).parts, {'diagonal'});
      expect(migrated.of(keySquares).lessonDone, isFalse);
      // Parte 1: os capítulos que ficaram mais o means, que veio da Parte 2.
      expect(migrated.of(_first).lessonDone, isTrue);
      expect(migrated.of(_first).approved, isTrue);
      expect(migrated.of(_first).parts, {
        'distant',
        'lateral',
        'capablanca',
        'edge',
        'means',
      });
      expect(migrated.of(_first).stars, {'e09': 1, 'e18': 2});
      expect(migrated.of(_second).lessonDone, isTrue);
      expect(migrated.of(_second).stars, {'e17': 1});
    });

    test('Parte 1 concluída sem o means: não conta como concluída', () {
      const old = EndgameProgress(
        chaptersMigrated: false,
        lessons: {
          _first: EndgameLessonProgress(lessonDone: true),
          _second: EndgameLessonProgress(parts: {'reserve', 'waiting'}),
        },
      );
      final migrated = EndgameProgressMigration.apply(old);
      expect(migrated.of(_first).lessonDone, isFalse);
      expect(migrated.of(_first).parts, {
        'distant',
        'lateral',
        'capablanca',
        'edge',
      });
      expect(migrated.of(_second).parts, {'reserve', 'waiting'});
    });

    test('lição em andamento: means e diagonal acompanham o capítulo', () {
      const old = EndgameProgress(
        chaptersMigrated: false,
        lessons: {
          _first: EndgameLessonProgress(
            parts: {'distant', 'diagonal', 'lateral', 'defend'},
            stars: {'e11': 2},
          ),
          _second: EndgameLessonProgress(
            parts: {'means', 'waiting', 'useReserve'},
          ),
        },
      );
      final migrated = EndgameProgressMigration.apply(old);
      expect(migrated.of(keySquares).parts, {'diagonal'});
      expect(migrated.of(_first).parts, {'distant', 'lateral', 'means'});
      expect(migrated.of(_first).lessonDone, isFalse);
      expect(migrated.of(_first).stars, {'e11': 2});
      expect(migrated.of(_second).parts, {'waiting'});
    });

    test('o exercício e17 aberto vai para a Parte 2 com as estrelas', () {
      const open = ExerciseCheckpoint(exerciseId: 'e17', turn: 1);
      const old = EndgameProgress(
        chaptersMigrated: false,
        lessons: {
          _first: EndgameLessonProgress(exercise: open, stars: {'e17': 1}),
        },
      );
      final migrated = EndgameProgressMigration.apply(old);
      expect(migrated.of(_first).exercise, isNull);
      expect(migrated.of(_second).exercise, open);
      expect(migrated.of(_second).stars, {'e17': 1});
      expect(migrated.openExercise, (_second, open));
    });

    test('a lição aberta no diagonal e no means muda de lição', () {
      const inDiagonal = EndgameProgress(
        chaptersMigrated: false,
        ongoing: LessonCheckpoint(lessonId: _first, step: 2, part: 'diagonal'),
      );
      expect(
        EndgameProgressMigration.apply(inDiagonal).ongoing?.lessonId,
        keySquares,
      );
      const inMeans = EndgameProgress(
        chaptersMigrated: false,
        ongoing: LessonCheckpoint(lessonId: _second, step: 4, part: 'means'),
      );
      final migrated = EndgameProgressMigration.apply(inMeans);
      expect(migrated.ongoing?.lessonId, _first);
      expect(migrated.ongoing?.step, 4);
    });

    test('é idempotente e sobrevive à gravação em JSON', () {
      const old = EndgameProgress(
        chaptersMigrated: false,
        lessons: {_first: EndgameLessonProgress(lessonDone: true)},
      );
      final once = EndgameProgressMigration.apply(old);
      expect(EndgameProgressMigration.apply(once), same(once));
      final loaded = EndgameProgress.fromJson(once.toJson());
      expect(loaded.chaptersMigrated, isTrue);
      expect(EndgameProgressMigration.apply(loaded), same(loaded));
      // Gravado antes da T76: sem o campo, volta a migrar.
      final legacy = EndgameProgress.fromJson({
        'lessons': {
          _first: {'lessonDone': true},
          _second: {'lessonDone': true},
        },
      });
      expect(legacy.chaptersMigrated, isFalse);
    });
  });
}
