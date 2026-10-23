import 'dart:convert';

import '../../../domain/models/featured.dart';
import '../../../domain/models/game_setup.dart';
import '../../services/preferences_service.dart';

/// O que o jogador já fez com os finais em destaque: quais jogou e o
/// adversário e o relógio que escolheu em cada um.
abstract class FeaturedProgressRepository {
  /// Os ids dos finais já jogados (ao menos uma tentativa).
  Future<Set<String>> played();

  Future<void> markPlayed(String id);

  /// A escolha do jogador neste final. Nula: vale a do final.
  Future<FeaturedChoice?> choice(String id);

  Future<void> saveChoice(String id, FeaturedChoice choice);
}

/// Gravado nas preferências do aparelho.
class LocalFeaturedProgressRepository implements FeaturedProgressRepository {
  LocalFeaturedProgressRepository(this._preferences);

  final PreferencesService _preferences;

  static const _playedKey = 'featured.played';
  static String _choiceKey(String id) => 'featured.$id.choice';

  @override
  Future<Set<String>> played() async {
    final text = await _preferences.getString(_playedKey);
    if (text == null) return {};
    try {
      return {for (final id in jsonDecode(text) as List) id as String};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> markPlayed(String id) async {
    final all = await played();
    if (!all.add(id)) return;
    await _preferences.setString(_playedKey, jsonEncode(all.toList()..sort()));
  }

  @override
  Future<FeaturedChoice?> choice(String id) async {
    final text = await _preferences.getString(_choiceKey(id));
    if (text == null) return null;
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return FeaturedChoice(
        opponent: OpponentKind.trainingFromCode(json['opponent'] as String?),
        level: json['level'] as int?,
        clock: json['clock'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveChoice(String id, FeaturedChoice choice) =>
      _preferences.setString(
        _choiceKey(id),
        jsonEncode({
          'opponent': choice.opponent.code,
          'level': choice.level,
          'clock': choice.clock,
        }),
      );
}
