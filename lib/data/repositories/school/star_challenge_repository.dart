import 'dart:convert';
import 'dart:async';

import '../../../domain/models/star_challenge.dart';
import '../../services/preferences_service.dart';

/// Os melhores resultados dos desafios das estrelas.
abstract class StarChallengeRepository {
  Future<StarChallengeProgress> load();

  Future<void> save(StarChallengeProgress progress);
  Future<void> addRun({
    required ChallengePiece piece,
    required ChallengeLevel level,
    required int points,
    required DateTime at,
  });
  Future<List<StarChallengeRun>> runsSince(DateTime since);

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
  Future<void> _pending = Future.value();
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<Map<String, dynamic>> _read() async {
    final text = await _preferences.getString(_key);
    if (text == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } on FormatException {
      return {};
    }
  }

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
  Future<void> save(StarChallengeProgress progress) => _serial(() async {
    final json = await _read();
    final best = {...StarChallengeProgress.fromJson(json).best};
    for (final entry in progress.best.entries) {
      if (entry.value > (best[entry.key] ?? 0)) best[entry.key] = entry.value;
    }
    await _preferences.setString(_key, jsonEncode({...json, 'best': best}));
  });

  @override
  Future<void> addRun({
    required ChallengePiece piece,
    required ChallengeLevel level,
    required int points,
    required DateTime at,
  }) => _serial(() async {
    final json = await _read();
    final best = {...StarChallengeProgress.fromJson(json).best};
    final key = StarChallengeProgress.keyOf(piece, level);
    if (points > (best[key] ?? 0)) best[key] = points;
    final run = StarChallengeRun(
      piece: piece,
      level: level,
      points: points,
      at: at,
    );
    await _preferences.setString(
      _key,
      jsonEncode({
        ...json,
        'best': best,
        'runs': [...(json['runs'] as List? ?? []), run.toJson()],
      }),
    );
  });

  @override
  Future<List<StarChallengeRun>> runsSince(DateTime since) async {
    final json = await _read();
    return List.unmodifiable(
      (json['runs'] as List? ?? [])
          .map(
            (r) =>
                StarChallengeRun.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .where((r) => !r.at.isBefore(since)),
    );
  }
}
