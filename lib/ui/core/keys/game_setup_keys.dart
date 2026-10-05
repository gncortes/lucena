import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/models/game_setup.dart';

abstract final class GameSetupKeys {
  static const screen = Key('setup.screen');
  static const preview = Key('setup.preview');
  static const goal = Key('setup.goal');

  static Key side(Side side) => Key('setup.side.${side.name}');
  static Key opponent(OpponentKind kind) => Key('setup.opponent.${kind.code}');

  /// Os níveis do Maia, um por rating (`setup.level.1400`).
  static const levels = Key('setup.levels');
  static Key level(int level) => Key('setup.level.$level');

  /// O aviso de qual nível combina com o rating do perfil.
  static const suggestedLevel = Key('setup.level.suggested');

  /// Os ritmos nomeados (`setup.pace.3+2`).
  static const paces = Key('setup.paces');
  static Key pace(String id) => Key('setup.pace.$id');
  static const clockSwitch = Key('setup.clock');

  /// Os seletores de tempo: `user` ou `opponent`, `minutes` ou `increment`.
  static Key value(String who, String field) => Key('setup.$who.$field');
  static Key decrease(String who, String field) =>
      Key('setup.$who.$field.decrease');
  static Key increase(String who, String field) =>
      Key('setup.$who.$field.increase');

  static const timeError = Key('setup.timeError');

  /// Uma partida do histórico; 0 é a mais recente.
  static Key attempt(int index) => Key('setup.attempt.$index');
  static const startButton = Key('setup.start');
}
