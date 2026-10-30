import 'package:flutter/widgets.dart';

abstract final class TestCanvasKeys {
  static const facts = Key('testCanvas.facts');
  static const medal = Key('testCanvas.medal');
  static const reviewHint = Key('testCanvas.reviewHint');
  static Key answer(int index) => Key('testCanvas.answer.$index');
}
