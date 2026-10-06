import 'dart:convert';

import '../../../domain/models/star_challenge.dart';
import '../../services/preferences_service.dart';

/// Os melhores resultados dos desafios das estrelas.
abstract class StarChallengeRepository {
  Future<StarChallengeProgress> load();

  Future<void> save(StarChallengeProgress progress);
}

/// Gravado nas preferências do aparelho.
class LocalStarChallengeRepository implements StarChallengeRepository {
  LocalStarChallengeRepository(this._preferences);

  static const _key = 'school.starChallenges';

  final PreferencesService _preferences;

  @override
  Future<StarChallengeProgress> load() async {
    final text = await _preferences.getString(_key);
    if (text == null) return const StarChallengeProgress();
    try {
      return StarChallengeProgress.fromJson(jsonDecode(text));
    } on FormatException {
      return const StarChallengeProgress();
    }
  }

  @override
  Future<void> save(StarChallengeProgress progress) =>
      _preferences.setString(_key, jsonEncode(progress.toJson()));
}
