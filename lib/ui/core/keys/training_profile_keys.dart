import 'package:flutter/widgets.dart';

abstract final class TrainingProfileKeys {
  static const screen = ValueKey('trainingProfile.screen');
  static const choose = ValueKey('trainingProfile.choose');
  static const why = ValueKey('trainingProfile.why');
  static const whyBoard = ValueKey('trainingProfile.whyBoard');
  static const whyClose = ValueKey('trainingProfile.whyClose');
  static const back = ValueKey('trainingProfile.back');
  static const moment = ValueKey('trainingProfile.moment');
  static Key card(String profile) => ValueKey('trainingProfile.card.$profile');
  static Key chip(String profile, int index) =>
      ValueKey('trainingProfile.chip.$profile.$index');
}
