import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/school_training_progress.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_item_tile.dart';
import 'package:lucena/ui/core/widgets/course/piece_stars_row.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/view_models/training_plan_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';
import 'package:lucena/ui/course_guide/widgets/training_plan_screen.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

// Presentation fixture: real follow-up IDs; synthetic unrelated lessons and
// module names deliberately avoid copying private lesson content.
TrainingResources resources() => TrainingResources(
  lessons: [
    for (final piece in ChallengePiece.values)
      TrainingLesson(
        id: 'pieces.${piece.name}',
        kind: TrainingLessonKind.school,
        title: 'Aula ${piece.name}',
        groupId: 'pieces',
        group: 'Peças',
      ),
    for (final id in ['mates.twoRooks', 'mates.queen'])
      TrainingLesson(
        id: id,
        kind: TrainingLessonKind.school,
        title: 'Aula $id',
        groupId: 'firstMates',
        group: 'Mates',
      ),
    for (var n = 0; n < 29; n++)
      TrainingLesson(
        id: 'fixture.$n',
        kind: TrainingLessonKind.school,
        title: 'Aula $n',
        groupId: 'fixture.module.${n % 6}',
        group: 'Grupo ${n % 6}',
      ),
    const TrainingLesson(
      id: 'hidden',
      kind: TrainingLessonKind.school,
      title: 'Oculta',
      groupId: 'hidden',
      group: 'Oculto',
      visible: false,
    ),
  ],
);

