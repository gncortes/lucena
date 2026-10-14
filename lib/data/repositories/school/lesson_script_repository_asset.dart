import 'dart:convert';

import '../../../domain/models/lesson_script.dart';
import '../../services/asset_service.dart';
import 'lesson_script_repository.dart';

/// O roteiro em `assets/lessons/roteiros/<lição>.json`, as falas da lição em
/// `assets/lessons/<idioma>/endgames/<lição>.json` e as genéricas em
/// `assets/lessons/<idioma>/roteiro_generico.json`.
class AssetLessonScriptRepository implements LessonScriptRepository {
  AssetLessonScriptRepository(this._assets);

  static String lessonTextsPath(String lessonId, String language) =>
      'assets/lessons/$language/endgames/$lessonId.json';
  static String genericPath(String language) =>
      'assets/lessons/$language/roteiro_generico.json';

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

  /// As genéricas do idioma sob as da lição.
  Future<Map<String, String>> _merged(String lessonId, String language) async =>
      {
        ...await _read(genericPath(language)),
        ...await _read(lessonTextsPath(lessonId, language)),
      };

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
