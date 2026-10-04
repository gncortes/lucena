import 'dart:convert';

import 'package:dartchess/dartchess.dart';

import '../../../domain/models/clock.dart';
import '../../../domain/models/game_snapshot.dart';
import '../../services/preferences_service.dart';
import 'ongoing_game_repository.dart';

/// Partida em andamento gravada no aparelho, como um texto JSON.
class LocalOngoingGameRepository implements OngoingGameRepository {
  LocalOngoingGameRepository(this._preferences);

  static const _key = 'game.ongoing';

  final PreferencesService _preferences;

  @override
  Future<GameSnapshot?> load() async {
    final text = await _preferences.getString(_key);
    if (text == null) return null;
    try {
      return _decode(jsonDecode(text) as Map<String, dynamic>);
    } on Object {
      // Gravação ilegível (versão antiga, arquivo corrompido): sem partida.
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(GameSnapshot snapshot) =>
      _preferences.setString(_key, jsonEncode(_encode(snapshot)));

  @override
  Future<void> clear() => _preferences.remove(_key);

  Map<String, dynamic> _encode(GameSnapshot snapshot) {
    final clock = snapshot.clock;
    return {
      'startFen': snapshot.startFen,
      'moves': snapshot.moves,
      'orientation': snapshot.orientation.name,
      'playerSide': snapshot.playerSide?.name,
      'onScreen': snapshot.onScreen,
      'clock': clock == null
          ? null
          : {
              'white': clock.config.white.code,
              'black': clock.config.black.code,
              'whiteMs': clock.white.inMilliseconds,
              'blackMs': clock.black.inMilliseconds,
              'running': clock.running?.name,
              // O instante em que a vez começou, e não quanto falta: o
              // desconto continua valendo com o app fechado.
              'turnStartedAt': clock.turnStartedAt?.millisecondsSinceEpoch,
            },
    };
  }

  GameSnapshot _decode(Map<String, dynamic> json) {
    final sides = Side.values.asNameMap();
    final clock = json['clock'] as Map<String, dynamic>?;
    final turnStartedAt = clock?['turnStartedAt'] as int?;
    return GameSnapshot(
      startFen: json['startFen'] as String,
      moves: (json['moves'] as List).cast<String>(),
      orientation: sides[json['orientation']]!,
      playerSide: sides[json['playerSide']],
      onScreen: json['onScreen'] as bool,
      clock: clock == null
          ? null
          : ClockState(
              config: ClockConfig(
                white: TimeControl.tryParse(clock['white'] as String)!,
                black: TimeControl.tryParse(clock['black'] as String)!,
              ),
              white: Duration(milliseconds: clock['whiteMs'] as int),
              black: Duration(milliseconds: clock['blackMs'] as int),
              running: sides[clock['running']],
              turnStartedAt: turnStartedAt == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      turnStartedAt,
                      isUtc: true,
                    ),
            ),
    );
  }
}
