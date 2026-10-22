import 'dart:convert';

import '../../../domain/models/attempt.dart';
import '../../services/preferences_service.dart';
import 'progress_repository.dart';

/// As partidas deste aparelho mais o que veio da conta (E1.13): os desafios
/// e as posições cumpridos em outro celular contam como cumpridos aqui, sem
/// virar partida no histórico (as partidas de lá não descem).
class RestoredProgressRepository implements ProgressRepository {
  RestoredProgressRepository(this._local, this._preferences, {this._onAdded});

  static const _challengesKey = 'sync.restored.challenges';
  static const _positionsKey = 'sync.restored.positions';

  final ProgressRepository _local;
  final PreferencesService _preferences;

  // Avisa que uma partida terminou (a conta recebe o progresso depois).
  final void Function()? _onAdded;

  /// Junta [challenges] e [positions] aos que já vieram da conta.
  Future<void> restore({
    required Set<String> challenges,
    required Set<String> positions,
  }) async {
    await _add(_challengesKey, challenges);
    await _add(_positionsKey, positions);
  }

  Future<void> _add(String key, Set<String> ids) async {
    final saved = await _read(key);
    if (saved.containsAll(ids)) return;
    await _preferences.setString(
      key,
      jsonEncode(({...saved, ...ids}).toList()..sort()),
    );
  }

  Future<Set<String>> _read(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null) return {};
    try {
      return {
        for (final id in jsonDecode(raw) as List)
          if (id is String) id,
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<int> addAttempt(Attempt attempt) async {
    final id = await _local.addAttempt(attempt);
    _onAdded?.call();
    return id;
  }

  @override
  Future<List<Attempt>> allAttempts() => _local.allAttempts();

  @override
  Future<Map<int, Attempt>> allAttemptsById() => _local.allAttemptsById();

  @override
  Future<Map<int, Attempt>> attemptsById(Iterable<int> ids) =>
      _local.attemptsById(ids);

  @override
  Future<List<Attempt>> attemptsFor(String positionId) =>
      _local.attemptsFor(positionId);

  @override
  Future<Set<String>> fulfilledPositions() async => {
    ...await _local.fulfilledPositions(),
    ...await _read(_positionsKey),
  };

  @override
  Future<List<Attempt>> attemptsForChallenge(String challengeId) =>
      _local.attemptsForChallenge(challengeId);

  @override
  Future<Set<String>> fulfilledChallenges() async => {
    ...await _local.fulfilledChallenges(),
    ...await _read(_challengesKey),
  };
}
