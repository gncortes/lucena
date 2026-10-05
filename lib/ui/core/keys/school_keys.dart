import 'package:flutter/widgets.dart';

abstract final class SchoolKeys {
  static const screen = Key('school.screen');
  static const continueButton = Key('school.continue');
  static const graduated = Key('school.graduated');

  /// Uma aula na trilha.
  static Key lesson(String id) => Key('school.lesson.$id');

  /// Um módulo na trilha.
  static Key module(String id) => Key('school.module.$id');
}

abstract final class LessonKeys {
  static const screen = Key('lesson.screen');
  static const missing = Key('lesson.missing');
  static const board = Key('lesson.board');
  static const speech = Key('lesson.speech');
  static const progress = Key('lesson.progress');
  static const stepCounter = Key('lesson.stepCounter');
  static const nextButton = Key('lesson.next');
  static const hintButton = Key('lesson.hint');
  static const retryButton = Key('lesson.retry');
  static const finished = Key('lesson.finished');
  static const nextLessonButton = Key('lesson.nextLesson');
  static const trailButton = Key('lesson.trail');
  static const journeyButton = Key('lesson.journey');

  /// O passo aberto (`<aula>.<passo>`).
  static Key step(String lessonId, String stepId) =>
      Key('lesson.step.$lessonId.$stepId');

  /// Uma estrela que falta pegar.
  static Key star(String square) => Key('lesson.star.$square');
}
