import 'dart:convert';

import '../../../domain/models/game_review.dart';
import '../../services/preferences_service.dart';

/// As revisões das partidas, para não refazer a análise ao reabrir.
abstract class GameReviewRepository {
  /// A revisão da partida [gameId]. Nula se ainda não foi feita (ou foi feita
  /// por outra versão do cálculo).
  Future<GameReview?> load(int gameId);

  Future<void> save(int gameId, GameReview review);

  /// A precisão das brancas e das pretas em cada partida de [gameIds] que já
  /// tem revisão (para o histórico, sem ler as revisões inteiras).
  Future<Map<int, ({double? white, double? black})>> accuracies(
    Iterable<int> gameIds,
  );
}

/// Guarda cada revisão nas preferências, em JSON.
class LocalGameReviewRepository implements GameReviewRepository {
  const LocalGameReviewRepository(this._preferences);

  final PreferencesService _preferences;

  static String keyOf(int gameId) => 'review.$gameId';
  static String accuracyKeyOf(int gameId) => 'review.accuracy.$gameId';

  @override
  Future<GameReview?> load(int gameId) async {
    final raw = await _preferences.getString(keyOf(gameId));
    if (raw == null) return null;
    try {
      return GameReview.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(int gameId, GameReview review) async {
    await _preferences.setString(keyOf(gameId), jsonEncode(review.toJson()));
    await _preferences.setString(
      accuracyKeyOf(gameId),
      jsonEncode({
        'white': review.whiteAccuracy,
        'black': review.blackAccuracy,
      }),
    );
  }

  @override
  Future<Map<int, ({double? white, double? black})>> accuracies(
    Iterable<int> gameIds,
  ) async {
    final found = <int, ({double? white, double? black})>{};
    for (final id in gameIds) {
      final raw = await _preferences.getString(accuracyKeyOf(id));
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, Object?>;
        found[id] = (
          white: (json['white'] as num?)?.toDouble(),
          black: (json['black'] as num?)?.toDouble(),
        );
      } on Object {
        continue;
      }
    }
    return found;
  }
}
