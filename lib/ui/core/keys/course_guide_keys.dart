import 'package:flutter/widgets.dart';

abstract final class CourseGuideKeys {
  static const screen = Key('courseGuide.screen');
  static const chapterScreen = Key('courseGuide.chapter.screen');
  static Key chapter(String id) => Key('courseGuide.chapter.$id');
  static const chapterContinue = Key('courseGuide.chapter.continue');
  static const goalsBadge = Key('courseGuide.goalsBadge');
  static Key chapterLesson(String id) => Key('courseGuide.chapter.lesson.$id');
  static Key catalogPart(String id) => Key('courseGuide.catalogPart.$id');
  static Key tab(String tab) => Key('courseGuide.tab.$tab');
  static const planAction = Key('courseGuide.planAction');
  static const helpAction = Key('courseGuide.helpAction');
  static const continueButton = Key('courseGuide.continue');
  static const levelTest = Key('courseGuide.levelTest');
  static const seeCatalog = Key('courseGuide.seeCatalog');
  static Key difficultyStar(String id) => Key('courseGuide.difficulty.$id');
}
