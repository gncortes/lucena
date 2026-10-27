import '../models/endgame_lesson.dart';
import '../models/lesson_content.dart';

/// Há aula de final liberada no app? A trilha vazia, ou o conteúdo ainda não
/// publicado ([LessonContentUnavailable]), é "não": o Curso de finais e os
/// finais para você somem das telas até a primeira aula chegar.
class CourseAvailability {
  const CourseAvailability(this._trail);

  final Future<EndgameTrail> Function() _trail;

  Future<bool> call() async {
    try {
      return (await _trail()).lessons.isNotEmpty;
    } on LessonContentUnavailable {
      return false;
    }
  }
}
