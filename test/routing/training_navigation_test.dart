import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/push/push_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/training/training_history_source.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/routing/training_routes.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/reminders/view_models/reminders_cubit.dart';

import '../../testing/fakes/fake_activity_repository.dart';
import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_course_training_repository.dart';
import '../../testing/fakes/fake_push_repository.dart';
import '../../testing/fakes/fake_reminders_repository.dart';
import '../../testing/test_app.dart';
import '../../testing/training/training_scenario_builder.dart';

void main() {
  testWidgets('welcome opens plan, saves durably and reloads guide', (
    tester,
  ) async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repo = FakeTrainingRepository(
      content: {TrainingCourse.pilares: scenario.content},
    );
    final reminders = RemindersCubit(
      reminders: FakeRemindersRepository(),
      activity: FakeActivityRepository(now: scenario.now),
      week: FakeWeekRepository(
        WeekSummary(
          monday: DateTime(2026, 10, 26),
          finals: 0,
          perDay: const [0, 0, 0, 0, 0, 0, 0],
          ratingFrom: 1200,
          ratingTo: 1200,
          streakDays: 0,
          firstTry: 0,
        ),
      ),
      now: scenario.now,
      training: repo,
    );
    final router = GoRouter(
      initialLocation: Routes.training('pilares'),
      routes: [
        trainingRoute(),
        GoRoute(path: Routes.settings, builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(reminders.close);
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TrainingRepository>.value(value: repo),
          RepositoryProvider<TrainingHistorySource>.value(
            value: TrainingHistorySource(
              repo,
              learning: null,
              now: scenario.now,
            ),
          ),
          RepositoryProvider<EndgameLessonRepository>.value(
            value: FakeEndgameLessonRepository(),
          ),
          RepositoryProvider<EndgameProgressRepository>.value(
            value: FakeEndgameProgressRepository(),
          ),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<Now>.value(value: scenario.now),
          RepositoryProvider<PushRepository>.value(
            value: FakePushRepository(allowed: true),
          ),
        ],
        child: BlocProvider.value(
          value: reminders,
          child: TestApp(
            locale: const Locale('pt'),
            router: router,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Boas-vindas ao Pilares do Xadrez'), findsOneWidget);
    await tester.ensureVisible(find.byKey(CourseGuideKeys.continueButton));
    await tester.tap(find.byKey(CourseGuideKeys.continueButton));
    await tester.pumpAndSettle();
    expect(find.byKey(TrainingKeys.planScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(TrainingKeys.planSave),
      300,
      scrollable: find.descendant(
        of: find.byKey(TrainingKeys.planScroll),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(TrainingKeys.planSave));
    await tester.pumpAndSettle();
    expect((await repo.load(TrainingCourse.pilares)).onboardingDone, isTrue);
    expect(
      router.routeInformationProvider.value.uri.path,
      Routes.training('pilares'),
    );
    expect(find.text('Boas-vindas ao Pilares do Xadrez'), findsNothing);
    expect(find.byKey(CourseGuideKeys.screen), findsOneWidget);
    expect(find.byKey(TrainingKeys.planScreen), findsNothing);
  });

  testWidgets('unknown training course returns to settings', (tester) async {
    final router = GoRouter(
      initialLocation: Routes.training('unknown'),
      routes: [
        trainingRoute(),
        GoRoute(path: Routes.settings, builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(TestApp(router: router, child: const SizedBox()));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, Routes.settings);
    expect(find.byKey(CourseGuideKeys.screen), findsNothing);
  });
}
