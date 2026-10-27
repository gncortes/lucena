import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/use_cases/course_availability.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';

void main() {
  test('com aula na trilha, o curso está disponível', () async {
    final available = CourseAvailability(FakeEndgameLessonRepository().trail);
    expect(await available(), isTrue);
  });

  test('trilha vazia: o curso não está disponível', () async {
    final available = CourseAvailability(
      FakeEndgameLessonRepository(trail: const EndgameTrail(modules: [])).trail,
    );
    expect(await available(), isFalse);
  });

  test('conteúdo não publicado: o curso não está disponível', () async {
    final available = CourseAvailability(
      () async => throw const LessonContentUnavailable(),
    );
    expect(await available(), isFalse);
  });
}
