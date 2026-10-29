import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/course/course_item_tile.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

void main() {
  setUpAll(Goldens.loadFonts);
  for (final size in phoneSizes) {
    for (final sample in ['done', 'zero', 'locked', 'open']) {
      testWidgets(
        'test card $sample uses operational points and actions at $size',
        (tester) async {
          setPhoneSize(tester, size);
          final repo = FakeTrainingRepository(
            content: {
              TrainingCourse.pilares: TrainingResources(
                lessons: const [
                  TrainingLesson(
                    id: 'prior',
                    kind: TrainingLessonKind.theme,
                    title: 'Primeira',
                    groupId: 'z',
                    partId: 'p',
                  ),
                  TrainingLesson(
                    id: 'required',
                    kind: TrainingLessonKind.theme,
                    title: 'Aula real',
                    groupId: 'random',
                    partId: 'p',
                  ),
                  TrainingLesson(
                    id: 'actual-test',
                    kind: TrainingLessonKind.test,
                    title: 'Teste real',
                    group: 'Capítulo real',
                    groupId: 'random',
                    partId: 'p',
                  ),
                ],
              ),
            },
            states: {
              TrainingCourse.pilares: TrainingState(
                course: TrainingCourse.pilares,
                installSeed: 'qa11',
                completedLessons: sample == 'open'
                    ? {'required': '2026-10-29'}
                    : const {},
              ),
            },
          );
          final cubit = CourseGuideCubit(
            repository: repo,
            config: TrainingCourseConfig.pilares,
            now: FakeNow(DateTime(2026, 10, 29)),
          );
          addTearDown(cubit.close);
          addTearDown(repo.dispose);
          await cubit.load();
          String? opened;
          var placement = false;
          await tester.pumpWidget(
            TestApp(
              locale: const Locale('pt'),
              child: BlocProvider.value(
                value: cubit,
                child: Scaffold(
                  body: TrainingProgressTab(
                    onTheme: (_) {},
                    onTest: (id) => opened = id,
                    onLevelTest: () => placement = true,
                    testProgress: {
                      if (sample == 'done')
                        'actual-test': (
                          score: 10,
                          maxScore: 12,
                          solved: 5,
                          total: 5,
                        ),
                      if (sample == 'zero')
                        'actual-test': (
                          score: 0,
                          maxScore: 12,
                          solved: 1,
                          total: 5,
                        ),
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final t = tester.element(find.byType(TrainingProgressTab)).l10n;
          final card = find.byKey(CourseGuideKeys.chapterLesson('actual-test'));
          await tester.ensureVisible(card);
          final tile = tester.widget<CourseItemTile>(card);
          expect(
            tile.title,
            t.trainingProgressChapterTitle(2, 'Capítulo real'),
          );
          expect(tile.state, switch (sample) {
            'done' => CourseItemState.approved,
            'zero' => CourseItemState.started,
            'locked' => CourseItemState.locked,
            _ => CourseItemState.open,
          });
          if (sample == 'done') {
            expect(find.text(t.trainingCount(12, 10)), findsOneWidget);
            expect(find.text(t.trainingTestDoneBody), findsOneWidget);
          } else if (sample == 'zero') {
            expect(find.text(t.trainingCount(12, 0)), findsOneWidget);
            expect(find.text(t.trainingTestsMissing), findsNothing);
          } else if (sample == 'locked') {
            expect(
              find.text(t.trainingTestLocked('Aula real')),
              findsOneWidget,
            );
            expect(tile.onTap, isNull);
          }
          await tester.tap(card);
          expect(opened, sample == 'locked' ? isNull : 'actual-test');
          final level = find.byKey(CourseGuideKeys.levelTest);
          await tester.ensureVisible(level);
          await tester.tap(level);
          expect(placement, isTrue);
          expect(find.text(t.trainingLevelTestOptional), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
