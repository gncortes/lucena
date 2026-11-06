import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/streak_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

/// T85 P8 A: a sequência de dias no cartão de Hoje das Metas, lida do
/// repositório de atividade com os dias gravados (nada de número pronto).
void main() {
  // Quinta-feira; a semana vai de 26/10 a 01/11.
  final thursday = DateTime(2026, 10, 29, 12);

  Future<void> pump(
    WidgetTester tester,
    Set<DateTime> days, {
    Size size = const Size(360, 640),
  }) async {
    setPhoneSize(tester, size);
    final scenario = TrainingScenarioBuilder(
      TrainingCourse.pilares,
      date: thursday,
    );
    final repository = scenario.repository(scenario.goalsScenario('middle'));
    final cubit = CourseGuideCubit(
      repository: repository,
      config: scenario.config,
      now: scenario.now,
      activity: FakeActivityRepository(days: days, now: scenario.now),
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
    expect(tester.takeException(), isNull);
  }

  DateTime d(int day, [int month = 10]) => DateTime(2026, month, day, 18);

  testWidgets('3 dias seguidos e hoje sem treino: "Treinar hoje faz 4"', (
    tester,
  ) async {
    await pump(tester, {d(26), d(27), d(28), d(1, 10)});
    expect(find.text('3 dias seguidos'), findsOneWidget);
    expect(find.text('Ontem contou. Treinar hoje faz 4.'), findsOneWidget);
    expect(find.text('recorde 3'), findsOneWidget);
    final week = find.byKey(StreakKeys.weekStrip);
    expect(
      find.descendant(of: week, matching: find.byIcon(Icons.check)),
      findsNWidgets(3),
    );
    final card = tester.getRect(find.byKey(TrainingKeys.goalsSummary));
    expect(tester.getRect(week).bottom, lessThan(card.bottom));
  });

  testWidgets('print do cartão com a sequência (411×914)', (tester) async {
    await Goldens.loadFonts();
    await pump(tester, {
      d(26),
      d(27),
      d(28),
      d(1, 10),
    }, size: const Size(411, 914));
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/p8a/sequencia_411x914.png'),
    );
  });

  testWidgets('hoje já treinado: a nota diz que hoje contou', (tester) async {
    await pump(tester, {d(27), d(28), d(29)});
    expect(find.text('3 dias seguidos'), findsOneWidget);
    expect(find.text('Hoje já contou.'), findsOneWidget);
    expect(find.textContaining('Treinar hoje faz'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(StreakKeys.weekStrip),
        matching: find.byIcon(Icons.check),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('sequência zerada: recomeça e o recorde fica', (tester) async {
    await pump(tester, {d(20), d(21), d(22), d(23), d(24)});
    expect(find.text('0 dias seguidos'), findsOneWidget);
    expect(
      find.text('Ontem ficou sem treino. Treinar hoje recomeça.'),
      findsOneWidget,
    );
    expect(find.text('recorde 5'), findsOneWidget);
  });

  testWidgets('primeiro dia: sem recorde, treinar hoje faz o dia 1', (
    tester,
  ) async {
    await pump(tester, {});
    expect(find.text('Sua sequência começa hoje'), findsOneWidget);
    expect(find.text('Treinar hoje faz o dia 1.'), findsOneWidget);
    expect(find.byKey(TrainingKeys.streakRecord), findsNothing);
  });

  testWidgets('sem o repositório de atividade o cartão não tem sequência', (
    tester,
  ) async {
    setPhoneSize(tester, const Size(360, 640));
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = scenario.repository(scenario.goalsScenario('middle'));
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
    expect(find.byKey(TrainingKeys.streakCard), findsNothing);
  });

  testWidgets(
    'geometria em 360x640: sem estouro, linha e faixa dentro do cartão',
    (tester) async {
      await pump(tester, {d(26), d(27), d(28)});
      final card = tester.getRect(find.byKey(TrainingKeys.goalsSummary));
      final streak = tester.getRect(find.byKey(TrainingKeys.streakCard));
      final week = tester.getRect(find.byKey(StreakKeys.weekStrip));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(360));
      expect(streak.left, greaterThanOrEqualTo(card.left));
      expect(streak.right, lessThanOrEqualTo(card.right));
      expect(week.width, closeTo(streak.width, 1));
      // Canvas: as bolinhas da semana têm 32 dp.
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byKey(StreakKeys.weekStrip),
                    matching: find.byIcon(Icons.check),
                  )
                  .first,
            )
            .height,
        lessThanOrEqualTo(32),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ao voltar de uma lição o guia recarrega e o cartão atualiza', (
    tester,
  ) async {
    setPhoneSize(tester, const Size(360, 640));
    final scenario = TrainingScenarioBuilder(
      TrainingCourse.pilares,
      date: thursday,
    );
    final repository = scenario.repository(scenario.goalsScenario('middle'));
    final activity = FakeActivityRepository(
      days: {d(27), d(28)},
      now: scenario.now,
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: scenario.config,
      now: scenario.now,
      activity: activity,
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
    expect(find.text('Ontem contou. Treinar hoje faz 3.'), findsOneWidget);
    // A lição conclui e marca o dia; o retorno (ReloadOnReturn) recarrega.
    await activity.markToday();
    await cubit.load();
    await tester.pumpAndSettle();
    expect(find.text('3 dias seguidos'), findsOneWidget);
    expect(find.text('Hoje já contou.'), findsOneWidget);
  });
}
