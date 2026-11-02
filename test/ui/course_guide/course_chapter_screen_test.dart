import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_chapter_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('chapter opens only its real visible index lessons', (
    tester,
  ) async {
    const first = TrainingLesson(
      id: 'pilares.c1.part1',
      kind: TrainingLessonKind.theme,
      title: 'Primeira aula',
      groupId: 'c1',
      group: 'Primeiro capítulo',
      partTitle: 'Primeira parte',
    );
    const other = TrainingLesson(
      id: 'pilares.c2.part1',
      kind: TrainingLessonKind.theme,
      title: 'Outro capítulo',
      groupId: 'c2',
    );
    const hidden = TrainingLesson(
      id: 'pilares.c1.hidden',
      kind: TrainingLessonKind.theme,
      title: 'Aula oculta',
      groupId: 'c1',
      visible: false,
    );
    final repo = FakeTrainingRepository(
      content: {
        TrainingCourse.pilares: TrainingResources(
          lessons: [first, other, hidden],
        ),
      },
    );
    final cubit = CourseGuideCubit(
      repository: repo,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(DateTime(2026, 10, 26)),
    );
    addTearDown(cubit.close);
    addTearDown(repo.dispose);
    await cubit.load();
    TrainingLesson? opened;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: CourseChapterScreen(
            chapter: 'c1',
            onBack: () {},
            onLesson: (lesson) => opened = lesson,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Primeira aula'), findsOneWidget);
    expect(find.text('Outro capítulo'), findsNothing);
    expect(find.text('Aula oculta'), findsNothing);
    await tester.tap(find.byKey(CourseGuideKeys.chapterLesson(first.id)));
    expect(opened, same(first));
    opened = null;
    await tester.tap(find.byKey(CourseGuideKeys.chapterContinue));
    expect(opened, same(first));
  });
}
