import 'dart:convert';

import '../../../domain/models/featured.dart';
import '../../../domain/models/find_move_checkpoint.dart';
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

  Future<FindMoveCheckpoint?> findMove(FeaturedEndgame endgame);

  /// Grava a transição inteira; [onPlayed] executa dentro da mesma fila
  /// quando a fase conclui o desafio (inclui o registro de atividade).
  Future<void> saveFindMove(
    String id,
    FindMoveCheckpoint checkpoint, {
    Future<void> Function()? onPlayed,
  });

  static final _findMovePending = <String, Future<void>>{};

  /// Compartilhada entre instâncias locais: reabrir espera os writes anteriores.
  /// A operação não deve chamar outro método que use esta fila para o mesmo ID.
  static Future<T> serializeFindMove<T>(
    String id,
    Future<T> Function() action,
  ) {
    final previous = _findMovePending[id] ?? Future<void>.value();
    final result = previous.then((_) => action());
    final completion = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    _findMovePending[id] = completion;
    return result.whenComplete(() {
      if (identical(_findMovePending[id], completion)) {
        _findMovePending.remove(id);
      }
    });
  }
}

/// Gravado nas preferências do aparelho.
class LocalFeaturedProgressRepository implements FeaturedProgressRepository {
  LocalFeaturedProgressRepository(this._preferences);

  final PreferencesService _preferences;

  static const _playedKey = 'featured.played';
  static String _choiceKey(String id) => 'featured.$id.choice';

  @override
  Future<FindMoveCheckpoint?> findMove(FeaturedEndgame endgame) =>
      FeaturedProgressRepository.serializeFindMove(endgame.id, () async {
        final text = await _preferences.getString(
          'featured.${endgame.id}.findMove',
        );
        if (text == null) return null;
        final checkpoint = FindMoveCheckpoint.fromJson(
          jsonDecode(text) as Map<String, dynamic>,
        );
        return checkpoint.matches(endgame) ? checkpoint : null;
      });

  @override
  Future<void> saveFindMove(
    String id,
    FindMoveCheckpoint checkpoint, {
    Future<void> Function()? onPlayed,
  }) => FeaturedProgressRepository.serializeFindMove(id, () async {
    if (checkpoint.phase == FindMovePhase.solved ||
        checkpoint.phase == FindMovePhase.revealed) {
      await markPlayed(id);
      await onPlayed?.call();
    }
    await _preferences.setString(
      'featured.$id.findMove',
      jsonEncode(checkpoint.toJson()),
    );
  });

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
