import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucena/ui/core/theme/canvas_symbols.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/repositories/push/push_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/training/training_history_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/routing/training_routes.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_course_training_repository.dart';
import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_now.dart';
import '../../testing/fakes/fake_push_repository.dart';
import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/goldens/golden_harness.dart';
import '../../testing/phone_size.dart';
import '../../testing/test_app.dart';

final now = FakeNow(DateTime(2026, 10, 29, 12));
TrainingResources resources() => TrainingResources(
  lessons: [
    for (final id in ['active', 'done', 'firm'])
      TrainingLesson(
        id: id,
        kind: TrainingLessonKind.opening,
        title: 'Abertura $id',
      ),
  ],
  openings: {
    for (final id in ['active', 'done', 'firm'])
      id: [
        OpeningTrecho(
          id: 't1',
          title: 'Trecho 1',
          moves: ['e2e4', 'e7e5', 'g1f3'],
        ),
        OpeningTrecho(
          id: 't2',
          title: 'Trecho 2',
          moves: ['d2d4', 'd7d5', 'c1f4'],
        ),
      ],
  },
);
FakeTrainingRepository initialRepository() => FakeTrainingRepository(
  content: {TrainingCourse.pilares: resources()},
  states: {
    TrainingCourse.pilares: TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 'opening-shell',
      onboardingDone: true,
      tab: CourseGuideTab.catalog,
      completedLessons: {
        for (final id in ['active', 'done', 'firm']) id: '2026-10-28',
      },
      day: DayGoals(
        date: '2026-10-29',
        studyDay: true,
        goals: [
          TrainingGoal(
            kind: GoalKind.openings,
            ref: 'openings',
            items: {'active': 't1', 'done': 't1'},
          ),
        ],
      ),
      openings: {
        for (final id in ['active', 'done', 'firm'])
          id: OpeningTrack(
            lessonId: id,
            startedOn: '2026-10-28',
            doneTrechos: id == 'active'
                ? {}
                : {
                    't1': id == 'done' ? '2026-10-29' : '2026-10-28',
                    if (id == 'firm') 't2': '2026-10-28',
                  },
          ),
      },
    ),
  },
);

Future<({GoRouter router, FakeTrainingRepository repository})> showShell(
  WidgetTester tester, {
  Size size = const Size(412, 917),
  FakeTrainingRepository? repository,
  String initialPath = '/training/pilares/openings',
}) async {
  setPhoneSize(tester, size);
  final repo = repository ?? initialRepository();
  final settings = SettingsCubit(
    FakeSettingsRepository(),
    languages: AppLanguage.selectable,
  );
  await settings.load();
  final router = GoRouter(
    initialLocation: initialPath,
    routes: [trainingRoute()],
  );
  addTearDown(repo.dispose);
  addTearDown(settings.close);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TrainingRepository>.value(value: repo),
        RepositoryProvider<TrainingHistorySource>.value(
          value: TrainingHistorySource(repo, learning: null, now: now),
        ),
        RepositoryProvider<EndgameLessonRepository>.value(
          value: FakeEndgameLessonRepository(),
        ),
        RepositoryProvider<EndgameProgressRepository>.value(
          value: FakeEndgameProgressRepository(),
        ),
        RepositoryProvider<Now>.value(value: now),
        RepositoryProvider<CharacterRepository>.value(
          value: FakeCharacterRepository(),
        ),
        RepositoryProvider<PushRepository>.value(
          value: FakePushRepository(allowed: true),
        ),
      ],
      child: TestApp(
        trainingAccess: true,
        settingsCubit: settings,
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, repository: repo);
}

