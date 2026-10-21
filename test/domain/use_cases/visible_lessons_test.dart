import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/visible_endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/school/visible_lesson_repository.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

/// A aula de final com um capítulo de roteiro novo (as dos fakes são do
/// formato antigo, escondido).
EndgameLesson _scripted(EndgameLesson lesson) => EndgameLesson(
  id: lesson.id,
  module: lesson.module,
  lesson: Lesson.parted(
    id: lesson.id,
    parts: [
      LessonPart(id: 'main', steps: lesson.lesson.steps, script: 'r.json'),
    ],
  ),
  exercises: lesson.exercises,
  passScore: lesson.passScore,
  keyPositions: lesson.keyPositions,
  practice: lesson.practice,
);

/// Os fakes de final, todos com roteiro novo.
class _ScriptedEndgames extends FakeEndgameLessonRepository {
  @override
  Future<EndgameTrail> trail() async => EndgameTrail(
    modules: [
      for (final m in (await super.trail()).modules)
        EndgameModule(
          id: m.id,
          lessons: [for (final l in m.lessons) _scripted(l)],
        ),
    ],
  );
}

/// A Escola de teste, com a aula de roteiro novo.
class _ScriptedSchool extends FakeLessonRepository {
  @override
  Future<Course> course() async {
    final course = await super.course();
    return Course(
      modules: [
        for (final m in course.modules)
          CourseModule(
            id: m.id,
            lessons: [
              for (final l in m.lessons)
                Lesson(id: l.id, steps: l.steps, script: 'r.json'),
            ],
          ),
      ],
    );
  }
}

void main() {
  test('a Oposição, o bispo e cavalo, a dama contra torre, a Lucena e a '
      'Escola escondida', () {
    expect(VisibleLessons.endgameLessonIds, {
      'pawns.keySquares',
      'pawns.distantOpposition',
      'pawns.waitingMoves',
      'mates.bishopKnight.deletang',
      'queen.vsRook.philidor',
      'rook.lucena',
    });
    expect(VisibleLessons.school, isFalse);
  });

  group('trilha', () {
    final all = _ScriptedEndgames();

    test('fica só a aula liberada; o módulo vazio sai', () async {
      final trail = VisibleLessons.trail(await all.trail(), {'rook.philidor'});
      expect([for (final m in trail.modules) m.id], ['rook']);
      expect([for (final l in trail.lessons) l.id], ['rook.philidor']);
      expect(trail.lesson('rook.lucena'), isNull);
      expect(trail.after('rook.philidor'), isNull);
    });

    test('exercício de ideia sem capítulo visível sai da lista', () async {
      final base = (await all.trail()).lesson('rook.lucena')!;
      Exercise ex(String id) {
        final model = base.exercises.first;
        return Exercise(
          id: id,
          stars: 1,
          fen: model.fen,
          goal: model.goal,
          line: model.line,
        );
      }

      final lesson = EndgameLesson(
        id: 'pawns.keySquares',
        module: 'pawns',
        lesson: base.lesson,
        exercises: [ex('e14'), ex('e15'), ex('e16'), ex('e10')],
        passScore: 2,
        keyPositions: base.keyPositions,
        practice: base.practice,
      );
      final trail = VisibleLessons.trail(
        EndgameTrail(
          modules: [
            EndgameModule(id: 'pawns', lessons: [lesson]),
          ],
        ),
        {'pawns.keySquares'},
      );
      expect(
        [for (final e in trail.lesson('pawns.keySquares')!.exercises) e.id],
        ['e14', 'e10'],
      );
    });

    test('nenhuma liberada: trilha vazia', () async {
      final trail = VisibleLessons.trail(await all.trail(), {});
      expect(trail.modules, isEmpty);
    });

    test('o repositório filtra a trilha e deixa as falas', () async {
      final visible = VisibleEndgameLessonRepository(all, ids: {'rook.lucena'});
      expect(
        [for (final l in (await visible.trail()).lessons) l.id],
        ['rook.lucena'],
      );
      expect(await visible.texts('en'), same(await all.texts('en')));
    });
  });

  group('Escola', () {
    final all = _ScriptedSchool();

    test('sem aula liberada, o curso fica vazio', () async {
      final course = await VisibleLessonRepository(all).course();
      expect(course.modules, isEmpty);
      expect(
        await VisibleLessonRepository(all).texts('en'),
        isA<LessonTexts>(),
      );
    });

    test('a aula liberada fica, na ordem, sem os módulos vazios', () async {
      final full = await all.course();
      final first = full.modules.first.lessons.first.id;
      final course = await VisibleLessonRepository(all, ids: {first}).course();
      expect([for (final m in course.modules) m.id], [full.modules.first.id]);
      expect([for (final l in course.lessons) l.id], [first]);
    });
  });

  group('tela inicial sem a Escola', () {
    test('a sugestão não traz as aulas do Viktor; a Jornada sobe', () {
      final layout = HomeSuggestion.of(RatingLevel.beginner);
      expect(layout.order, isNot(contains(HomePath.learn)));
      expect(layout.shown, [
        HomePath.journey,
        HomePath.forYou,
        HomePath.endgames,
      ]);
    });

    test('o ajustado com a Escola marcada perde só ela', () {
      final saved = HomeSuggestion.of(
        RatingLevel.beginner,
        school: true,
      ).copyWith(custom: true);
      final layout = HomeSuggestion.resolve(saved, RatingLevel.beginner);
      expect(layout.order, isNot(contains(HomePath.learn)));
      expect(layout.shown, [HomePath.journey]);
    });

    test('só a Escola marcada: o primeiro caminho aparece', () {
      const saved = HomeLayout(
        order: [HomePath.learn, HomePath.train, HomePath.journey],
        visible: {HomePath.learn},
        custom: true,
      );
      expect(HomeSuggestion.resolve(saved, RatingLevel.casual).shown, [
        HomePath.train,
      ]);
    });
  });
}
