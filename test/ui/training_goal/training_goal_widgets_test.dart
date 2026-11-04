import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/goal/study_plan.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../course_guide/course_guide_catalog_layout_test.dart' show lesson;

Future<void> pump(
  WidgetTester tester, {
  required CourseGuideTab tab,
  TrainingObjective? objective,
  StudyPlan? plan,
}) async {
  setPhoneSize(tester, const Size(412, 917));
  const config = TrainingCourseConfig.pilares;
  final repository = FakeTrainingRepository(
    content: {
      config.course: TrainingResources(
        lessons: [
          lesson('a1', 'alpha'),
          lesson('b1', 'beta'),
          lesson('c1', 'gamma'),
        ],
      ),
    },
    states: {
      config.course: TrainingState(
        course: config.course,
        installSeed: 'goal',
        onboardingDone: true,
        tab: tab,
        objective: objective,
        studyPlan: plan,
      ),
    },
  );
  final cubit = CourseGuideCubit(
    repository: repository,
    config: config,
    now: FakeNow(DateTime(2026, 11, 4, 12)),
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
}

void main() {
  setUpAll(Goldens.loadFonts);

  testWidgets('sem objetivo, o Início convida a definir um', (tester) async {
    await pump(tester, tab: CourseGuideTab.lesson);
    expect(find.byKey(TrainingGoalKeys.goalCardDefine), findsOneWidget);
    expect(find.text('Definir meu objetivo'), findsOneWidget);
  });

  testWidgets('com torneio, o Início mostra os dias que faltam', (
    tester,
  ) async {
    await pump(
      tester,
      tab: CourseGuideTab.lesson,
      objective: const TrainingObjective(
        kind: ObjectiveKind.tournament,
        setOn: '2026-11-04',
        tournamentDate: '2026-11-14',
      ),
    );
    expect(find.byKey(TrainingGoalKeys.goalCard), findsWidgets);
    expect(find.byKey(TrainingGoalKeys.goalCardDefine), findsNothing);
    expect(find.text('Torneio em 10 dias'), findsOneWidget);
  });

  testWidgets('catálogo abre em Meu plano e o filtro mostra tudo', (
    tester,
  ) async {
    await pump(
      tester,
      tab: CourseGuideTab.catalog,
      objective: const TrainingObjective(
        kind: ObjectiveKind.tournament,
        setOn: '2026-11-04',
        tournamentDate: '2026-11-14',
      ),
      plan: StudyPlan(
        createdOn: '2026-11-04',
        chapterIds: const ['alpha'],
        weeks: [
          PlanWeek(
            start: '2026-11-04',
            end: '2026-11-10',
            chapterIds: const ['alpha'],
          ),
        ],
      ),
    );
    expect(find.byKey(TrainingGoalKeys.catalogFilter), findsOneWidget);
    expect(find.byKey(CourseGuideKeys.chapterLesson('a1')), findsOneWidget);
    expect(find.byKey(CourseGuideKeys.chapterLesson('b1')), findsNothing);
    expect(find.byKey(TrainingGoalKeys.catalogChangePlan), findsOneWidget);

    await tester.tap(find.byKey(TrainingGoalKeys.catalogFilterAll));
    await tester.pumpAndSettle();
    expect(find.byKey(CourseGuideKeys.chapterLesson('b1')), findsOneWidget);
    expect(find.byKey(TrainingGoalKeys.catalogChangePlan), findsNothing);
  });

  testWidgets('sem plano, o catálogo mostra tudo e sem filtro', (tester) async {
    await pump(tester, tab: CourseGuideTab.catalog);
    expect(find.byKey(TrainingGoalKeys.catalogFilter), findsNothing);
    expect(find.byKey(CourseGuideKeys.chapterLesson('b1')), findsOneWidget);
  });

  testWidgets('o ícone Sobre o Pilares abre a folha', (tester) async {
    await pump(tester, tab: CourseGuideTab.catalog);
    await tester.tap(find.byKey(TrainingGoalKeys.catalogAbout));
    await tester.pumpAndSettle();
    expect(find.text('Sobre o Pilares'), findsOneWidget);
  });
}
