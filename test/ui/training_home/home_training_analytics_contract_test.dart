import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/home_actions.dart';

import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  for (final config in TrainingCourseConfig.all) {
    testWidgets(
      'Home follow-up keeps the contracted event buckets ${config.course}',
      (tester) async {
        final school = config.course == TrainingCourse.escola;
        final goal = TrainingGoal(
          kind: school ? GoalKind.stars : GoalKind.exercise,
          ref: school ? 'pieces.rook' : 'theme',
          itemId: school ? 'easy' : 'e1',
          stars: 1,
        );
        final state = TrainingState(
          course: config.course,
          installSeed: 'analytics-contract',
          onboardingDone: true,
          day: DayGoals(date: '2026-10-29', studyDay: true, goals: [goal]),
        );
        final training = HomeTraining(
          config: config,
          state: state,
          resources: TrainingResources(),
          card: HomeCourseCard(
            school ? HomeCourseStatus.challenge : HomeCourseStatus.exercise,
            school
                ? HomeCourseDestination.challenge
                : HomeCourseDestination.exercise,
            goal.ref,
            goal: goal,
          ),
        );
        final repository = FakeTrainingRepository(
          states: {config.course: state},
        );
        final analytics = FakeAnalyticsRepository();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => openTrainingCourse(context, training),
                  child: const Text('Abrir'),
                ),
              ),
            ),
            GoRoute(
              path: '/training/:course',
              builder: (_, _) => const Scaffold(body: Text('guia')),
            ),
            GoRoute(
              path: '/training/:course/exercise/:theme',
              builder: (_, _) => const Scaffold(body: Text('destino')),
            ),
            GoRoute(
              path: '/school/challenges/:piece/:level',
              builder: (_, _) => const Scaffold(body: Text('destino')),
            ),
          ],
        );
        addTearDown(router.dispose);
        addTearDown(repository.dispose);
        await tester.pumpWidget(
          RepositoryProvider<TrainingRepository>.value(
            value: repository,
            child: TestApp(
              router: router,
              analytics: analytics,
              child: const SizedBox(),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        expect(find.text('destino'), findsOneWidget);
        expect(analytics.eventsNamed('curso_cartao_home').single.params, {
          'curso': config.course.name,
          'estado': 'exercicio',
          'destino': 'exercicio',
        });
      },
    );
  }
}
