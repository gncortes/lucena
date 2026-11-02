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
  ValueChanged<TrainingLesson>? onLesson,
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
          onLesson: onLesson ?? (_) {},
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
  testWidgets(
    'Escola preserves module and per-lesson catalog without level test',
    (tester) async {
      setPhoneSize(tester, const Size(412, 917));
      final cubit = await pumpGuide(
        tester,
        config: TrainingCourseConfig.escola,
      );
      expect(find.byType(PlacementTestCard), findsNothing);
      expect(find.text('MÓDULO 1 · CAPÍTULO OMEGA'), findsOneWidget);
      expect(find.byType(CoursePartHeader), findsNothing);
      expect(find.text('3 de 3'), findsNothing);
      expect(find.byKey(CourseGuideKeys.chapterLesson('a1')), findsOneWidget);
      expect(
        tester
            .widget<CourseItemTile>(
              find.byKey(CourseGuideKeys.chapterLesson('a1')),
            )
            .title,
        'Aula 1 · Aula a1',
      );
      await cubit.selectTab(CourseGuideTab.lesson);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CourseContinueCard>(find.byType(CourseContinueCard))
            .label,
        'Módulo 2 · aula 1',
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in phoneSizes) {
    testWidgets(
      'catalog orders chapters and opens lessons and tests at $size',
      (tester) async {
        setPhoneSize(tester, size);
        String? opened;
        final cubit = await pumpGuide(
          tester,
          onLesson: (lesson) => opened = lesson.id,
        );
        expect(find.byType(PlacementTestCard), findsNothing);
        expect(cubit.state.training!.completedLessons.length, 3);
        final header = tester.widget<CoursePartHeader>(
          find.byType(CoursePartHeader).first,
        );
        expect(header.label, 'Capítulo 1');
        expect(header.title, 'Capítulo omega');
        expect(header.count, isNull);
        expect(
          tester
              .widget<CourseItemTile>(
                find.byKey(CourseGuideKeys.chapterLesson('a1')),
              )
              .title,
          'Aula a1',
        );
        expect(
          tester
              .widget<CourseItemTile>(
                find.byKey(CourseGuideKeys.chapterLesson('t1')),
              )
              .title,
          'Teste do capítulo',
        );
        await tester.tap(find.byKey(CourseGuideKeys.chapterLesson('a1')));
        expect(opened, 'a1');
        await tester.tap(find.byKey(CourseGuideKeys.chapterLesson('t1')));
        expect(opened, 't1');
        await tester.scrollUntilVisible(
          find.byKey(CourseGuideKeys.chapter('gamma')),
          100,
        );
        expect(
          tester
              .widget<CoursePartHeader>(find.byType(CoursePartHeader).last)
              .label,
          'Capítulo 3',
        );
        expect(cubit.state.training!.completedLessons.length, 3);
        expect(tester.takeException(), isNull);
      },
    );
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
    testWidgets('test remains recommended after chapter lessons at $size', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      await pumpGuide(tester, done: {'a1', 'a2'});
      expect(
        tester
            .widget<CourseItemTile>(
              find.byKey(CourseGuideKeys.chapterLesson('t1')),
            )
            .state,
        CourseItemState.started,
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
