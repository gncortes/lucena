import 'package:flutter/widgets.dart';

abstract final class ExplanationKeys {
  static Key block(String id) => ValueKey('explanation.block.$id');
  static Key header(String id) => ValueKey('explanation.header.$id');
  static Key paragraph(String id, int index) =>
      ValueKey('explanation.paragraph.$id.$index');
  static Key variation(String id) => ValueKey('explanation.variation.$id');
  static const first = ValueKey('explanation.first');
  static const previous = ValueKey('explanation.previous');
  static const next = ValueKey('explanation.next');
  static const last = ValueKey('explanation.last');
  static const restore = ValueKey('explanation.restore');
  static const parent = ValueKey('explanation.parent');
  static const unavailable = ValueKey('explanation.unavailable');
}
