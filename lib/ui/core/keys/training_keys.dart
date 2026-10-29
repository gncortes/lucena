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
  static const nextGoal = Key('training.nextGoal');
  static const secondary = Key('training.secondary');
  static const endPrimary = Key('training.endPrimary');
  static const endSecondary = Key('training.endSecondary');
  static Key openingCard(String id) => Key('training.opening.$id');
  static Key trainTrecho(String id) => Key('training.trainTrecho.$id');
  static const prevMove = Key('training.prevMove');
  static const nextMove = Key('training.nextMove');
  static Key moveInList(int i) => Key('training.move.$i');
  static Key planChip(int min) => Key('training.plan.$min');
  static Key weekday(int i) => Key('training.weekday.$i');
  static const reminderSwitch = Key('training.reminderSwitch');
  static const reminderTime = Key('training.reminderTime');
  static const planSave = Key('training.planSave');
  static Key masteryRow(String id) => Key('training.mastery.$id');
  static Key moduleRow(String id) => Key('training.module.$id');
  static Key pieceStars(String piece) => Key('training.pieceStars.$piece');
  static const tourNext = Key('training.tourNext');
  static const tourSkip = Key('training.tourSkip');
}
