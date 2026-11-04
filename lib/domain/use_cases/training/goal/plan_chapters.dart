import '../../../models/training/training_content.dart';
import '../../../models/training/training_course.dart';
import '../../../models/training/training_resources.dart';

/// Minutos estimados por lição e pelo teste do capítulo ("cerca de 15 minutos").
const minutesPerLesson = 15;

/// Capítulo do curso: o grupo de lições e o teste (H-TRE-07: a unidade do plano é o capítulo inteiro).
final class PlanChapter {
  PlanChapter({
    required this.id,
    required this.title,
    required this.partId,
    required this.partTitle,
    required Iterable<String> lessonIds,
    this.testId,
  }) : lessonIds = List.unmodifiable(lessonIds);

  final String id, title, partId, partTitle;
  final List<String> lessonIds;
  final String? testId;

  /// Lições mais o teste.
  int get itemCount => lessonIds.length + (testId == null ? 0 : 1);
  int get minutes => itemCount * minutesPerLesson;

  Iterable<String> get allIds => [...lessonIds, ?testId];
}

/// Capítulos na ordem do curso. Aberturas ficam de fora: têm metas próprias.
List<PlanChapter> planChapters(TrainingResources resources) {
  final order = <String>[];
  final groups = <String, List<TrainingLesson>>{};
  for (final lesson in resources.lessons) {
    if (!lesson.visible ||
        !lesson.published ||
        !lesson.inCourseOrder ||
        lesson.kind == TrainingLessonKind.opening ||
        lesson.groupId.isEmpty) {
      continue;
    }
    if (!groups.containsKey(lesson.groupId)) order.add(lesson.groupId);
    groups.putIfAbsent(lesson.groupId, () => []).add(lesson);
  }
  return [
    for (final id in order)
      PlanChapter(
        id: id,
        title: groups[id]!.first.group,
        partId: groups[id]!.first.partId,
        partTitle: groups[id]!.first.partTitle,
        lessonIds: [
          for (final l in groups[id]!)
            if (l.kind != TrainingLessonKind.test) l.id,
        ],
        testId: groups[id]!
            .where((l) => l.kind == TrainingLessonKind.test)
            .map((l) => l.id)
            .firstOrNull,
      ),
  ];
}

/// Andamento do capítulo (lições feitas e teste feito).
final class ChapterProgress {
  const ChapterProgress({
    required this.chapter,
    required this.lessonsDone,
    required this.testDone,
  });
  final PlanChapter chapter;
  final int lessonsDone;
  final bool testDone;
  int get lessonsTotal => chapter.lessonIds.length;
  bool get complete =>
      lessonsDone >= lessonsTotal && (chapter.testId == null || testDone);
  int get minutesLeft =>
      ((lessonsTotal - lessonsDone) +
          (chapter.testId == null || testDone ? 0 : 1)) *
      minutesPerLesson;
}

ChapterProgress chapterProgress(
  PlanChapter chapter,
  Map<String, String> completedLessons,
) => ChapterProgress(
  chapter: chapter,
  lessonsDone: chapter.lessonIds.where(completedLessons.containsKey).length,
  testDone:
      chapter.testId != null && completedLessons.containsKey(chapter.testId),
);
