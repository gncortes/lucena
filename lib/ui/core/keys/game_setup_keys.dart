import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/models/game_setup.dart';

abstract final class GameSetupKeys {
  static const screen = Key('setup.screen');
  static const preview = Key('setup.preview');
  static const goal = Key('setup.goal');

  static Key side(Side side) => Key('setup.side.${side.name}');
  static Key opponent(OpponentKind kind) => Key('setup.opponent.${kind.code}');
  static const clockSwitch = Key('setup.clock');

  /// Os seletores de tempo: `user` ou `opponent`, `minutes` ou `increment`.
  static Key value(String who, String field) => Key('setup.$who.$field');
  static Key decrease(String who, String field) =>
      Key('setup.$who.$field.decrease');
  static Key increase(String who, String field) =>
      Key('setup.$who.$field.increase');

  static const timeError = Key('setup.timeError');
  static const startButton = Key('setup.start');
}
