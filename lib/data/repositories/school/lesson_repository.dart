import '../../../domain/models/lesson.dart';

/// As aulas da Escola do Viktor e as falas dele.
abstract class LessonRepository {
  Future<Course> course();

  /// As falas em [language] (`pt`, `en`). O que falta no idioma vem do
  /// inglês.
  Future<LessonTexts> texts(String language);
}
