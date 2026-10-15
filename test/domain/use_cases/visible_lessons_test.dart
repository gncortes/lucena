import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/visible_endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/school/visible_lesson_repository.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  test('só a Oposição, Partes 1 e 2, e a Escola escondida', () {
    expect(VisibleLessons.endgameLessonIds, {
      'pawns.distantOpposition',
      'pawns.waitingMoves',
    });
    expect(VisibleLessons.school, isFalse);
  });

  group('trilha', () {
    final all = FakeEndgameLessonRepository();

    test('fica só a aula liberada; o módulo vazio sai', () async {
      final trail = VisibleLessons.trail(await all.trail(), {'rook.philidor'});
      expect([for (final m in trail.modules) m.id], ['rook']);
      expect([for (final l in trail.lessons) l.id], ['rook.philidor']);
      expect(trail.lesson('rook.lucena'), isNull);
      expect(trail.after('rook.philidor'), isNull);
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
    final all = FakeLessonRepository();

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
