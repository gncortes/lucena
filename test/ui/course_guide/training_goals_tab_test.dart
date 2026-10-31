import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';

import '../../../testing/phone_size.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  for (final size in phoneSizes) {
    for (final sample in [
      'first',
      'second',
      'middle',
      'goalDone',
      'extraLesson',
      'nextDay',
      'doneExtra',
      'large',
      'done',
      'doubled',
      'dayOff',
      'scrolled',
    ]) {
      testWidgets(
        'Metas $sample em ${size.width.toInt()} conserva estado e rola sem overflow',
        (tester) async {
          setPhoneSize(tester, size);
          final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
          final training = scenario.goalsScenario(sample);
          final repository = scenario.repository(training);
          final cubit = CourseGuideCubit(
            repository: repository,
            config: scenario.config,
            now: scenario.now,
            characters: sample == 'done' ? FakeCharacterRepository() : null,
          );
          addTearDown(cubit.close);
          addTearDown(repository.dispose);
          await cubit.load();
          var goalsOpened = 0;
          await tester.pumpWidget(
            TestApp(
              locale: const Locale('pt'),
              child: BlocProvider.value(
                value: cubit,
                child: Scaffold(
                  body: TrainingGoalsTab(
                    onGoal: (_) => goalsOpened++,
                    onPlan: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (sample == 'dayOff') {
            expect(find.text('Hoje é dia de folga'), findsOneWidget);
            expect(find.byKey(TrainingKeys.doubleButton), findsNothing);
          } else if (sample == 'doneExtra') {
            expect(find.byKey(TrainingKeys.doubleOffer), findsOneWidget);
            expect(find.byKey(TrainingKeys.doubleButton), findsOneWidget);
          } else if (sample != 'done') {
            expect(find.byKey(TrainingKeys.goalsSummary), findsOneWidget);
          }
          if (sample == 'doubled') {
            expect(find.text('META DOBRADA'), findsOneWidget);
          }
          if (sample == 'first' ||
              sample == 'large' ||
              sample == 'second' ||
              sample == 'scrolled') {
            final goal = training.day!.next!;
            await tester.tap(
              find.byKey(TrainingKeys.goalTile(goal.kind.name, goal.ref)),
            );
            expect(goalsOpened, 1);
          }
          await tester.drag(find.byType(Scrollable), const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            cubit.state.training!.day!.goals.length,
            training.day!.goals.length,
          );
        },
      );
    }
  }
}
