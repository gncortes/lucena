import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../core/keys/course_guide_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/course/chapter_lesson_list.dart';
import '../../core/widgets/course/course_chapter_layout.dart';
import '../../core/widgets/course/course_continue_footer.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/course_guide_cubit.dart';
import 'course_guide_copy.dart';

/// A chapter uses exactly the visible lessons supplied by the private index.
class CourseChapterScreen extends StatelessWidget {
  const CourseChapterScreen({
    required this.chapter,
    required this.onBack,
    required this.onLesson,
    super.key,
  });
  final String chapter;
  final VoidCallback onBack;
  final ValueChanged<TrainingLesson> onLesson;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CourseGuideCubit, CourseGuideState>(
    builder: (context, state) {
      final lessons =
          state.resources?.lessons
              .where((lesson) => lesson.visible && lesson.groupId == chapter)
              .toList() ??
          [];
      final visible =
          state.resources?.lessons.where((l) => l.visible).toList() ??
          <TrainingLesson>[];
      final part = lessons.firstOrNull?.partId;
      final parts = visible.map((l) => l.partId).toSet().toList();
      final chapters = visible
          .where((l) => l.partId == part)
          .map((l) => l.groupId)
          .toSet()
          .toList();
      final number = chapters.indexOf(chapter) + 1;
      final rows = lessons
          .where((l) => l.kind != TrainingLessonKind.test)
          .toList();
      final exercises = lessons
          .where((l) => l.kind == TrainingLessonKind.test)
          .firstOrNull;
      final completed =
          state.training?.completedLessons ?? const <String, String>{};
      final next = lessons
          .where((l) => !completed.containsKey(l.id))
          .firstOrNull;
      return Scaffold(
        key: CourseGuideKeys.chapterScreen,
        appBar: LucenaAppBar(leading: BackButton(onPressed: onBack)),
        body: SafeArea(
          top: false,
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : lessons.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: Icons.auto_stories_outlined,
                    message: context.l10n.lessonsUnavailableMessage,
                  ),
                )
              : CourseChapterLayout(
                  place: context.l10n.endgameModulePlace(
                    context.l10n.trainingPartLabel(
                      courseGuideRoman(parts.indexOf(part ?? '') + 1),
                    ),
                    number,
                    chapters.length,
                  ),
                  title: lessons.first.group,
                  list: ChapterLessonList(
                    rows: [
                      for (final (index, lesson) in rows.indexed)
                        ChapterLessonRow(
                          key: CourseGuideKeys.chapterLesson(lesson.id),
                          kind: completed.containsKey(lesson.id)
                              ? ChapterRowKind.done
                              : lesson == next
                              ? ChapterRowKind.recommended
                              : ChapterRowKind.other,
                          number: '$number.${index + 1}',
                          title: lesson.title,
                          summary: lesson.summary,
                          onTap: () => onLesson(lesson),
                        ),
                    ],
                    exercises: exercises == null
                        ? null
                        : ChapterLessonRow(
                            key: CourseGuideKeys.chapterLesson(exercises.id),
                            kind: ChapterRowKind.exercises,
                            number: '$number.${rows.length + 1}',
                            title: context.l10n.chapterExercisesTitle,
                            onTap: () => onLesson(exercises),
                          ),
                  ),
                  footer: CourseContinueFooter(
                    label: context.l10n.homeContinue,
                    buttonKey: CourseGuideKeys.chapterContinue,
                    onPressed: next == null ? null : () => onLesson(next),
                  ),
                ),
        ),
      );
    },
  );
}
