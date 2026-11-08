import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';

import 'dart:async';

import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/ui/course_guide/view_models/training_plan_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_plan_screen.dart';

import '../../../testing/fakes/fake_push_repository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_chapter_screen.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/training_progress/widgets/training_theme_screen.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_progress_screen.dart';

import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  testWidgets('plan initial load has shimmer', (tester) async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = scenario.repository(scenario.large());
    final pending = Completer<void>();
    final cubit = TrainingPlanCubit(
      repository: repository,
      config: scenario.config,
      now: scenario.now,
      push: FakePushRepository(),
      beforeLoad: () => pending.future,
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    final loading = cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: TrainingPlanScreen(onBack: () {}, onSaved: () {}),
        ),
      ),
    );
    expect(find.byType(SkeletonBlock), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    pending.complete();
    await loading;
  });

  testWidgets('plan retries initial failure', (tester) async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = scenario.repository(scenario.large());
    var fail = true;
    final retry = Completer<void>();
    final cubit = TrainingPlanCubit(
      repository: repository,
      config: scenario.config,
      now: scenario.now,
      push: FakePushRepository(),
      beforeLoad: () async {
        if (fail) throw StateError('plan load');
        await retry.future;
      },
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: TrainingPlanScreen(onBack: () {}, onSaved: () {}),
        ),
      ),
    );
    expect(find.byType(LoadErrorScreen), findsOneWidget);
    fail = false;
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pump();
    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    retry.complete();
    await tester.pumpAndSettle();
    expect(cubit.state.ready, isTrue);
    expect(find.byType(LoadErrorScreen), findsNothing);
  });

  final screens = <String, Widget>{
    'guide': CourseGuideScreen(
      onBack: () {},
      onPlan: () {},
      onHelp: () {},
      onWelcomeContinue: () {},
      onLesson: (_) {},
      onChapter: (_) {},
      goalsBuilder: (_) => const SizedBox(),
      progressBuilder: (_) => const SizedBox(),
    ),
    'chapter': CourseChapterScreen(
      chapter: '',
      onBack: () {},
      onLesson: (_) {},
    ),
    'theme': TrainingThemeScreen(lessonId: 'theme1', onBack: () {}),
    'opening progress': TrainingOpeningProgressScreen(onTrain: (_, _) {}),
  };
  final failures = <Object, LoadErrorKind>{
    StateError('test load'): LoadErrorKind.generic,
    const LessonContentNetworkUnavailable(): LoadErrorKind.offline,
    const LessonContentStorageUnavailable(1024): LoadErrorKind.noSpace,
    const LessonContentNotFound(): LoadErrorKind.unavailable,
  };
  for (final failure in failures.entries) {
    for (final entry in screens.entries) {
      testWidgets(
        '${entry.key} ${failure.value} reports load failure and retries',
        (tester) async {
          final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
          final repository = scenario.repository(scenario.large());
          var fail = true;
          final cubit = CourseGuideCubit(
            repository: repository,
            config: TrainingCourseConfig.pilares,
            now: scenario.now,
            beforeLoad: () async {
              if (fail) throw failure.key;
            },
          );
          addTearDown(cubit.close);
          addTearDown(repository.dispose);
          await cubit.load();
          await tester.pumpWidget(
            TestApp(
              locale: const Locale('pt'),
              child: BlocProvider.value(
                value: cubit,
                child: Scaffold(body: entry.value),
              ),
            ),
          );
          expect(find.byType(LoadErrorScreen), findsOneWidget);
          expect(
            tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
            failure.value,
          );
          fail = false;
          await tester.tap(find.byKey(LoadErrorKeys.action));
          await tester.pumpAndSettle();
          expect(cubit.state.failed, isFalse);
          expect(cubit.state.resources, isNotNull);
          expect(find.byType(LoadErrorScreen), findsNothing);
        },
      );
    }
  }
}
