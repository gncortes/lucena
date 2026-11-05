import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
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
            // H-ANI-29: "META DOBRADA" é o selo; todo cartão entra em fila.
            expect(
              find.descendant(
                of: find.byKey(MotionKeys.seloDaMetaDobrada),
                matching: find.text('META DOBRADA'),
              ),
              findsOneWidget,
            );
            final goals = training.day!.goals;
            for (var i = 0; i < goals.length; i++) {
              expect(
                find.byKey(MotionKeys.cartaoDaMetaDobrada(i)),
                findsOneWidget,
              );
            }
            expect(find.text('FEITAS HOJE'), findsOneWidget);
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
  group('H-ANI-18: "Faltam N de M" conta junto com a barra', () {
    Future<void> abrir(WidgetTester tester, {bool reduzir = false}) async {
      setPhoneSize(tester, const Size(412, 917));
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
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduzir),
          child: TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: Scaffold(
                body: TrainingGoalsTab(onGoal: (_) {}, onPlan: () {}),
              ),
            ),
          ),
        ),
      );
    }

    (int, int)? faltam(WidgetTester tester) {
      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(TrainingKeys.goalsSummary),
          matching: find.byType(Text),
        ),
      )) {
        final m = RegExp(r'^Faltam (\d+) de (\d+)$')
            .firstMatch(text.data ?? '');
        if (m != null) return (int.parse(m.group(1)!), int.parse(m.group(2)!));
      }
      return null;
    }

    testWidgets('começa em M e desce até N', (tester) async {
      await abrir(tester);
      await tester.pumpAndSettle();
      final (fim, total) = faltam(tester)!;
      expect(fim, lessThan(total));
      await tester.pumpWidget(const SizedBox());
      await abrir(tester);
      await tester.pump();
      expect(faltam(tester)!.$1, greaterThan(fim));
      await tester.pumpAndSettle();
      expect(faltam(tester)!.$1, fim);
    });

    testWidgets('movimento reduzido: N já no primeiro quadro', (tester) async {
      await abrir(tester, reduzir: true);
      await tester.pumpAndSettle();
      final fim = faltam(tester)!.$1;
      await tester.pumpWidget(const SizedBox());
      await abrir(tester, reduzir: true);
      await tester.pump();
      expect(faltam(tester)!.$1, fim);
    });
  });
}
