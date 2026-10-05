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

  /// "Personalizar": o chip e o painel com o tempo de cada lado (`user` ou
  /// `opponent`), em controles deslizantes de `minutes` e `increment`.
  static const customPace = Key('setup.pace.custom');
  static const customSheet = Key('setup.custom.sheet');
  static const customSame = Key('setup.custom.same');
  static const customConfirm = Key('setup.custom.confirm');
  static Key customValue(String who) => Key('setup.custom.$who.value');
  static Key customSlider(String who, String field) =>
      Key('setup.custom.$who.$field');

  static const timeError = Key('setup.timeError');

  /// Uma partida do histórico; 0 é a mais recente.
  static Key attempt(int index) => Key('setup.attempt.$index');
  static const startButton = Key('setup.start');
}
