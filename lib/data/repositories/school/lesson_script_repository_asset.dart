import 'dart:convert';

import '../../../domain/models/lesson_script.dart';
import '../../services/asset_service.dart';
import 'lesson_script_repository.dart';

/// O roteiro em `assets/lessons/roteiros/<lição>.json` (aula da Escola) ou, nas
/// aulas de final, em `roteiros/<lição>/<capítulo>.json` (campo `roteiro` da
/// parte), as falas da lição em
/// `assets/lessons/<idioma>/endgames/<lição>.json` (aula de final) ou
/// `assets/lessons/<idioma>/iniciante/<lição>.json` (curso de iniciante, T71)
/// mais as falas à parte de cada capítulo, em
/// `assets/lessons/<idioma>/endgames/<lição>.<capítulo>.rot.json` (T76:
/// quem escreve um capítulo entrega só as chaves dele; o capítulo existe se a
/// lição o lista em `parts`), e as genéricas em `assets/lessons/<idioma>/roteiro_generico.json` e
/// `roteiro_iniciante.json`.
class AssetLessonScriptRepository implements LessonScriptRepository {
  AssetLessonScriptRepository(this._assets);

  static String scriptPath(String lessonId) =>
      'assets/lessons/roteiros/$lessonId.json';

  /// O roteiro de um capítulo de aula de final (o `roteiro` da parte).
  static String chapterScriptPath(String lessonId, String partId) =>
      'assets/lessons/roteiros/$lessonId/$partId.json';
  static String lessonTextsPath(String lessonId, String language) =>
      'assets/lessons/$language/endgames/$lessonId.json';
  static String chapterTextsPath(
    String lessonId,
    String partId,
    String language,
  ) => 'assets/lessons/$language/endgames/$lessonId.$partId.rot.json';
  static String beginnerTextsPath(String lessonId, String language) =>
      'assets/lessons/$language/iniciante/$lessonId.json';
  static String genericPath(String language) =>
      'assets/lessons/$language/roteiro_generico.json';
  static String beginnerGenericPath(String language) =>
      'assets/lessons/$language/roteiro_iniciante.json';

  /// Os idiomas com falas. Outro idioma cai no inglês.
  static const languages = {'en', 'pt'};

  final AssetService _assets;
  final _scripts = <String, LessonScript>{};
  final _texts = <String, ScriptTexts>{};

  @override
  Future<LessonScript> script(String path) async {
    final cached = _scripts[path];
    if (cached != null) return cached;
    final json = jsonDecode(await _assets.loadString(path));
    return _scripts[path] = LessonScript.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<ScriptTexts> texts(String lessonId, String language) async {
    final code = languages.contains(language) ? language : 'en';
    return _texts['$lessonId/$code'] ??= ScriptTexts({
      ...await _merged(lessonId, 'en'),
      if (code != 'en') ...await _merged(lessonId, code),
    });
  }

  /// As genéricas do idioma sob as da lição. A lição está numa das duas
  /// pastas; a que falta não pesa.
  Future<Map<String, String>> _merged(String lessonId, String language) async =>
      {
        ...await _read(genericPath(language)),
        ...await _read(beginnerGenericPath(language)),
        ...await _read(lessonTextsPath(lessonId, language)),
        ...await _chapters(lessonId, language),
        ...await _read(beginnerTextsPath(lessonId, language)),
      };

  /// As falas à parte dos capítulos da aula de final [lessonId]; sem o
  /// arquivo do capítulo, nada.
  Future<Map<String, String>> _chapters(
    String lessonId,
    String language,
  ) async {
    final List<dynamic> parts;
    try {
      final lesson = jsonDecode(
        await _assets.loadString('assets/lessons/endgames/$lessonId.json'),
      );
      parts = (lesson as Map)['parts'] as List? ?? const [];
    } on Object {
      return const {};
    }
    return {
      for (final part in parts)
        if (part is Map && part['id'] is String)
          ...await _read(
            chapterTextsPath(lessonId, part['id'] as String, language),
          ),
    };
  }

  Future<Map<String, String>> _read(String path) async {
    final Object? json;
    try {
      json = jsonDecode(await _assets.loadString(path));
    } on Object {
      return const {};
    }
    if (json is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in json.entries)
        if (value is String)
          '$key': value
        else if (value is List && value.isNotEmpty && value.first is String)
          '$key': value.first as String,
    };
  }
}
