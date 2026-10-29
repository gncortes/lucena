import 'package:flutter/widgets.dart';

import '../../core/l10n/l10n.dart';

/// Maps the localization identifiers carried by TrainingCourseConfig. Course
/// views consume the same slots without branching on a course enum.
String courseGuideCopy(BuildContext context, String key) {
  final t = context.l10n;
  return <String, String>{
        'trainingPilaresTitle': t.trainingPilaresTitle,
        'schoolTitle': t.schoolTitle,
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
