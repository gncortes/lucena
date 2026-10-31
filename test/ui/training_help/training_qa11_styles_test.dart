import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/animated_progress.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';
import 'package:lucena/ui/training_help/widgets/training_help_screen.dart';
import 'package:lucena/ui/training_help/widgets/training_tour.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

Future<CourseGuideCubit> guide() async {
  final repo = FakeTrainingRepository(
    content: {
      TrainingCourse.pilares: TrainingResources(
        lessons: [
          const TrainingLesson(
            id: 'theme',
            kind: TrainingLessonKind.theme,
            title: 'Tema',
          ),
        ],
      ),
    },
    states: {
      TrainingCourse.pilares: TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'qa11',
        tab: CourseGuideTab.progress,
        cycles: {
          'theme': ThemeCycle(
            lessonId: 'theme',
            startedOn: '2026-10-20',
            days: [
              const ThemeDay(
                date: '2026-10-20',
                exerciseId: 'e1',
                stars: 1,
                correct: true,
              ),
            ],
          ),
        },
      ),
    },
  );
  final cubit = CourseGuideCubit(
    repository: repo,
    config: TrainingCourseConfig.pilares,
    now: FakeNow(DateTime(2026, 10, 29)),
  );
  addTearDown(repo.dispose);
  addTearDown(cubit.close);
  await cubit.load();
  return cubit;
}

void main() {
  setUpAll(Goldens.loadFonts);
  for (final size in phoneSizes) {
    testWidgets('progress typography and neutral rail at $size', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      final cubit = await guide();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: BlocProvider.value(
            value: cubit,
            child: Scaffold(body: TrainingProgressTab(onTheme: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(TrainingProgressTab));
      final t = context.l10n;
      expect(
        tester.widget<Text>(find.text(t.trainingMasteryNote)).style!.fontSize,
        12,
      );
      expect(
        tester.widget<Text>(find.text('Tema')).style!.fontWeight,
        FontWeight.w500,
      );
      expect(
        tester
            .widget<Text>(find.text(t.trainingCycleDays(1)))
            .style!
            .fontWeight,
        FontWeight.w500,
      );
      expect(
        tester
            .widget<AnimatedProgress>(find.byType(AnimatedProgress))
            .backgroundColor,
        Theme.of(context).scaffoldBackgroundColor,
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('help tour action remains 52 and calls host at $size', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      var opened = false;
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: TrainingHelpScreen(onBack: () {}, onTour: () => opened = true),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(TrainingKeys.helpTour);
      expect(tester.getSize(button).height, 52);
      await tester.tap(button);
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'four tour steps use Canvas title/button and external close at $size',
      (tester) async {
        setPhoneSize(tester, size);
        final cubit = await guide();
        var closed = false;
        final shell = CourseGuideScreen(
          onBack: () {},
          onPlan: () {},
          onHelp: () {},
          onWelcomeContinue: () {},
          onLesson: (_) {},
          onChapter: (_) {},
          goalsBuilder: (_) => const SizedBox(),
          progressBuilder: (_) => const SizedBox(),
        );
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: Material(
                child: TrainingTour(
                  child: shell,
                  onTab: (tab) => cubit.selectTab(tab),
                  onClose: () => closed = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final t = tester.element(find.byType(TrainingTour)).l10n;
        final titles = [
          t.courseGuideTour1Title,
          t.courseGuideTour2Title,
          t.courseGuideTour3Title,
          t.courseGuideTour4Title,
        ];
        for (var step = 0; step < 4; step++) {
          final title = find
              .descendant(
                of: find.byType(Semantics),
                matching: find.text(titles[step]),
              )
              .last;
          final text = tester.widget<Text>(title);
          expect(text.style!.fontSize, 20);
          expect(text.style!.height, 1.2);
          expect(text.style!.fontWeight, FontWeight.w500);
          final next = find.byKey(TrainingKeys.tourNext);
          expect(tester.getSize(next), const Size(140, 52));
          final close = tester.getRect(find.byKey(TrainingKeys.tourClose));
          final panel = tester.getRect(
            find.ancestor(of: title, matching: find.byType(Material)).first,
          );
          expect(close.size, const Size(48, 48));
          expect(close.bottom, lessThan(panel.top));
          expect(
            close.overlaps(
              tester.getRect(find.byKey(CourseGuideKeys.helpAction)),
            ),
            isFalse,
          );
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(closed, isTrue);
        expect(cubit.state.training!.tourSeen, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
