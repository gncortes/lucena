import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_continue_card.dart';
import 'package:lucena/ui/core/widgets/course/course_item_tile.dart';
import 'package:lucena/ui/core/widgets/course/course_part_header.dart';
import 'package:lucena/ui/core/widgets/placement_test_card.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

TrainingLesson lesson(
  String id,
  String chapter, {
  bool test = false,
  String part = 'z',
}) => TrainingLesson(
  id: id,
  kind: test ? TrainingLessonKind.test : TrainingLessonKind.theme,
  title: test ? 'Teste $id' : 'Aula $id',
  partId: part,
  partTitle: part == 'z' ? 'Primeira parte' : 'Segunda parte',
  groupId: chapter,
  group: 'Capítulo $chapter',
);

Future<CourseGuideCubit> pumpGuide(
  WidgetTester tester, {
  CourseGuideTab tab = CourseGuideTab.catalog,
  Set<String> done = const {'a1', 'a2', 't1'},
  TrainingCourseConfig config = TrainingCourseConfig.pilares,
  VoidCallback? onLevelTest,
}) async {
  final resources = TrainingResources(
    lessons: [
      lesson('a1', 'omega'),
      lesson('a2', 'omega'),
      lesson('t1', 'omega', test: true),
      lesson('b1', 'alpha'),
      lesson('b2', 'alpha'),
      lesson('t2', 'alpha', test: true),
      lesson('c1', 'gamma', part: 'a'),
    ],
  );
  final repository = FakeTrainingRepository(
    content: {config.course: resources},
    states: {
      config.course: TrainingState(
        course: config.course,
        installSeed: 'layout',
        onboardingDone: true,
        tab: tab,
        completedLessons: {for (final id in done) id: '2026-10-28'},
      ),
    },
  );
  final cubit = CourseGuideCubit(
    repository: repository,
    config: config,
    now: FakeNow(DateTime(2026, 10, 29, 12)),
  );
  addTearDown(cubit.close);
  addTearDown(repository.dispose);
  await cubit.load();
  await tester.pumpWidget(
    TestApp(
      locale: const Locale('pt'),
      child: BlocProvider.value(
        value: cubit,
        child: CourseGuideScreen(
          onLevelTest: onLevelTest,
          onBack: () {},
          onPlan: () {},
          onHelp: () {},
          onWelcomeContinue: () {},
          onLesson: (_) {},
          onChapter: (_) {},
          goalsBuilder: (_) => const SizedBox(),
          progressBuilder: (_) => const SizedBox(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  setUpAll(Goldens.loadFonts);
  for (final size in phoneSizes) {
    testWidgets('catalog counts chapters and numbers real order at $size', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      var opened = 0;
      final cubit = await pumpGuide(tester, onLevelTest: () => opened++);
      expect(find.byType(PlacementTestCard), findsOneWidget);
      await tester.tap(find.byKey(CourseGuideKeys.levelTest));
      expect(opened, 1);
      expect(cubit.state.training!.completedLessons.length, 3);
      final header = tester.widget<CoursePartHeader>(
        find.byType(CoursePartHeader).first,
      );
      expect(header.label, 'Parte I');
      expect(header.title, 'Primeira parte');
      expect(header.count, '1 de 2');
      expect(
        tester
            .widget<CourseItemTile>(
              find.byKey(CourseGuideKeys.chapter('omega')),
            )
            .title,
        '1 · Capítulo omega',
      );
      expect(
        tester
            .widget<CourseItemTile>(
              find.byKey(CourseGuideKeys.chapter('alpha')),
            )
            .title,
        '2 · Capítulo alpha',
      );
      await tester.scrollUntilVisible(
        find.byKey(CourseGuideKeys.catalogPart('a')),
        100,
      );
      expect(find.text('Parte II'), findsOneWidget);
      await tester.tap(find.byKey(CourseGuideKeys.catalogPart('a')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CoursePartHeader>(find.byType(CoursePartHeader).last)
            .label,
        'Parte II',
      );
      expect(cubit.state.training!.completedLessons.length, 3);
      expect(tester.takeException(), isNull);
    });
    testWidgets('lesson uses Roman part and catalog button is 52 at $size', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      await pumpGuide(tester, tab: CourseGuideTab.lesson);
      expect(
        tester
            .widget<CourseContinueCard>(find.byType(CourseContinueCard))
            .label,
        'Parte I · aula 3',
      );
      await tester.scrollUntilVisible(
        find.byKey(CourseGuideKeys.seeCatalog),
        100,
      );
      expect(tester.getSize(find.byKey(CourseGuideKeys.seeCatalog)).height, 52);
      expect(tester.takeException(), isNull);
    });
    testWidgets('real second part uses ordinal II at $size', (tester) async {
      setPhoneSize(tester, size);
      await pumpGuide(
        tester,
        tab: CourseGuideTab.lesson,
        done: {'a1', 'a2', 't1', 'b1', 'b2', 't2'},
      );
      expect(
        tester
            .widget<CourseContinueCard>(find.byType(CourseContinueCard))
            .label,
        'Parte II · aula 1',
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('chapter counts as approved only after its test at $size', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      await pumpGuide(tester, done: {'a1', 'a2'});
      expect(
        tester
            .widget<CoursePartHeader>(find.byType(CoursePartHeader).first)
            .count,
        '0 de 2',
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('pending test keeps its title without lesson zero at $size', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      await pumpGuide(tester, tab: CourseGuideTab.lesson, done: {'a1', 'a2'});
      final card = tester.widget<CourseContinueCard>(
        find.byType(CourseContinueCard),
      );
      expect(card.label, 'Parte I');
      expect(card.title, 'Teste t1');
      expect(tester.takeException(), isNull);
    });
  }
}
