import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/training/training_history_source.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/routing/training_routes.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_course_training_repository.dart';
import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/test_app.dart';
import '../../testing/training/training_scenario_builder.dart';

void main() {
  testWidgets('exercise completes durably and returns to the same goals tab', (
    tester,
  ) async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    addTearDown(settings.close);
    final repo = FakeTrainingRepository(
      states: {TrainingCourse.pilares: scenario.large()},
      content: {TrainingCourse.pilares: scenario.content},
    );
    final router = GoRouter(
      initialLocation: Routes.training('pilares'),
      routes: [trainingRoute()],
    );
    addTearDown(router.dispose);
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
          RepositoryProvider<Now>.value(value: scenario.now),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
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
    await tester.tap(find.byKey(CourseGuideKeys.tab('goals')));
    await tester.pumpAndSettle();
    final target = find.byKey(TrainingKeys.goalTile('exercise', 'theme1'));
    await tester.scrollUntilVisible(target, 200);
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(
      find.byKey(TrainingKeys.exerciseBoard),
      findsOneWidget,
      reason:
          '${router.routeInformationProvider.value.uri} | ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().take(12).join(" / ")}',
    );
    final cubit = tester
        .element(find.byKey(TrainingKeys.exerciseBoard))
        .read<TrainingExerciseCubit>();
    await cubit.play('a1a8');
    await tester.pumpAndSettle();
    expect(
      (await repo.load(TrainingCourse.pilares)).day!.goals
          .where((g) => g.ref == 'theme1')
          .single
          .done,
      isTrue,
    );
    await tester.tap(find.byKey(TrainingKeys.nextGoal));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      Routes.training('pilares'),
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byKey(TrainingKeys.exerciseBoard), findsNothing);
  });
}
