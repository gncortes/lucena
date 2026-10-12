import 'package:flutter/widgets.dart';

abstract final class GameSoundKeys {
  static const dialog = Key('game.sound.dialog');
  static const close = Key('game.sound.close');
  static const sound = Key('game.sound.enabled');
  static const comments = Key('game.sound.comments');
  static const speeds = Key('game.sound.speeds');
  static Key speed(double value) => ValueKey('game.sound.speed.$value');
}
