import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/course_preview_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/course/chapter_lesson_list.dart';
import '../../core/widgets/course/course_chapter_layout.dart';
import '../../core/widgets/course/course_continue_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/course_preview_cubit.dart';

/// Um capítulo do Pilares do Xadrez (canvas `PropV2CursoLicao`), com os
/// mesmos componentes do capítulo de finais. Prévia: nada navega.
class CourseChapterPreviewScreen extends StatelessWidget {
  const CourseChapterPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CoursePreviewCubit, CoursePreviewState>(
      builder: (context, state) {
        final chapter = state.preview?.chapter;
        return Scaffold(
          key: CoursePreviewKeys.chapter,
          appBar: LucenaAppBar(),
          body: chapter == null
              ? const SizedBox.shrink()
              : CourseChapterLayout(
                  place: l10n.endgameModulePlace(
                    chapter.part,
                    chapter.number,
                    chapter.count,
                  ),
                  title: chapter.title,
                  list: ChapterLessonList(
                    rows: [
                      for (final lesson in chapter.lessons)
                        ChapterLessonRow(
                          key: CoursePreviewKeys.chapterLesson(lesson.id),
                          kind: ChapterRowKind.values.byName(lesson.kind),
                          number: lesson.number,
                          title: lesson.title,
                          summary: lesson.summary.isEmpty
                              ? null
                              : lesson.summary,
                          onTap: () {},
                        ),
                    ],
                    exercises: ChapterLessonRow(
                      key: CoursePreviewKeys.chapterExercises,
                      kind: ChapterRowKind.exercises,
                      number: chapter.exercisesNumber,
                      title: l10n.chapterExercisesTitle,
                      onTap: () {},
                    ),
                  ),
                  footer: CourseContinueFooter(
                    buttonKey: CoursePreviewKeys.chapterStart,
                    label: l10n.chapterStartLesson(chapter.start),
                    onPressed: () {},
                  ),
                ),
        );
      },
    );
  }
}
