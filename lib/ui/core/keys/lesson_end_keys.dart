import 'package:flutter/widgets.dart';

/// Keys das telas de fim de lição e de curso (T85-D1, H-LIC-50 a 58).
abstract final class LessonEndKeys {
  static const dayGoal = Key('lessonEnd.dayGoal');
  static const dayGoalBack = Key('lessonEnd.dayGoal.back');
  static const dayGoalTest = Key('lessonEnd.dayGoal.test');
  static const dayGoalClose = Key('lessonEnd.dayGoal.close');
  static const dayGoalProgress = Key('lessonEnd.dayGoal.progress');

  static const offer = Key('lessonEnd.offer');
  static const offerAction = Key('lessonEnd.offer.action');
  static const offerNotNow = Key('lessonEnd.offer.notNow');
  static const offerClose = Key('lessonEnd.offer.close');

  static const review = Key('lessonEnd.review');
  static const reviewStart = Key('lessonEnd.review.start');
  static const reviewItem = Key('lessonEnd.review.item');
  static const tournament = Key('lessonEnd.tournament');
  static const tournamentWarmup = Key('lessonEnd.tournament.warmup');
  static const tournamentNotNow = Key('lessonEnd.tournament.notNow');
  static const tournamentPosition = Key('lessonEnd.tournament.position');

  static const completed = Key('lessonEnd.completed');
  static const completedDiploma = Key('lessonEnd.completed.diploma');
  static const completedGoals = Key('lessonEnd.completed.goals');
  static const completedCatalog = Key('lessonEnd.completed.catalog');
  static const completedShare = Key('lessonEnd.completed.share');
  static const completedClose = Key('lessonEnd.completed.close');

  static const soon = Key('lessonEnd.soon');
  static const soonBack = Key('lessonEnd.soon.back');
  static const soonClose = Key('lessonEnd.soon.close');
}
