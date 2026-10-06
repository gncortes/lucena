import 'dart:convert';

import '../../../domain/models/endgame_lesson.dart';
import '../../services/preferences_service.dart';

/// O que o aluno já fez nas aulas de finais.
abstract class EndgameProgressRepository {
  Future<EndgameProgress> load();

  Future<void> save(EndgameProgress progress);
}

/// Gravado nas preferências do aparelho.
class LocalEndgameProgressRepository implements EndgameProgressRepository {
  LocalEndgameProgressRepository(this._preferences);

  static const key = 'endgames.progress';

  final PreferencesService _preferences;

  @override
  Future<EndgameProgress> load() async {
    final text = await _preferences.getString(key);
    if (text == null) return const EndgameProgress();
    try {
      return EndgameProgress.fromJson(jsonDecode(text));
    } on FormatException {
      return const EndgameProgress();
    }
  }

  @override
  Future<void> save(EndgameProgress progress) =>
      _preferences.setString(key, jsonEncode(progress.toJson()));
}
