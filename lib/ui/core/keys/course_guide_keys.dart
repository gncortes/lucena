import 'package:flutter/widgets.dart';

abstract final class CourseGuideKeys {
  static Key tab(String tab) => Key('courseGuide.tab.$tab');
  static const planAction = Key('courseGuide.planAction');
  static const helpAction = Key('courseGuide.helpAction');
  static const continueButton = Key('courseGuide.continue');
  static const seeCatalog = Key('courseGuide.seeCatalog');
  static Key difficultyStar(String id) => Key('courseGuide.difficulty.$id');
}
