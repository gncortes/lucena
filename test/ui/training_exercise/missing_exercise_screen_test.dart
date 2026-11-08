import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  const teacher = Character(
    id: Character.masterId,
    level: 2600,
    name: 'Viktor',
    tagline: {},
    personality: {},
    traits: [],
    avatar: 'assets/branding/stockfish.png',
  );

  // H-TRE-17 gap 9: exercício que sumiu mostra o erro padrão, com ação.
  for (final expired in [false, true]) {
    testWidgets(
      expired
          ? 'exercício que expirou no meio mostra erro padrão com ação'
          : 'exercício ausente do banco mostra erro padrão com ação',
      (tester) async {
        final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
        final saved = scenario.large();
        final goal = saved.day!.goals.firstWhere(
          (g) => g.kind == GoalKind.exercise,
        );
        final repository = scenario.repository(saved);
        if (!expired) {
          repository.content[TrainingCourse.pilares] = TrainingResources(
            lessons: scenario.content.lessons,
          );
        }
        addTearDown(repository.dispose);
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await settings.load();
        addTearDown(settings.close);
        await tester.pumpWidget(
          TestApp(
            settingsCubit: settings,
            locale: const Locale('pt'),
            child: TrainingExerciseScreen(
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
        await tester.pumpAndSettle();
        if (expired) {
          final cubit = tester
              .element(find.byType(Scaffold).first)
              .read<TrainingExerciseCubit>();
          await repository.update(
            TrainingCourse.pilares,
            (s) => s.copyWith(
              day: s.day!.copyWith(
                goals: [
                  for (final g in s.day!.goals)
                    if (g.key != goal.key) g,
                ],
              ),
            ),
          );
          await cubit.play(cubit.state.exercise!.solution.first);
          await cubit.play(cubit.state.exercise!.solution.first);
          await tester.pumpAndSettle();
        }
        expect(find.byType(LoadErrorScreen), findsOneWidget);
        expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
