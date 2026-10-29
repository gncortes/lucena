import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/training/training_history_source.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/routing/training_routes.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_course_training_repository.dart';
import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_now.dart';
import '../../testing/phone_size.dart';
import '../../testing/test_app.dart';

void main() {
  for (final theme in [false, true]) {
    testWidgets('theme header opt-in preserves default guide: theme=$theme', (
      tester,
    ) async {
      setPhoneSize(tester, const Size(412, 917));
      final now = FakeNow(DateTime(2026, 10, 29));
      final repo = FakeTrainingRepository(
        content: {
          TrainingCourse.pilares: TrainingResources(
            lessons: [
              const TrainingLesson(
                id: 'theme',
                kind: TrainingLessonKind.theme,
                title: 'Tema',
              ),
            ],
          ),
        },
        states: {
          TrainingCourse.pilares: TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'header',
            tab: CourseGuideTab.progress,
            cycles: {
              'theme': ThemeCycle(lessonId: 'theme', startedOn: '2026-10-20'),
            },
          ),
        },
      );
      final router = GoRouter(
        initialLocation: theme
            ? Routes.trainingTheme('pilares', 'theme')
            : Routes.training('pilares'),
        routes: [trainingRoute()],
      );
      addTearDown(repo.dispose);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<TrainingRepository>.value(value: repo),
            RepositoryProvider<TrainingHistorySource>.value(
              value: TrainingHistorySource(repo, learning: null, now: now),
            ),
            RepositoryProvider<EndgameLessonRepository>.value(
              value: FakeEndgameLessonRepository(),
            ),
            RepositoryProvider<EndgameProgressRepository>.value(
              value: FakeEndgameProgressRepository(),
            ),
            RepositoryProvider<Now>.value(value: now),
            RepositoryProvider<CharacterRepository>.value(
              value: FakeCharacterRepository(),
            ),
          ],
          child: TestApp(
            locale: const Locale('pt'),
            router: router,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.centerTitle, theme);
      expect(
        find.byKey(CourseGuideKeys.planAction),
        theme ? findsNothing : findsOneWidget,
      );
      expect(
        find.byKey(CourseGuideKeys.helpAction),
        theme ? findsNothing : findsOneWidget,
      );
      expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .destinations
            .length,
        4,
      );
      if (theme) expect(find.byKey(TrainingKeys.themeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
