import 'package:flutter/widgets.dart';

import '../../core/l10n/l10n.dart';
import '../../../domain/models/training/training_content.dart';

/// Study screens use the explanatory topic label; Catalog keeps the short title.
String trainingMasteryLessonTitle(
  BuildContext context,
  TrainingLesson lesson,
) => switch (lesson.id) {
  'pilares.c1.doubleAttack' => context.l10n.trainingMasteryDoubleAttack,
  'pilares.c1.hangingPiece' => context.l10n.trainingMasteryHangingPiece,
  _ => lesson.title,
};

String trainingProgressOpeningTitle(BuildContext context, OpeningTrecho part) =>
    part.openingId == 'others' || part.openingId == 'othersAggr'
    ? context.l10n.trainingOpeningChipOthers
    : part.title;

/// Maps the localization identifiers carried by TrainingCourseConfig. Course
/// views consume the same slots without branching on a course enum.
String courseGuideCopy(BuildContext context, String key, {int count = 0}) {
  final t = context.l10n;
  if (key == 'trainingEscolaDoubleBody') {
    return t.trainingEscolaDoubleBody(count);
  }
  return <String, String>{
        'trainingPilaresTitle': t.trainingPilaresTitle,
        'schoolTitle': t.schoolTitle,
        'trainingFirstInfo': t.trainingFirstInfo,
        'trainingAllDoneViktor': t.trainingAllDoneViktor,
        'trainingEscolaAllDoneViktor': t.trainingEscolaAllDoneViktor,
        'trainingDoubleOfferBody': t.trainingDoubleOfferBody,
        'trainingDayOffInfo': t.trainingDayOffInfo,
        'trainingEscolaDayOffInfo': t.trainingEscolaDayOffInfo,
        'trainingEscolaTips1Title': t.trainingEscolaTips1Title,
        'trainingEscolaTips1Body': t.trainingEscolaTips1Body,
        'trainingEscolaTips2Title': t.trainingEscolaTips2Title,
        'trainingEscolaTips2Body': t.trainingEscolaTips2Body,
        'trainingEscolaTips3Title': t.trainingEscolaTips3Title,
        'trainingEscolaTips3Body': t.trainingEscolaTips3Body,
        'trainingEscolaTips4Title': t.trainingEscolaTips4Title,
        'trainingEscolaTips4Body': t.trainingEscolaTips4Body,
        'trainingEscolaPlanReco15': t.trainingEscolaPlanReco15,
        'trainingEscolaPlanReco30': t.trainingEscolaPlanReco30,
        'trainingEscolaPlanReco60': t.trainingEscolaPlanReco60,
        'trainingEscolaPlanReco120': t.trainingEscolaPlanReco120,
        'trainingEscolaWelcomeTitle': t.trainingEscolaWelcomeTitle,
        'trainingEscolaWelcomeBody': t.trainingEscolaWelcomeBody,
        'trainingEscolaTabsLesson': t.trainingEscolaTabsLesson,
        'trainingEscolaTabsGoals': t.trainingEscolaTabsGoals,
        'trainingEscolaTabsProgress': t.trainingEscolaTabsProgress,
        'trainingEscolaTabsCatalog': t.trainingEscolaTabsCatalog,
        'trainingPlanTime120More': t.trainingPlanTime120More,
        'trainingSectionBots': t.trainingSectionBots,
        'trainingSectionStars': t.trainingSectionStars,
        'trainingSpeedrunGoalTitle': t.trainingSpeedrunGoalTitle,
        'trainingEscolaFirstInfo': t.trainingEscolaFirstInfo,
        'trainingProgressLessons': t.trainingProgressLessons,
        'trainingProgressPieceStars': t.trainingProgressPieceStars,
        'trainingBotNameCoco': t.trainingBotNameCoco,
        'trainingPlanTimeQuestion': t.trainingPlanTimeQuestion,
        'trainingPlanTime15': t.trainingPlanTime15,
        'trainingPlanTime30': t.trainingPlanTime30,
        'trainingPlanTime60': t.trainingPlanTime60,
        'trainingPlanTime120': t.trainingPlanTime120,
        'trainingPlanTime240': t.trainingPlanTime240,
        'trainingPlanReco15': t.trainingPlanReco15,
        'trainingPlanReco30': t.trainingPlanReco30,
        'trainingPlanReco60': t.trainingPlanReco60,
        'trainingPlanReco120': t.trainingPlanReco120,
        'trainingPlanReco240': t.trainingPlanReco240,
        'trainingPlanRecoMore': t.trainingPlanRecoMore,
        'courseGuideWelcomeTitle': t.courseGuideWelcomeTitle,
        'courseGuideWelcomeBody': t.courseGuideWelcomeBody,
        'courseGuideTips1Title': t.courseGuideTips1Title,
        'courseGuideTips1Body': t.courseGuideTips1Body,
        'courseGuideTips2Title': t.courseGuideTips2Title,
        'courseGuideTips2Body': t.courseGuideTips2Body,
        'courseGuideTips3Title': t.courseGuideTips3Title,
        'courseGuideTips3Body': t.courseGuideTips3Body,
        'courseGuideTips4Title': t.courseGuideTips4Title,
        'courseGuideTips4Body': t.courseGuideTips4Body,
      }[key] ??
      (throw ArgumentError.value(
        key,
        'key',
        'Unknown guide localization identifier',
      ));
}

/// Roman ordinal shared by the guide and its chapter position.
String courseGuideRoman(int ordinal) {
  var remaining = ordinal;
  final result = StringBuffer();
  for (final (value, symbol) in [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ]) {
    while (remaining >= value) {
      result.write(symbol);
      remaining -= value;
    }
  }
  return result.toString();
}
