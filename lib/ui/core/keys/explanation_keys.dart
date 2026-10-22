import 'package:flutter/widgets.dart';

abstract final class ExplanationKeys {
  static Key block(String id) => ValueKey('explanation.block.$id');
  static Key header(String id) => ValueKey('explanation.header.$id');
  static Key paragraph(String id, int index) =>
      ValueKey('explanation.paragraph.$id.$index');
  static Key variation(String id) => ValueKey('explanation.variation.$id');

  /// The arrow that opens or closes the sub-variations of a line.
  static Key expand(String id) => ValueKey('explanation.expand.$id');

  /// The context/history quote of a block (LessonQuote).
  static Key quote(String id) => ValueKey('explanation.quote.$id');
  static const first = ValueKey('explanation.first');
  static const previous = ValueKey('explanation.previous');
  static const next = ValueKey('explanation.next');
  static const last = ValueKey('explanation.last');
  static const restore = ValueKey('explanation.restore');
  static const parent = ValueKey('explanation.parent');
  static const unavailable = ValueKey('explanation.unavailable');
}
