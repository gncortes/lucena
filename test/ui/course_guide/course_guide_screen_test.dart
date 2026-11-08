import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_continue_card.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  for (final size in phoneSizes) {
    testWidgets(
      'boas-vindas em ${size.width.toInt()} mantém quatro abas e Continuar',
      (tester) async {
        setPhoneSize(tester, size);
        final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
        final repository = FakeTrainingRepository(
          content: {TrainingCourse.pilares: scenario.content},
        );
        final cubit = CourseGuideCubit(
          repository: repository,
          config: TrainingCourseConfig.pilares,
          now: scenario.now,
        );
        addTearDown(cubit.close);
        addTearDown(repository.dispose);
        await cubit.load();
        var continued = false;
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: CourseGuideScreen(
                onBack: () {},
                onPlan: () {},
                onHelp: () {},
                onWelcomeContinue: () => continued = true,
                onLesson: (_) {},
                onChapter: (_) {},
                goalsBuilder: (_) => const SizedBox(),
                progressBuilder: (_) => const SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Boas-vindas ao Pilares do Xadrez'), findsOneWidget);
        for (final tab in CourseGuideTab.values) {
          expect(find.byKey(CourseGuideKeys.tab(tab.name)), findsOneWidget);
        }
        await tester.scrollUntilVisible(
          find.byKey(CourseGuideKeys.continueButton),
          150,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(CourseGuideKeys.continueButton));
        expect(continued, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'aba Aula e Catálogo em ${size.width.toInt()} usam curso real e preservam navegação',
      (tester) async {
        setPhoneSize(tester, size);
        final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
        final repository = scenario.repository(scenario.large());
        final cubit = CourseGuideCubit(
          repository: repository,
          config: TrainingCourseConfig.pilares,
          now: scenario.now,
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
        expect(find.byType(CourseContinueCard), findsOneWidget);
        expect(find.text('Tema 9'), findsOneWidget);
        expect(find.text('Dicas de estudo'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(CourseGuideKeys.seeCatalog),
          150,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(CourseGuideKeys.seeCatalog));
        await tester.pumpAndSettle();
        expect(cubit.state.training!.tab, CourseGuideTab.catalog);
        expect(find.text('Catálogo'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('curso ausente mostra indisponibilidade sem inventar conteúdo', (
    tester,
  ) async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = FakeTrainingRepository(
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'x',
        ),
      },
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: scenario.now,
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
    expect(find.byType(CourseContinueCard), findsNothing);
    expect(find.byKey(CourseGuideKeys.continueButton), findsNothing);
  });
}
