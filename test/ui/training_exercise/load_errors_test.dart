import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_screen.dart';

import '../../../testing/test_app.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/training/training_scenario_builder.dart';

class FailingTraining implements TrainingRepository {
  FailingTraining(this.delegate);
  final TrainingRepository delegate;
  bool fail = true;
  Completer<void>? pending;
  @override
  Future<TrainingResources> resources(TrainingCourse course) async {
    await pending?.future;
    if (fail) throw StateError('training resources');
    return delegate.resources(course);
  }

  @override
  Future<TrainingState> load(TrainingCourse course) => delegate.load(course);
  @override
  Stream<TrainingState> get changes => delegate.changes;
  @override
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  ) => delegate.update(course, change);
  @override
  Future<TrainingState> transact(
    TrainingCourse course,
    FutureOr<TrainingState> Function(TrainingState) change,
  ) => delegate.transact(course, change);
}

void main() {
  for (final initial in [true, false]) {
    for (final opening in [false, true]) {
      testWidgets(
        '${opening ? "opening" : "exercise"} failure retries real load initial=$initial',
        (tester) async {
          final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
          final saved = scenario.large();
          final delegate = scenario.repository(saved);
          final repository = FailingTraining(delegate)..fail = !initial;
          final pending = Completer<void>();
          if (initial) repository.pending = pending;
          addTearDown(delegate.dispose);
          final settings = SettingsCubit(
            FakeSettingsRepository(),
            languages: AppLanguage.selectable,
          );
          await settings.load();
          addTearDown(settings.close);
          const teacher = Character(
            id: Character.masterId,
            level: 2600,
            name: 'Viktor',
            tagline: {},
            personality: {},
            traits: [],
            avatar: 'assets/branding/stockfish.png',
          );
          final goal = saved.day!.goals.firstWhere(
            (g) => g.kind == GoalKind.exercise,
          );
          await tester.pumpWidget(
            TestApp(
              settingsCubit: settings,
              locale: const Locale('pt'),
              child: opening
                  ? TrainingOpeningScreen(
                      repository: repository,
                      config: scenario.config,
                      now: scenario.now,
                      lessonId: 'opening1',
                      teacher: teacher,
                      onNextGoal: () {},
                    )
                  : TrainingExerciseScreen(
                      repository: repository,
                      config: scenario.config,
                      now: scenario.now,
                      goalKey: goal.key,
                      title: 'Teste',
                      teacher: teacher,
                      onNextGoal: () {},
                      onRedoLesson: (_) {},
                    ),
            ),
          );
          if (initial) {
            await tester.pump();
            expect(find.byType(SkeletonBlock), findsWidgets);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            pending.complete();
            await tester.pumpAndSettle();
            expect(find.byType(SkeletonBlock), findsNothing);
            expect(tester.takeException(), isNull);
            return;
          }
          await tester.pumpAndSettle();
          expect(find.byType(LoadErrorScreen), findsOneWidget);
          expect(
            tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
            LoadErrorKind.generic,
          );
          repository.fail = false;
          await tester.tap(find.byKey(LoadErrorKeys.action));
          await tester.pumpAndSettle();
          expect(find.byType(LoadErrorScreen), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
