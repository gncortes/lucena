import 'dart:convert';

import '../../../domain/models/lesson.dart';
import '../../services/preferences_service.dart';

/// O que o aluno já fez na Escola do Viktor.
abstract class SchoolProgressRepository {
  Future<SchoolProgress> load();

  Future<void> save(SchoolProgress progress);
}

/// Gravado nas preferências do aparelho.
class LocalSchoolProgressRepository implements SchoolProgressRepository {
  LocalSchoolProgressRepository(this._preferences);

  static const _completedKey = 'school.completed';
  static const _ongoingKey = 'school.ongoing';

  final PreferencesService _preferences;

  @override
  Future<SchoolProgress> load() async {
    final completed = await _preferences.getString(_completedKey);
    final ongoing = await _preferences.getString(_ongoingKey);
    return SchoolProgress(
      completed: {
        for (final id in _decode(completed) as List? ?? const [])
          if (id is String) id,
      },
      ongoing: LessonCheckpoint.fromJson(_decode(ongoing)),
    );
  }

  @override
  Future<void> save(SchoolProgress progress) async {
    await _preferences.setString(
      _completedKey,
      jsonEncode(progress.completed.toList()..sort()),
    );
    final ongoing = progress.ongoing;
    if (ongoing == null) {
      await _preferences.remove(_ongoingKey);
    } else {
      await _preferences.setString(_ongoingKey, jsonEncode(ongoing.toJson()));
    }
  }

  static Object? _decode(String? text) {
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}
