import '../../../domain/models/lesson_script.dart';

/// Os roteiros de lição (T70) e as falas deles.
abstract class LessonScriptRepository {
  /// O roteiro do asset [path] (`LessonPart.script`).
  Future<LessonScript> script(String path);

  /// As falas da lição [lessonId] em [language]: as da lição por cima das
  /// genéricas, e o idioma por cima do inglês.
  Future<ScriptTexts> texts(String lessonId, String language);
}
