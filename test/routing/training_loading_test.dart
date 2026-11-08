import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/training_routes.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/test_app.dart';
import '../../testing/training/training_scenario_builder.dart';
import '../ui/training_exercise/load_errors_test.dart' show FailingTraining;

void main() {
  for (final initial in [false, true]) {
    testWidgets(
      'training wrapper ${initial ? "initial shimmer" : "pending retry keeps error"}',
      (tester) async {
        final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
        final saved = scenario.large();
        final delegate = scenario.repository(saved);
        addTearDown(delegate.dispose);
        final repository = FailingTraining(delegate)..fail = !initial;
        final pending = Completer<void>();
        if (initial) repository.pending = pending;
        final goal = saved.day!.goals.firstWhere(
          (g) => g.kind == GoalKind.exercise,
        );
        final route = trainingRoute().routes.whereType<GoRoute>().firstWhere(
          (r) => r.path == 'exercise/:theme',
        );
        final router = GoRouter(
          initialLocation: '/training/pilares/exercise/${goal.ref}',
          routes: [
            GoRoute(
              path: '/training/:course',
              builder: (_, _) => const SizedBox(),
              routes: [route],
            ),
          ],
        );
        addTearDown(router.dispose);
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await settings.load();
        addTearDown(settings.close);
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<TrainingRepository>.value(value: repository),
              RepositoryProvider<CharacterRepository>.value(
                value: FakeCharacterRepository(),
              ),
              RepositoryProvider<Now>.value(value: scenario.now),
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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        if (initial) {
          expect(find.byType(SkeletonBlock), findsWidgets);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          pending.complete();
        } else {
          await tester.pumpAndSettle();
          expect(find.byType(LoadErrorScreen), findsOneWidget);
          repository.pending = pending;
          await tester.tap(find.byKey(LoadErrorKeys.action));
          await tester.pump();
          expect(find.byType(LoadErrorScreen), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(find.byKey(LoadErrorKeys.action))
                .onPressed,
            isNull,
          );
          expect(find.byType(SkeletonBlock), findsNothing);
          pending.complete();
          await tester.pumpAndSettle();
          expect(find.byType(LoadErrorScreen), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(find.byKey(LoadErrorKeys.action))
                .onPressed,
            isNotNull,
          );
          repository
            ..pending = null
            ..fail = false;
          await tester.tap(find.byKey(LoadErrorKeys.action));
        }
        await tester.pumpAndSettle();
        expect(find.byType(LoadErrorScreen), findsNothing);
        expect(find.byType(SkeletonBlock), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