void main() {
  for (final size in phoneSizes) {
    Future<CourseGuideCubit> show(
      WidgetTester tester,
      TrainingScenarioBuilder scenario,
      TrainingState state, {
      ValueChanged<TrainingGoal>? onGoal,
    }) async {
      setPhoneSize(tester, size);
      final repository = scenario.repository(state);
      final cubit = CourseGuideCubit(
        repository: repository,
        config: scenario.config,
        now: scenario.now,
      );
      addTearDown(cubit.close);
      addTearDown(repository.dispose);
      await cubit.load();
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: const [],
      );
      addTearDown(settings.close);
      await settings.load();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: BlocProvider.value(
            value: cubit,
            child: CourseGuideScreen(
              onBack: () {},
              onPlan: () {},
              onHelp: () {},
              onWelcomeContinue: () {},
              onLesson: (_) {},
              onChapter: (_) {},
              goalsBuilder: (_) =>
                  TrainingGoalsTab(onGoal: onGoal ?? (_) {}, onPlan: () {}),
              progressBuilder: (_) => TrainingProgressTab(onTheme: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return cubit;
    }

    testWidgets('School welcome, lesson and catalog share shell at $size', (
      tester,
    ) async {
      final scenario = TrainingScenarioBuilder(
        TrainingCourse.escola,
        resources: resources(),
      );
      final cubit = await show(
        tester,
        scenario,
        TrainingState(course: scenario.course, installSeed: 'welcome'),
      );
      expect(find.text('Escola do Viktor'), findsOneWidget);
      expect(find.text('Boas-vindas à Escola do Viktor'), findsOneWidget);
      for (final phrase in [
        'a próxima aula, sempre aqui.',
        'o que fazer hoje.',
        'as aulas feitas e as estrelas.',
        'todas as aulas do curso.',
      ]) {
        expect(find.textContaining(phrase), findsOneWidget);
      }
      expect(find.byKey(CourseGuideKeys.helpAction), findsNothing);
      for (final tab in CourseGuideTab.values) {
        expect(find.byKey(CourseGuideKeys.tab(tab.name)), findsOneWidget);
      }
      await cubit.repository.update(
        scenario.course,
        (s) => s.copyWith(onboardingDone: true),
      );
      await cubit.load();
      await tester.pumpAndSettle();
      expect(find.text('Módulo 1 · aula 1'), findsOneWidget);
      await tester.tap(find.byKey(CourseGuideKeys.tab('catalog')));
      await tester.pumpAndSettle();
      expect(find.text('MÓDULO 1 · PEÇAS'), findsOneWidget);
      expect(find.text('Módulo 2 · Mates'), findsOneWidget);
      expect(find.textContaining('Oculta'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final stateName in [
      'first',
      'pieces',
      'mates',
      'done',
      'off',
      'doubled',
    ]) {
      testWidgets('School goals $stateName render and route at $size', (
        tester,
      ) async {
        final scenario = TrainingScenarioBuilder(
          TrainingCourse.escola,
          resources: resources(),
        );
        final state = switch (stateName) {
          'pieces' => scenario.schoolPieces(),
          'mates' => scenario.schoolMates(),
          'done' => scenario.schoolAllDone(),
          'off' => scenario.schoolOffDay(),
          'doubled' => scenario.doubled(),
          _ => scenario.schoolDayOne(),
        };
        TrainingGoal? opened;
        final cubit = await show(
          tester,
          scenario,
          state.copyWith(tab: CourseGuideTab.goals),
          onGoal: (goal) => opened = goal,
        );
        if (stateName == 'done') {
          expect(find.byKey(TrainingKeys.doubleButton), findsOneWidget);
          expect(
            find.text('Entram hoje mais 4 aulas e os desafios delas.'),
            findsOneWidget,
          );
          await tester.tap(find.byKey(TrainingKeys.doubleButton));
          await tester.pumpAndSettle();
          expect(find.text('META DOBRADA'), findsOneWidget);
          await cubit.repository.update(
            scenario.course,
            (s) => s.copyWith(
              day: s.day!.copyWith(
                goals: s.day!.goals.map((g) => g.complete()),
              ),
            ),
          );
          await cubit.load();
          await tester.pumpAndSettle();
          expect(find.byKey(TrainingKeys.doubleButton), findsNothing);
          expect(
            find.text(
              'Tudo feito por hoje. Suas metas voltam no próximo dia de estudo.',
            ),
            findsOneWidget,
          );
        } else if (stateName == 'off') {
          expect(find.text('Hoje é dia de folga'), findsOneWidget);
          expect(find.byKey(TrainingKeys.doubleButton), findsNothing);
        } else if (stateName == 'doubled') {
          expect(find.text('META DOBRADA'), findsOneWidget);
        } else {
          final next = state.day!.next!;
          await tester.tap(
            find.byKey(TrainingKeys.goalTile(next.kind.name, next.ref)),
          );
          expect(opened?.key, next.key);
        }
        if (stateName == 'first') {
          await tester.scrollUntilVisible(
            find.textContaining('desafio das estrelas dela entra'),
            150,
          );
          expect(
            find.textContaining('desafio das estrelas dela entra'),
            findsOneWidget,
          );
        }
        if (stateName == 'pieces') {
          await tester.scrollUntilVisible(find.text('Desafio do cavalo'), 180);
          expect(find.text('Desafio do cavalo'), findsOneWidget);
        }
        if (stateName == 'mates') {
          await tester.scrollUntilVisible(
            find.text('Speedrun: os dois mates'),
            180,
          );
          expect(
            find.text('Dama e duas torres em 15 minutos · Coco'),
            findsOneWidget,
          );
          expect(find.text('Contra o Coco · 1000'), findsNWidgets(2));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'School adds a challenge immediately after observed lesson at $size',
      (tester) async {
        final scenario = TrainingScenarioBuilder(
          TrainingCourse.escola,
          resources: resources(),
        );
        final cubit = await show(
          tester,
          scenario,
          scenario.schoolDayOne().copyWith(tab: CourseGuideTab.goals),
        );
        expect(find.text('Desafio da torre'), findsNothing);
        final lesson = scenario.content.lessons.firstWhere(
          (l) => l.id == 'pieces.rook',
        );
        expect(await cubit.observeLesson(lesson), isTrue);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Desafio da torre'), 150);
        expect(find.text('Fácil · pegue 1 estrela'), findsOneWidget);
        expect(cubit.state.training!.day!.date, '2026-10-26');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'School progress counts visible modules and 0–3 completed levels at $size',
      (tester) async {
        final scenario = TrainingScenarioBuilder(
          TrainingCourse.escola,
          resources: resources(),
        );
        await show(
          tester,
          scenario,
          scenario.schoolDayOne().copyWith(
            tab: CourseGuideTab.progress,
            completedLessons: {
              'pieces.rook': '2026-10-25',
              'hidden': '2026-10-25',
            },
            school: SchoolTrainingProgress(
              pieceLevels: {'rook': 0, 'bishop': 1, 'queen': 2, 'king': 3},
            ),
          ),
        );
        expect(find.text('1 de 37'), findsOneWidget);
        expect(find.text('Oculto'), findsNothing);
        for (final id in [
          'pieces',
          'firstMates',
          for (var n = 0; n < 6; n++) 'fixture.module.$n',
        ]) {
          await tester.scrollUntilVisible(
            find.byKey(TrainingKeys.moduleRow(id)),
            150,
          );
          expect(find.byKey(TrainingKeys.moduleRow(id)), findsOneWidget);
        }
        await tester.scrollUntilVisible(
          find.byKey(TrainingKeys.pieceStars('pawn')),
          150,
        );
        final rows = tester
            .widgetList<PieceStarsRow>(find.byType(PieceStarsRow))
            .toList();
        expect(rows.map((row) => row.completed), [0, 1, 2, 3, 0, 0]);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('School plan offers four quotas and defaults to 30 at $size', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      final scenario = TrainingScenarioBuilder(
        TrainingCourse.escola,
        resources: resources(),
      );
      final repository = scenario.repository(
        TrainingState(course: scenario.course, installSeed: 'plan'),
      );
      final cubit = TrainingPlanCubit(
        repository: repository,
        config: scenario.config,
        now: scenario.now,
        push: FakePushRepository(allowed: true),
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
      await tester.pumpAndSettle();
      expect(cubit.state.draft.minutes, 30);
      for (final minutes in [15, 30, 60, 120]) {
        expect(find.byKey(TrainingKeys.planChip(minutes)), findsOneWidget);
        await tester.tap(find.byKey(TrainingKeys.planChip(minutes)));
        await tester.pumpAndSettle();
        expect(cubit.state.draft.minutes, minutes);
      }
      expect(find.byKey(TrainingKeys.planChip(240)), findsNothing);
      expect(find.text('2 horas ou mais'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('star titles keep grammatical gender, level and completed copy', (
    tester,
  ) async {
    final scenario = TrainingScenarioBuilder(
      TrainingCourse.escola,
      resources: resources(),
    );
    final state = scenario.schoolDayOne();
    final repository = scenario.repository(
      state.copyWith(
        day: state.day!.copyWith(
          goals: [
            TrainingGoal(
              kind: GoalKind.stars,
              ref: 'pieces.rook',
              itemId: 'easy',
              stars: 1,
            ),
            TrainingGoal(
              kind: GoalKind.stars,
              ref: 'pieces.bishop',
              itemId: 'medium',
              stars: 2,
            ),
            TrainingGoal(
              kind: GoalKind.stars,
              ref: 'pieces.queen',
              itemId: 'hard',
              stars: 3,
              done: true,
            ),
          ],
        ),
      ),
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: scenario.config,
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
          child: Scaffold(
            body: TrainingGoalsTab(onGoal: (_) {}, onPlan: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Desafio da torre'), findsOneWidget);
    expect(find.text('Desafio do bispo'), findsOneWidget);
    expect(find.text('Desafio da dama'), findsOneWidget);
    expect(find.text('Fácil · pegue 1 estrela'), findsOneWidget);
    expect(find.text('Médio · pegue 2 estrelas'), findsOneWidget);
    expect(find.text('Difícil · 3 estrelas'), findsOneWidget);
    expect(
      tester.widgetList<CourseItemTile>(find.byType(CourseItemTile)).last.state,
      CourseItemState.approved,
    );
  });
}
