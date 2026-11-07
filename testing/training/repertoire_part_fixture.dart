import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';

/// Select a current repertoire part for a manually mounted Native fixture.
({String lessonId, OpeningTrecho part}) repertoirePartFixture(
  TrainingResources resources,
) {
  // Banks are populated by Future.wait; their insertion order is not the
  // curriculum order and includes profiles hidden from the current account.
  final lesson = resources.lessons.firstWhere(
    (lesson) =>
        lesson.kind == TrainingLessonKind.opening &&
        lesson.visible &&
        (resources.openings[lesson.id]?.any((part) => part.lines.isNotEmpty) ??
            false),
  );
  return (
    lessonId: lesson.id,
    part: resources.openings[lesson.id]!.firstWhere(
      (part) => part.lines.isNotEmpty,
    ),
  );
}