void main() {
  setUpAll(Goldens.loadFonts);
  for (final size in phoneSizes) {
    testWidgets(
      'opening list uses guide chrome and aligned accessible cards at $size',
      (tester) async {
        final host = await showShell(tester, size: size);
        expect(find.byKey(TrainingKeys.openingsScreen), findsOneWidget);
        final bar = tester.widget<AppBar>(find.byType(AppBar));
        expect(bar.centerTitle, isFalse);
        expect(find.byKey(CourseGuideKeys.planAction), findsOneWidget);
        expect(find.byKey(CourseGuideKeys.helpAction), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          CourseGuideTab.goals.index,
        );
        expect(
          tester
              .widget<Badge>(find.byKey(CourseGuideKeys.goalsBadge))
              .isLabelVisible,
          isTrue,
        );
        expect(
          (await host.repository.load(TrainingCourse.pilares)).tab,
          CourseGuideTab.goals,
        );
        final card = find.byKey(TrainingKeys.openingCard('active'));
        final cta = find.byKey(TrainingKeys.trainTrecho('active'));
        expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
        expect(
          find.descendant(
            of: cta,
            matching: find.byIcon(CanvasSymbols.chevronRight),
          ),
          findsOneWidget,
        );
        final label = find.text('Treinar a parte 1');
        expect(
          tester.getTopLeft(label).dx,
          closeTo(tester.getTopLeft(find.text('Abertura active')).dx, .01),
        );
        final segments = tester
            .widgetList<Container>(
              find.descendant(of: card, matching: find.byType(Container)),
            )
            .where((c) => c.constraints?.maxHeight == 28)
            .toList();
        expect(
          (segments.last.decoration! as BoxDecoration).color,
          const Color(0xfff5f7f4),
        );
        await tester.scrollUntilVisible(find.text('Parte de hoje feita'), 100);
        final done = find.text('Parte de hoje feita');
        expect(tester.widget<Text>(done).style!.color, AppColors.record);
        final row = find.ancestor(of: done, matching: find.byType(Row)).first;
        expect(
          find.descendant(
            of: row,
            matching: find.byIcon(Icons.check_circle_outline),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'firm opening keeps its status when a daily review is available',
    (tester) async {
      final repo = initialRepository();
      await repo.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(
          day: s.day!.copyWith(
            goals: [
              for (final goal in s.day!.goals)
                TrainingGoal(
                  kind: goal.kind,
                  ref: goal.ref,
                  items: {...goal.items, 'firm': 't1'},
                ),
            ],
          ),
        ),
      );
      await showShell(tester, repository: repo);
      final card = find.byKey(TrainingKeys.openingCard('firm'));
      await tester.scrollUntilVisible(card, 200);
      expect(
        find.descendant(
          of: card,
          matching: find.text('Todas as partes feitas · só revisão'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(TrainingKeys.trainTrecho('firm')), findsOneWidget);
    },
  );
  testWidgets('tab exit awaits durable write and survives a fresh repository', (
    tester,
  ) async {
    final host = await showShell(tester);
    final gate = Completer<void>();
    host.repository.beforeSave = gate.future;
    await tester.tap(find.byKey(CourseGuideKeys.tab('catalog')));
    await tester.pump();
    expect(
      host.router.routeInformationProvider.value.uri.path,
      '/training/pilares/openings',
    );
    expect(find.byKey(TrainingKeys.openingsScreen), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      host.router.routeInformationProvider.value.uri.path,
      Routes.training('pilares'),
    );
    expect(find.byKey(TrainingKeys.openingsScreen), findsNothing);
    final disk = TrainingState.fromJson(
      (await host.repository.load(TrainingCourse.pilares)).toJson(),
    );
    expect(disk.tab, CourseGuideTab.catalog);
    final restarted = FakeTrainingRepository(
      states: {TrainingCourse.pilares: disk},
      content: {TrainingCourse.pilares: resources()},
    );
    await showShell(
      tester,
      repository: restarted,
      initialPath: Routes.training('pilares'),
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      CourseGuideTab.catalog.index,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed tab write keeps list open; back returns to goals', (
    tester,
  ) async {
    final host = await showShell(tester);
    host.repository.writeError = StateError('disk unavailable');
    await tester.tap(find.byKey(CourseGuideKeys.tab('lesson')));
    await tester.pumpAndSettle();
    expect(
      host.router.routeInformationProvider.value.uri.path,
      '/training/pilares/openings',
    );
    host.repository.writeError = null;
    await tester.tap(find.byKey(CourseGuideKeys.back));
    await tester.pumpAndSettle();
    expect(
      host.router.routeInformationProvider.value.uri.path,
      Routes.training('pilares'),
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      CourseGuideTab.goals.index,
    );
    expect(
      (await host.repository.load(TrainingCourse.pilares)).tab,
      CourseGuideTab.goals,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'plan action preserves list and completed segment refreshes it on return',
    (tester) async {
      final host = await showShell(tester);
      await tester.tap(find.byKey(CourseGuideKeys.planAction));
      await tester.pumpAndSettle();
      expect(
        GoRouterState.of(tester.element(find.byKey(TrainingKeys.planScreen)))
            .uri
            .path,
        Routes.trainingPlan('pilares'),
      );
      await tester.tap(find.byIcon(CanvasSymbols.arrowBack));
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.openingsScreen), findsOneWidget);
      await tester.tap(find.byKey(TrainingKeys.trainTrecho('active')));
      await tester.pumpAndSettle();
      expect(
        GoRouterState.of(tester.element(find.byKey(TrainingKeys.openingBoard)))
            .uri
            .path,
        Routes.trainingOpening('pilares', 'active'),
      );
      final opening = tester
          .element(find.byKey(TrainingKeys.openingBoard))
          .read<TrainingOpeningCubit>();
      await opening.play('e2e4');
      await opening.play('g1f3');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CanvasSymbols.arrowBack));
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.openingsScreen), findsOneWidget);
      expect(find.byKey(TrainingKeys.trainTrecho('active')), findsNothing);
      expect(
        (await host.repository.load(TrainingCourse.pilares))
            .openings['active']!
            .doneTrechos['t1'],
        '2026-10-29',
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        CourseGuideTab.goals.index,
      );
      final disk = TrainingState.fromJson(
        (await host.repository.load(TrainingCourse.pilares)).toJson(),
      );
      await showShell(
        tester,
        repository: FakeTrainingRepository(
          states: {TrainingCourse.pilares: disk},
          content: {TrainingCourse.pilares: resources()},
        ),
      );
      expect(find.byKey(TrainingKeys.openingsScreen), findsOneWidget);
      expect(find.byKey(TrainingKeys.trainTrecho('active')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(TrainingKeys.openingCard('active')),
          matching: find.text('Parte de hoje feita'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
