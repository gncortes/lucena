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
    'progress keeps guide shell and explicit tour persists without reopening',
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

      expect(find.byKey(TrainingKeys.tourOverlay), findsNothing);
      await tester.tap(find.byKey(CourseGuideKeys.tab('progress')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TrainingKeys.masteryRow('theme1')));
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.themeScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.themeScreen), findsNothing);
      await tester.tap(find.byKey(CourseGuideKeys.helpAction));
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.helpScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(TrainingKeys.helpTour));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TrainingKeys.helpTour));
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.tourOverlay), findsOneWidget);
      await tester.tap(find.byKey(TrainingKeys.tourSkip));
      await tester.pumpAndSettle();
      expect((await repo.load(TrainingCourse.pilares)).tourSeen, isTrue);
      expect(find.byKey(TrainingKeys.tourOverlay), findsNothing);
      expect(find.byKey(TrainingKeys.helpScreen), findsNothing);
      expect(find.byKey(CourseGuideKeys.screen), findsOneWidget);
      router.go(Routes.training('pilares'));
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.tourOverlay), findsNothing);
    },
  );
}
