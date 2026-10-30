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
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_course_training_repository.dart';
import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/test_app.dart';
import '../../testing/phone_size.dart';
import '../../testing/training/training_scenario_builder.dart';

void main() {
  testWidgets(
    'opening list completes four segments through fade and returns to the same goals tab',
    (tester) async {
      setPhoneSize(tester, const Size(412, 915));
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
      await tester.scrollUntilVisible(
        find.byKey(TrainingKeys.trainTrecho('opening1')),
        150,
      );
      await tester.ensureVisible(
        find.byKey(TrainingKeys.trainTrecho('opening1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TrainingKeys.trainTrecho('opening1')));
      await tester.pumpAndSettle();
      for (var index = 1; index <= 4; index++) {
        expect(find.byKey(TrainingKeys.openingBoard), findsOneWidget);
        final cubit = tester
            .element(find.byKey(TrainingKeys.openingBoard))
            .read<TrainingOpeningCubit>();
        expect(cubit.state.lessonId, 'opening$index');
        await cubit.play('d2d4');
        await cubit.play('c1f4');
        await tester.pumpAndSettle();
      }
      expect(
        (await repo.load(TrainingCourse.pilares)).day!.goals
            .where((g) => g.kind == GoalKind.openings)
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
      expect(find.byKey(TrainingKeys.openingBoard), findsNothing);
    },
  );
}
