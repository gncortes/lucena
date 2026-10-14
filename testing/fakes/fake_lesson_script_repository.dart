import 'package:lucena/data/repositories/school/lesson_script_repository.dart';
import 'package:lucena/domain/models/lesson_script.dart';

/// Um roteiro e as falas na memória.
class FakeLessonScriptRepository implements LessonScriptRepository {
  FakeLessonScriptRepository(this.lessonScript, [Map<String, String>? texts])
    : _texts = ScriptTexts(texts ?? const {});

  final LessonScript lessonScript;
  final ScriptTexts _texts;

  /// Os caminhos e idiomas pedidos.
  final paths = <String>[];
  final languages = <String>[];

  @override
  Future<LessonScript> script(String path) async {
    paths.add(path);
    return lessonScript;
  }

  @override
  Future<ScriptTexts> texts(String lessonId, String language) async {
    languages.add(language);
    return _texts;
  }
}
