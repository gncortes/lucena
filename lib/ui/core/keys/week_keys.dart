import 'package:flutter/widgets.dart';

/// Sua semana (E1.23).
abstract final class WeekKeys {
  static const screen = Key('week.screen');
  static const headline = Key('week.headline');

  /// Um dos quatro números: `finals`, `points`, `days`, `firstTry`.
  static Key stat(String code) => Key('week.stat.$code');

  static const bars = Key('week.bars');
  static const rating = Key('week.rating');
  static const play = Key('week.play');
  static const seeStreak = Key('week.seeStreak');
}
