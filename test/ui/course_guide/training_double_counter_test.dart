import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/training_goal_counts.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';

import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

/// T85 B2b: ao tocar em "Dobrar a meta", o contador nunca mostra, nem por um
/// quadro, um número que não bate com a lista (ex.: "Faltam 4 de 4").
void main() {
  testWidgets('Dobrar a meta: Faltam N de M já nasce igual à lista', (
    tester,
  ) async {
    setPhoneSize(tester, const Size(412, 917));
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = scenario.repository(scenario.goalsScenario('doneExtra'));
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
    expect(cubit.doubleMinutes(), greaterThanOrEqualTo(15));
    expect(
      find.descendant(
        of: find.byKey(TrainingKeys.doubleOffer),
        matching: find.text(
          'Isso soma cerca de ${cubit.doubleMinutes()} min de estudo hoje.',
        ),
      ),
      findsOneWidget,
      reason: 'a oferta diz quanto tempo dobrar soma',
    );
    await tester.tap(find.byKey(TrainingKeys.doubleButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final counts = trainingGoalCounts(cubit.state.training!);
    expect(counts.remaining, lessThan(counts.total));
    expect(
      find.descendant(
        of: find.byKey(TrainingKeys.goalsSummary),
        matching: find.text('Faltam ${counts.remaining} de ${counts.total}'),
      ),
      findsOneWidget,
      reason: 'primeiro quadro depois de dobrar já mostra o número real',
    );
  });
}
