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

  /// O título, o módulo e a posição da aula no idioma, para a folha da aula
  /// gratuita e o fundo do convite do link só de aula. Nulo: a aula ou o
  /// texto não existe.
  Future<LinkedLessonInfo?> info(LinkedLesson lesson, String language) async {
    try {
      switch (lesson.kind) {
        case LinkedLessonKind.endgame:
          final found = (await _endgames.trail()).lesson(lesson.id);
          final texts = await _endgames.texts(language);
          final title = texts.plain('${lesson.id}.title');
          if (found == null || title == null) return null;
          return LinkedLessonInfo(
            kind: lesson.kind,
            title: title,
            module: texts.plain('endgames.module.${found.module}'),
            fen: found.keyPositions.firstOrNull?.fen ?? found.practice?.fen,
          );
        case LinkedLessonKind.school:
          final found = (await _school.course()).lesson(lesson.id);
          final texts = await _school.texts(language);
          final title = texts.plain('${lesson.id}.title');
          if (found == null || title == null) return null;
          return LinkedLessonInfo(
            kind: lesson.kind,
            title: title,
            fen: found.steps.map((step) => step.fen).nonNulls.firstOrNull,
          );
      }
    } on LessonContentUnavailable {
      return null;
    }
  }
}
