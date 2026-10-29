import 'package:flutter/widgets.dart';

abstract final class TrainingKeys {
  static const goalsSummary = Key('training.goalsSummary');
  static Key goalTile(String kind, String ref) =>
      Key('training.goal.$kind.$ref');
  static const doubleOffer = Key('training.doubleOffer');
  static const doubleButton = Key('training.doubleButton');
  static const difficultyBadge = Key('training.difficultyBadge');
  static const hintBadge = Key('training.hintBadge');
  static const exerciseBoard = Key('training.exerciseBoard');
  static const exerciseScreen = Key('training.exerciseScreen');
  static const exerciseHint = Key('training.exerciseHint');
  static const exerciseRetry = Key('training.exerciseRetry');
  static const exercisePracticeRetry = Key('training.exercisePracticeRetry');
  static const exerciseFeedbackExpand = Key('training.exerciseFeedbackExpand');
  static const exerciseFeedbackSheet = Key('training.exerciseFeedbackSheet');
  static const exerciseFeedbackScroll = Key('training.exerciseFeedbackScroll');
  static const exerciseSaveError = Key('training.exerciseSaveError');
  static const exerciseEnd = Key('training.exerciseEnd');
  static const nextGoal = Key('training.nextGoal');
  static const secondary = Key('training.secondary');
  static const endPrimary = Key('training.endPrimary');
  static const endSecondary = Key('training.endSecondary');
  static Key openingCard(String id) => Key('training.opening.$id');
  static const openingsScreen = Key('training.openingsScreen');
  static const openingScreen = Key('training.openingScreen');
  static const openingBack = Key('training.openingBack');
  static const openingBoard = Key('training.openingBoard');
  static Key openingTitle(String id) => Key('training.openingTitle.$id');
  static const openingSaveRetry = Key('training.openingSaveRetry');
  static const openingSaveError = Key('training.openingSaveError');
  static Key trainTrecho(String id) => Key('training.trainTrecho.$id');
  static const prevMove = Key('training.prevMove');
  static const nextMove = Key('training.nextMove');
  static Key moveInList(int i) => Key('training.move.$i');
  static Key planChip(int min) => Key('training.plan.$min');
  static Key weekday(int i) => Key('training.weekday.$i');
  static const reminderSwitch = Key('training.reminderSwitch');
  static const reminderTime = Key('training.reminderTime');
  static const planSave = Key('training.planSave');
  static const planScreen = Key('training.planScreen');
  static const planScroll = Key('training.planScroll');
  static const planError = Key('training.planError');
  static const permissionDialog = Key('training.permissionDialog');
  static const permissionLater = Key('training.permissionLater');
  static const permissionAllow = Key('training.permissionAllow');
  static const openNotificationSettings = Key(
    'training.openNotificationSettings',
  );
  static Key masteryRow(String id) => Key('training.mastery.$id');
  static Key moduleRow(String id) => Key('training.module.$id');
  static Key pieceStars(String piece) => Key('training.pieceStars.$piece');
  static const tourNext = Key('training.tourNext');
  static const themeScreen = Key('training.themeScreen');
  static const themeChart = Key('training.themeChart');
  static const themeBack = Key('training.themeBack');
  static const helpScreen = Key('training.helpScreen');
  static const helpBack = Key('training.helpBack');
  static const helpTour = Key('training.helpTour');
  static Key faq(int index) => Key('training.faq.$index');
  static const tourOverlay = Key('training.tourOverlay');
  static const tourClose = Key('training.tourClose');
  static const tourSkip = Key('training.tourSkip');
}
