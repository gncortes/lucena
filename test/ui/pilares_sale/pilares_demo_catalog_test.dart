import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/routing/route_names.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

TrainingLesson _lesson(
  String id,
  String chapter,
  String title, {
  String part = 'pilares.p1',
  String partTitle = 'Tática básica',
  TrainingLessonKind kind = TrainingLessonKind.theme,
  String group = '',
}) => TrainingLesson(
  id: id,
  kind: kind,
  title: title,
  groupId: chapter,
  group: group,
  partId: part,
  partTitle: partTitle,
);

/// O Catálogo da demonstração (H-VEN-11, `PropV2DemoCatalogoCompra`).
void main() {
  final lessons = [
    _lesson(
      'pilares.c1.garfo',
      'pilares.c1',
      'Garfo de cavalo',
      group: 'Ataque duplo e peças soltas',
    ),
    _lesson(
      'pilares.c1.duplo',
      'pilares.c1',
      'Ataque duplo',
      group: 'Ataque duplo e peças soltas',
    ),
    _lesson(
      'pilares.c1.solta',
      'pilares.c1',
      'Peça pendurada',
      group: 'Ataque duplo e peças soltas',
    ),
    _lesson(
      'pilares.c1.teste',
      'pilares.c1',
      'Ataque duplo e peças soltas',
      group: 'Ataque duplo e peças soltas',
      kind: TrainingLessonKind.test,
    ),
    _lesson('pilares.c2.a', 'pilares.c2', 'Cravada', group: 'Golpes em linha'),
    _lesson(
      'pilares.ab1.a',
      'pilares.ab1',
      'Italiana',
      group: 'Aberturas',
      kind: TrainingLessonKind.opening,
    ),
    _lesson(
      'pilares.c12.a',
      'pilares.c12',
      'Coluna aberta',
      group: 'Casas e colunas',
      part: 'pilares.p3',
      partTitle: 'Jogo posicional',
    ),
    _lesson(
      'pilares.c9.a',
      'pilares.c9',
      'Peão isolado',
      group: 'Fraquezas de peões',
      part: 'pilares.p3',
      partTitle: 'Jogo posicional',
    ),
    // Capítulo ainda não publicado: a linha com o cadeado aparece igual.
    const TrainingLesson(
      id: 'pilares.c20',
      kind: TrainingLessonKind.test,
      title: 'Cálculo de variantes',
      groupId: 'pilares.c20',
      partId: 'pilares.p5',
      visible: false,
      published: false,
    ),
  ];

  late List<String> chapters;
  late List<String> opened;

  Future<void> pump(
    WidgetTester tester, {
    CourseAccess access = CourseAccess.demo,
    Set<String> done = const {},
  }) async {
    chapters = [];
    opened = [];
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
          tab: CourseGuideTab.catalog,
          completedLessons: {for (final id in done) id: '2026-11-03'},
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
              onLesson: (lesson) => opened.add(lesson.id),
              onChapter: chapters.add,
              goalsBuilder: (_) => const SizedBox(),
              progressBuilder: (_) => const SizedBox(),
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
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        courseAccessRepository: FakeCourseAccessRepository(access),
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('demo: Capítulo 1 grátis, com anúncio, e o cartão do topo', (
    tester,
  ) async {
    await pump(tester, done: {'pilares.c1.garfo'});
    expect(find.byKey(PurchaseKeys.demoCatalogBanner), findsOneWidget);
    expect(find.text('Capítulo 1 liberado para você'), findsOneWidget);
    expect(find.text('1 de 4 concluídos'), findsOneWidget);
    expect(find.text('Grátis'), findsOneWidget);
    // Cada item do Capítulo 1 avisa que começa com um anúncio.
    for (final id in [
      'pilares.c1.garfo',
      'pilares.c1.duplo',
      'pilares.c1.solta',
      'pilares.c1.teste',
    ]) {
      final tile = find.byKey(CourseGuideKeys.chapterLesson(id));
      await scrollTo(tester, tile);
      expect(
        find.descendant(of: tile, matching: find.text('Começa com um anúncio')),
        findsOneWidget,
      );
    }
    expect(find.text('Teste do capítulo'), findsOneWidget);
    // O filtro do Catálogo do comprador não aparece na demo.
    expect(find.byKey(TrainingGoalKeys.catalogFilter), findsNothing);
    expect(find.byKey(CourseGuideKeys.helpAction), findsNothing);
    await tester.ensureVisible(
      find.byKey(CourseGuideKeys.chapterLesson('pilares.c1.duplo')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CourseGuideKeys.chapterLesson('pilares.c1.duplo')),
    );
    await tester.pump();
    expect(opened, ['pilares.c1.duplo']);
  });

  testWidgets('demo: os outros capítulos têm cadeado, por parte, na ordem', (
    tester,
  ) async {
    await pump(tester);
    await scrollTo(tester, find.byKey(PurchaseKeys.demoCatalogLearnMore));
    expect(find.text('NO CURSO COMPLETO'), findsOneWidget);
    expect(find.text('Parte I'), findsOneWidget);
    expect(find.text('Parte III'), findsOneWidget);
    expect(find.text('Parte V'), findsOneWidget);
    for (final n in [2, 12, 9, 20]) {
      expect(find.byKey(PurchaseKeys.demoCatalogLockedChapter(n)), findsOne);
    }
    expect(find.text('Capítulo 2 · Golpes em linha'), findsOneWidget);
    expect(find.text('Capítulo 20 · Cálculo de variantes'), findsOneWidget);
    // Aberturas não entram na lista de capítulos.
    expect(find.textContaining('Aberturas'), findsNothing);
    final y12 = tester
        .getTopLeft(find.byKey(PurchaseKeys.demoCatalogLockedChapter(12)))
        .dy;
    final y9 = tester
        .getTopLeft(find.byKey(PurchaseKeys.demoCatalogLockedChapter(9)))
        .dy;
    expect(y12, lessThan(y9));
    expect(
      find.text(
        'O Pilares tem 105 lições em 20 capítulos e mais de 850 exercícios.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('demo: o cadeado pede o capítulo (a folha de compra)', (
    tester,
  ) async {
    await pump(tester);
    await scrollTo(
      tester,
      find.byKey(PurchaseKeys.demoCatalogLockedChapter(2)),
    );
    await tester.ensureVisible(
      find.byKey(PurchaseKeys.demoCatalogLockedChapter(2)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PurchaseKeys.demoCatalogLockedChapter(2)));
    await tester.pump();
    expect(chapters, ['pilares.c2']);
  });

  testWidgets('demo: "Conhecer o Pilares" abre a apresentação', (tester) async {
    await pump(tester);
    await scrollTo(tester, find.byKey(PurchaseKeys.demoCatalogLearnMore));
    await tester.tap(find.byKey(PurchaseKeys.demoCatalogLearnMore));
    await tester.pumpAndSettle();
    expect(find.text('apresentação catalogo'), findsOneWidget);
  });

  testWidgets('comprador não vê nenhuma marca da demo', (tester) async {
    await pump(tester, access: CourseAccess.owned);
    expect(find.byKey(PurchaseKeys.demoCatalogBanner), findsNothing);
    expect(find.text('Grátis'), findsNothing);
    expect(find.text('Começa com um anúncio'), findsNothing);
    expect(find.text('NO CURSO COMPLETO'), findsNothing);
    expect(find.byKey(PurchaseKeys.demoCatalogLearnMore), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
  });
}
