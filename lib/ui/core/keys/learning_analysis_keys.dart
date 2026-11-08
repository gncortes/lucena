import 'package:flutter/widgets.dart';

abstract final class LearningAnalysisKeys {
  static const screen = ValueKey('learningAnalysis.screen');
  static const back = ValueKey('learningAnalysis.back');
  static const settings = ValueKey('learningAnalysis.settings');
  static const board = ValueKey('learningAnalysis.board');
  static const engine = ValueKey('learningAnalysis.engine');
  static const evaluation = ValueKey('learningAnalysis.evaluation');
  static const notation = ValueKey('learningAnalysis.notation');
  static const first = ValueKey('learningAnalysis.first');
  static const previous = ValueKey('learningAnalysis.previous');
  static const next = ValueKey('learningAnalysis.next');
  static const last = ValueKey('learningAnalysis.last');
  static const sheet = ValueKey('learningAnalysis.sheet');
  static const close = ValueKey('learningAnalysis.close');
  static const showEngine = ValueKey('learningAnalysis.showEngine');
  static const lines = ValueKey('learningAnalysis.lines');
  static const confirm = ValueKey('learningAnalysis.confirm');
  static ValueKey<String> move(int index) =>
      ValueKey('learningAnalysis.move.$index');
}
