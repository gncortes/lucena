import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/widgets/course/chapter_lesson_list.dart';
import 'package:lucena/ui/core/widgets/course/course_chapter_layout.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_chapter_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

void main() {
  setUpAll(Goldens.loadFonts);
  for (final size in phoneSizes) {
    for (final completedCount in [0, 1, 2]) {
      testWidgets(
        'chapter geometry and exercises at $size after $completedCount lessons',
        (tester) async {
          setPhoneSize(tester, size);
          TrainingLesson lesson(
            String id, {
            String chapter = 'alpha',
            String part = 'z',
            bool test = false,
            bool visible = true,
          }) => TrainingLesson(
            id: id,
            kind: test ? TrainingLessonKind.test : TrainingLessonKind.theme,
            title: test ? 'Teste original' : 'Aula $id',
            groupId: chapter,
            group: 'Capítulo $chapter',
            partId: part,
            partTitle: 'Descrição da parte $part',
            visible: visible,
          );
          final first = lesson('a1');
          final second = lesson('a2');
          final test = lesson('test', test: true);
          final resources = TrainingResources(
            lessons: [
              lesson('previous-part', chapter: 'old', part: 'a'),
              lesson('previous-chapter', chapter: 'omega'),
              first,
              second,
              test,
              lesson('hidden', visible: false),
              lesson('last-chapter', chapter: 'beta'),
            ],
          );
          final done = [first, second].take(completedCount);
          final repository = FakeTrainingRepository(
            content: {TrainingCourse.pilares: resources},
            states: {
              TrainingCourse.pilares: TrainingState(
                course: TrainingCourse.pilares,
                installSeed: 'chapter-layout',
                completedLessons: {for (final l in done) l.id: '2026-10-28'},
              ),
            },
          );
          final cubit = CourseGuideCubit(
            repository: repository,
            config: TrainingCourseConfig.pilares,
            now: FakeNow(DateTime(2026, 10, 29)),
          );
          addTearDown(cubit.close);
          addTearDown(repository.dispose);
          await cubit.load();
          TrainingLesson? opened;
          var backed = false;
          await tester.pumpWidget(
            TestApp(
              locale: const Locale('pt'),
              child: BlocProvider.value(
                value: cubit,
                child: CourseChapterScreen(
                  chapter: 'alpha',
                  onBack: () => backed = true,
                  onLesson: (l) => opened = l,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.widget<AppBar>(find.byType(AppBar)).title, isNull);
          final layout = tester.widget<CourseChapterLayout>(
            find.byType(CourseChapterLayout),
          );
          expect(layout.place, 'Parte II · capítulo 2 de 3');
          expect(layout.title, 'Capítulo alpha');
          final list = tester.widget<ChapterLessonList>(
            find.byType(ChapterLessonList),
          );
          expect(list.rows.length, 2);
          final rows = list.rows.cast<ChapterLessonRow>();
          expect(rows.map((r) => r.number), ['2.1', '2.2']);
          expect(
            rows.first.kind,
            completedCount > 0
                ? ChapterRowKind.done
                : ChapterRowKind.recommended,
          );
          expect(
            rows.last.kind,
            completedCount == 2
                ? ChapterRowKind.done
                : completedCount == 1
                ? ChapterRowKind.recommended
                : ChapterRowKind.other,
          );
          final exercises = list.exercises! as ChapterLessonRow;
          expect(exercises.kind, ChapterRowKind.exercises);
          expect(exercises.number, '2.3');
          expect(exercises.title, 'Exercícios');
          expect(find.byType(Divider), findsOneWidget);
          expect(find.text('Aula hidden'), findsNothing);
          await tester.tap(find.byKey(CourseGuideKeys.chapterLesson(test.id)));
          expect(opened, same(test));
          opened = null;
          await tester.tap(find.byKey(CourseGuideKeys.chapterContinue));
          expect(
            opened,
            same(
              completedCount == 0
                  ? first
                  : completedCount == 1
                  ? second
                  : test,
            ),
          );
          await tester.tap(find.byType(BackButton));
          expect(backed, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
