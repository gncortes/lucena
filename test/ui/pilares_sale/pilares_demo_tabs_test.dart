import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/demo_goals.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/route_names.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';
import 'package:lucena/ui/pilares_sale/widgets/pilares_demo_tabs.dart';

import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

TrainingLesson _lesson(String id, String chapter, String title) =>
    TrainingLesson(
      id: id,
      kind: TrainingLessonKind.theme,
      title: title,
      groupId: chapter,
      group: 'Ataque duplo e peças soltas',
      partId: 'pilares.p1',
      partTitle: 'Tática básica',
    );

/// Guia, Metas e Estatísticas da demonstração (H-VEN-12).
void main() {
  final lessons = [
    _lesson('pilares.c1.garfo', 'pilares.c1', 'Garfo de cavalo'),
    _lesson('pilares.c1.duplo', 'pilares.c1', 'Ataque duplo'),
    _lesson('pilares.c2.a', 'pilares.c2', 'Cravada'),
  ];

  group('DemoGoals', () {
    test('só lição do Capítulo 1 fica aberta', () {
      bool locked(GoalKind kind, String ref) =>
          DemoGoals.isLocked(TrainingGoal(kind: kind, ref: ref));
      expect(locked(GoalKind.lesson, 'pilares.c1.garfo'), isFalse);
      expect(locked(GoalKind.extraLesson, 'pilares.c1.duplo'), isFalse);
      expect(locked(GoalKind.lesson, 'pilares.c1'), isFalse);
      expect(locked(GoalKind.lesson, 'pilares.c2.a'), isTrue);
      expect(locked(GoalKind.exercise, 'pilares.c1.garfo'), isTrue);
      expect(locked(GoalKind.reinforce, 'pilares.c1.garfo'), isTrue);
      expect(locked(GoalKind.openings, 'pilares.ab1'), isTrue);
      expect(locked(GoalKind.bot, 'coco'), isTrue);
    });

    test('o selo conta só as metas abertas: 1, ou 0 com tudo feito', () {
      TrainingState state({bool done = false}) => TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'demo',
        day: DayGoals(
          date: '2026-11-04',
          studyDay: true,
          goals: [
            TrainingGoal(
              kind: GoalKind.lesson,
              ref: 'pilares.c1.duplo',
              done: done,
            ),
            TrainingGoal(kind: GoalKind.exercise, ref: 'pilares.c1.garfo'),
          ],
        ),
      );
      expect(DemoGoals.counts(state()), (total: 1, remaining: 1));
      expect(DemoGoals.counts(state(done: true)), (total: 1, remaining: 0));
    });
  });

  late FakeAnalyticsRepository analytics;
  late List<String> goals;

  Future<void> pump(
    WidgetTester tester, {
    required CourseGuideTab tab,
    CourseAccess access = CourseAccess.demo,
    bool nextDay = true,
  }) async {
    goals = [];
    analytics = FakeAnalyticsRepository();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    const config = TrainingCourseConfig.pilares;
    final repository = FakeTrainingRepository(
      content: {config.course: TrainingResources(lessons: lessons)},
      states: {
        config.course: TrainingState(
          course: config.course,
          installSeed: 'demo',
          onboardingDone: true,
          tab: tab,
          completedLessons: nextDay ? {'pilares.c1.garfo': '2026-11-03'} : {},
          day: DayGoals(
            date: '2026-11-04',
            studyDay: true,
            goals: [
              TrainingGoal(
                kind: GoalKind.lesson,
                ref: nextDay ? 'pilares.c1.duplo' : 'pilares.c1.garfo',
              ),
              if (nextDay)
                TrainingGoal(kind: GoalKind.exercise, ref: 'pilares.c1.garfo'),
            ],
          ),
        ),
      },
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: config,
      now: FakeNow(DateTime(2026, 11, 4, 9)),
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    // O mesmo encaixe da rota do curso (training_routes.dart).
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider.value(
            value: cubit,
            child: CourseGuideScreen(
              onBack: () {},
              onPlan: () {},
              onHelp: () {},
              onWelcomeContinue: () {},
              onLesson: (_) {},
              onChapter: (_) {},
              goalsBuilder: (context) {
                final demo = PilaresDemo.isActive(context, config.course);
                return TrainingGoalsTab(
                  onGoal: (goal) => goals.add(goal.ref),
                  onPlan: () {},
                  onLockedGoal: demo
                      ? (_) => PilaresDemo.openLockedGoal(context)
                      : null,
                  lessonSummary: demo ? context.l10n.venDemoGoalsLesson : null,
                  footer: demo ? const PilaresDemoGoalsCallout() : null,
                );
              },
              progressBuilder: (context) => TrainingProgressTab(
                onTheme: (_) {},
                onOpenings: () {},
                onTest: (_) {},
                footer: PilaresDemo.isActive(context, config.course)
                    ? const PilaresDemoStatsCallout()
                    : null,
              ),
            ),
          ),
        ),
        GoRoute(
          name: RouteNames.pilaresPresentation,
          path: '/apresentacao',
          builder: (_, state) => Scaffold(
            body: Text('apresentação ${state.uri.queryParameters['origem']}'),
          ),
        ),
        GoRoute(
          path: D2Paths.pilaresPlan,
          builder: (_, state) => Scaffold(
            body: Text('plano ${state.uri.queryParameters['origem']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        courseAccessRepository: FakeCourseAccessRepository(access),
        analytics: analytics,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Map<String, Object?> offerSeen() =>
      analytics.eventsNamed('pilares_oferta_vista').single.params;

  testWidgets('Guia: exemplo com selo e 6 semanas; o rodapé abre o plano', (
    tester,
  ) async {
    await pump(tester, tab: CourseGuideTab.guide);
    expect(find.byKey(PurchaseKeys.demoGuide), findsOneWidget);
    expect(find.byKey(CourseGuideKeys.guideTab), findsNothing);
    expect(find.text('Seu plano até o torneio'), findsOneWidget);
    expect(find.text('Exemplo'), findsOneWidget);
    for (var week = 1; week <= 6; week++) {
      expect(find.text('Semana $week'), findsOneWidget);
    }
    expect(find.text('Capítulo 6 · Contra o defensor'), findsOneWidget);
    expect(
      offerSeen(),
      allOf(
        containsPair('origem', 'destino'),
        containsPair('destaque', 'plano_exemplo'),
      ),
    );
    await tester.tap(find.byKey(PurchaseKeys.demoGuidePlan));
    await tester.pumpAndSettle();
    expect(find.text('plano destino'), findsOneWidget);
  });

  testWidgets('Guia: "Conhecer o Pilares" abre a apresentação', (tester) async {
    await pump(tester, tab: CourseGuideTab.guide);
    await tapVisible(tester, find.byKey(PurchaseKeys.demoGuideLearnMore));
    expect(find.text('apresentação destino'), findsOneWidget);
  });

  testWidgets('Metas, dia zero: a lição grátis, "Falta" 1 e o selo 1', (
    tester,
  ) async {
    await pump(tester, tab: CourseGuideTab.goals, nextDay: false);
    final lesson = find.byKey(
      TrainingKeys.goalTile(GoalKind.lesson.name, 'pilares.c1.garfo'),
    );
    expect(
      find.descendant(
        of: lesson,
        matching: find.text('Capítulo 1 · Lição grátis'),
      ),
      findsOneWidget,
    );
    expect(find.text('Faltam 1 de 1'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('1')),
      findsOneWidget,
    );
    await tapVisible(tester, find.byKey(PurchaseKeys.demoGoalsLearnMore));
    expect(find.text('apresentação metas'), findsOneWidget);
  });

  testWidgets('Metas, dia seguinte: o exercício vem com cadeado e a folha', (
    tester,
  ) async {
    await pump(tester, tab: CourseGuideTab.goals);
    final locked = find.byKey(
      PurchaseKeys.demoGoalsLockedTile(
        GoalKind.exercise.name,
        'pilares.c1.garfo',
      ),
    );
    expect(
      find.descendant(of: locked, matching: find.byIcon(Icons.lock_rounded)),
      findsOneWidget,
    );
    // O selo e o resumo não contam a meta trancada.
    expect(find.text('Faltam 1 de 1'), findsOneWidget);
    await tapVisible(tester, locked);
    expect(goals, isEmpty);
    expect(find.text('Metas fazem parte do Pilares'), findsOneWidget);
    // "Agora não" fecha sem navegar.
    await tester.tap(find.byKey(PurchaseKeys.demoGoalsLockSheetLater));
    await tester.pumpAndSettle();
    expect(find.byKey(PurchaseKeys.demoGoalsLockSheet), findsNothing);
    expect(locked, findsOneWidget);
    // "Conhecer o Pilares" abre a apresentação.
    await tapVisible(tester, locked);
    await tester.tap(find.byKey(PurchaseKeys.demoGoalsLockSheetLearn));
    await tester.pumpAndSettle();
    expect(find.text('apresentação metas'), findsOneWidget);
  });

  testWidgets('Metas: a lição grátis abre normalmente', (tester) async {
    await pump(tester, tab: CourseGuideTab.goals);
    await tapVisible(
      tester,
      find.byKey(
        TrainingKeys.goalTile(GoalKind.lesson.name, 'pilares.c1.duplo'),
      ),
    );
    expect(goals, ['pilares.c1.duplo']);
  });

  testWidgets('Estatísticas: vazio da Treino mais a chamada, sem ações', (
    tester,
  ) async {
    await pump(tester, tab: CourseGuideTab.stats);
    expect(find.byKey(TrainingKeys.progressEmpty), findsOneWidget);
    expect(find.byKey(CourseGuideKeys.planAction), findsNothing);
    expect(
      offerSeen(),
      allOf(
        containsPair('origem', 'estatisticas'),
        containsPair('destaque', 'dominio'),
      ),
    );
    // O vazio não rola: a chamada fica fixa embaixo.
    await tester.tap(find.byKey(PurchaseKeys.demoStatsLearnMore));
    await tester.pumpAndSettle();
    expect(find.text('apresentação estatisticas'), findsOneWidget);
  });

  for (final tab in [
    CourseGuideTab.guide,
    CourseGuideTab.goals,
    CourseGuideTab.stats,
  ]) {
    testWidgets('comprador: ${tab.name} sem chamada e sem cadeado', (
      tester,
    ) async {
      await pump(tester, tab: tab, access: CourseAccess.owned);
      expect(find.text('Conhecer o Pilares'), findsNothing);
      expect(find.byKey(PurchaseKeys.demoGuide), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(analytics.eventsNamed('pilares_oferta_vista'), isEmpty);
    });
  }
}
