import 'package:flutter/widgets.dart';

/// A Sequência (E1.22): a tela e a folha de sequência perdida.
abstract final class StreakKeys {
  static const screen = Key('streak.screen');
  static const current = Key('streak.current');
  static const record = Key('streak.record');
  static const weekStrip = Key('streak.weekStrip');
  static const monthGrid = Key('streak.monthGrid');

  /// O dia [day] do mês no calendário.
  static Key day(int day) => Key('streak.day.$day');

  static const lostSheet = Key('streak.lostSheet');
  static const lostPlay = Key('streak.lostPlay');
  static const lostNo = Key('streak.lostNo');
}
