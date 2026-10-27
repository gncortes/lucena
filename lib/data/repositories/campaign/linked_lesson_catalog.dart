import '../../../domain/models/lesson_content.dart';
import '../../../domain/models/linked_lesson.dart';
import '../endgames/endgame_lesson_repository.dart';
import '../school/lesson_repository.dart';

/// Se a aula de um link de campanha abre (T84): existe e está liberada
/// (`VisibleLessons`, que os repositórios do app já aplicam). O app não tem
/// aula paga nem trancada: liberada é a aula que aparece na trilha.
class LinkedLessonCatalog {
  const LinkedLessonCatalog({required this._endgames, required this._school});

  final EndgameLessonRepository _endgames;
  final LessonRepository _school;

  Future<bool> available(LinkedLesson lesson) async {
    try {
      return switch (lesson.kind) {
        LinkedLessonKind.endgame =>
          (await _endgames.trail()).lesson(lesson.id) != null,
        LinkedLessonKind.school =>
          (await _school.course()).lesson(lesson.id) != null,
      };
    } on LessonContentUnavailable {
      return false;
    }
  }
}
