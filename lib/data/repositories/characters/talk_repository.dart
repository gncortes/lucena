import 'dart:convert';

import '../../../domain/use_cases/game_events.dart';
import '../../services/preferences_service.dart';

/// O que o personagem lembra da partida em andamento (emoção, falas já
/// ditas, a fala no balão). Volta com a partida depois de fechar o app.
class TalkSnapshot {
  const TalkSnapshot({
    required this.gameStartedAt,
    required this.plies,
    required this.memory,
    this.lineId,
    this.dismissedLineIds = const [],
    this.speechHintShown = false,
  });

  /// De que partida é: o início dela.
  final DateTime gameStartedAt;

  /// Quantos lances da partida já foram vistos.
  final int plies;
  final TalkMemory memory;

  /// A fala no balão. Nula: balão fechado.
  final String? lineId;
  final List<String> dismissedLineIds;
  final bool speechHintShown;

  Map<String, dynamic> toJson() => {
    'game': gameStartedAt.toUtc().toIso8601String(),
    'plies': plies,
    'memory': memory.toJson(),
    'line': lineId,
    'dismissed': dismissedLineIds,
    'speechHintShown': speechHintShown,
  };

  static TalkSnapshot? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final game = DateTime.tryParse(json['game'] as String? ?? '');
    final memory = json['memory'];
    if (game == null || memory is! Map<String, dynamic>) return null;
    return TalkSnapshot(
      gameStartedAt: game,
      plies: json['plies'] as int? ?? 0,
      memory: TalkMemory.fromJson(memory),
      lineId: json['line'] as String?,
      dismissedLineIds: json['dismissed'] is List
          ? (json['dismissed'] as List).whereType<String>().toSet().toList()
          : const [],
      speechHintShown: json['speechHintShown'] == true,
    );
  }
}

abstract class TalkRepository {
  Future<TalkSnapshot?> load();

  Future<void> save(TalkSnapshot snapshot);

  /// Intervalo global da dica, independente da partida em andamento.
  Future<DateTime?> loadSpeechHintShownAt();
  Future<void> saveSpeechHintShownAt(DateTime shownAt);
}

/// Gravado nas preferências, como a partida em andamento.
class LocalTalkRepository implements TalkRepository {
  LocalTalkRepository(this._preferences);

  static const _key = 'talk.ongoing';
  static const _speechHintKey = 'talk.speechHint.shownAt';

  final PreferencesService _preferences;

  @override
  Future<TalkSnapshot?> load() async {
    final text = await _preferences.getString(_key);
    if (text == null) return null;
    try {
      return TalkSnapshot.fromJson(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(TalkSnapshot snapshot) =>
      _preferences.setString(_key, jsonEncode(snapshot.toJson()));

  @override
  Future<DateTime?> loadSpeechHintShownAt() async {
    final value = await _preferences.getString(_speechHintKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> saveSpeechHintShownAt(DateTime shownAt) =>
      _preferences.setString(_speechHintKey, shownAt.toUtc().toIso8601String());
}
