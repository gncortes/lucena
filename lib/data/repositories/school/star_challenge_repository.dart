import 'dart:convert';

import '../../../domain/models/star_challenge.dart';
import '../../services/preferences_service.dart';

/// Os melhores resultados dos desafios das estrelas.
abstract class StarChallengeRepository {
  Future<StarChallengeProgress> load();

  Future<void> save(StarChallengeProgress progress);

  /// O desafio que estava na tela quando o app foi fechado: o app reabre no
  /// Pronto dele (a rodada não é restaurada).
  Future<OpenStarChallenge?> open();

  /// Grava o desafio na tela; nulo: o aluno saiu dele.
  Future<void> setOpen(OpenStarChallenge? challenge);
}

/// Gravado nas preferências do aparelho.
class LocalStarChallengeRepository implements StarChallengeRepository {
  LocalStarChallengeRepository(this._preferences);

  static const _key = 'school.starChallenges';
  static const _openKey = 'school.starChallenges.open';

  final PreferencesService _preferences;

  @override
  Future<OpenStarChallenge?> open() async =>
      OpenStarChallenge.parse(await _preferences.getString(_openKey));

  @override
  Future<void> setOpen(OpenStarChallenge? challenge) => challenge == null
      ? _preferences.remove(_openKey)
      : _preferences.setString(_openKey, challenge.key);

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
