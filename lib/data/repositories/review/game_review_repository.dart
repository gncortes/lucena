import 'dart:convert';

import '../../../domain/models/game_review.dart';
import '../../services/preferences_service.dart';

/// As revisões das partidas, para não refazer a análise ao reabrir.
abstract class GameReviewRepository {
  /// A revisão da partida [gameId]. Nula se ainda não foi feita (ou foi feita
  /// por outra versão do cálculo).
  Future<GameReview?> load(int gameId);

  Future<void> save(int gameId, GameReview review);
}

/// Guarda cada revisão nas preferências, em JSON.
class LocalGameReviewRepository implements GameReviewRepository {
  const LocalGameReviewRepository(this._preferences);

  final PreferencesService _preferences;

  static String keyOf(int gameId) => 'review.$gameId';

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
  Future<void> save(int gameId, GameReview review) =>
      _preferences.setString(keyOf(gameId), jsonEncode(review.toJson()));
}
