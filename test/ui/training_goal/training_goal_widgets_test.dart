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

Future<FakeTrainingRepository> pump(
  WidgetTester tester, {
  required CourseGuideTab tab,
  TrainingObjective? objective,
  StudyPlan? plan,
  StudyPlan? previous,
  bool? catalogOnlyPlan,
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
        previousStudyPlan: previous,
        catalogOnlyPlan: catalogOnlyPlan,
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
  return repository;
}

void main() {
  setUpAll(Goldens.loadFonts);

  testWidgets('sem objetivo, o Início convida a definir um', (tester) async {
    await pump(tester, tab: CourseGuideTab.lesson);
    expect(find.byKey(TrainingGoalKeys.goalCardDefine), findsOneWidget);
    expect(find.text('Definir meu objetivo'), findsOneWidget);
  });

  testWidgets('PropV2GuiaSemObjetivo: cartão com o estádio e o botão fixo '
      'embaixo, na largura toda', (tester) async {
    await pump(tester, tab: CourseGuideTab.guide);
    final card = find.byKey(TrainingGoalKeys.guideEmpty).first;
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.stadium_outlined)),
      findsOneWidget,
    );
    final button = tester.getRect(find.byKey(TrainingGoalKeys.guideDefine));
    expect(button.width, 412 - 32);
    expect(button.height, 52);
    expect(button.top, greaterThan(tester.getRect(card).bottom + 200));
    final title = tester.getRect(find.text('Qual é o seu objetivo?'));
    expect(title.left, tester.getRect(card).left + 24);
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

    // H-ANI-30 (PropV2FiltroA, CompSegmentado): "Todas" se enche em 200 ms.
    Color fundo(Key rotulo) => tester
        .widget<Material>(
          find
              .ancestor(of: find.byKey(rotulo), matching: find.byType(Material))
              .first,
        )
        .color!;
    final vazio = fundo(TrainingGoalKeys.catalogFilterAll);
    final cheio = fundo(TrainingGoalKeys.catalogFilterPlan);
    await tester.tap(find.byKey(TrainingGoalKeys.catalogFilterAll));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      fundo(TrainingGoalKeys.catalogFilterAll),
      isNot(anyOf(vazio, cheio)),
    );
    await tester.pumpAndSettle();
    expect(fundo(TrainingGoalKeys.catalogFilterAll), cheio);
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

  testWidgets('H-TRE-09: Voltar ao plano anterior troca o plano e some', (
    tester,
  ) async {
    StudyPlan plan(String id) => StudyPlan(
      createdOn: '2026-11-04',
      chapterIds: [id],
      weeks: [
        PlanWeek(start: '2026-11-04', end: '2026-11-10', chapterIds: [id]),
      ],
    );
    const objective = TrainingObjective(
      kind: ObjectiveKind.tournament,
      setOn: '2026-11-04',
      tournamentDate: '2026-11-14',
    );
    await pump(
      tester,
      tab: CourseGuideTab.guide,
      objective: objective,
      plan: plan('beta'),
      previous: plan('alpha'),
    );
    expect(find.byKey(TrainingGoalKeys.adjustUndo), findsOneWidget);
    expect(find.text('Voltar ao plano anterior'), findsOneWidget);
    await tester.tap(find.byKey(TrainingGoalKeys.adjustUndo));
    await tester.pumpAndSettle();
    expect(find.byKey(TrainingGoalKeys.adjustUndo), findsNothing);
  });

  testWidgets('o filtro do Catálogo fica salvo e volta ao reabrir', (
    tester,
  ) async {
    StudyPlan plan() => StudyPlan(
      createdOn: '2026-11-04',
      chapterIds: const ['alpha'],
      weeks: [
        PlanWeek(
          start: '2026-11-04',
          end: '2026-11-10',
          chapterIds: const ['alpha'],
        ),
      ],
    );
    const objective = TrainingObjective(
      kind: ObjectiveKind.tournament,
      setOn: '2026-11-04',
      tournamentDate: '2026-11-14',
    );
    final repository = await pump(
      tester,
      tab: CourseGuideTab.catalog,
      objective: objective,
      plan: plan(),
    );
    await tester.tap(find.byKey(TrainingGoalKeys.catalogFilterAll));
    await tester.pumpAndSettle();
    final saved = await repository.load(TrainingCourse.pilares);
    expect(saved.catalogOnlyPlan, isFalse);
    expect(TrainingState.fromJson(saved.toJson()).catalogOnlyPlan, isFalse);

    await pump(
      tester,
      tab: CourseGuideTab.catalog,
      objective: objective,
      plan: plan(),
      catalogOnlyPlan: false,
    );
    expect(find.byKey(CourseGuideKeys.chapterLesson('b1')), findsOneWidget);
  });
}
