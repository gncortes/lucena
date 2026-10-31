import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';

import '../../../testing/training/training_scenario_builder.dart';

void main() {
  test('double waits for durable persistence, preserves order and survives reopening', () async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final extra = scenario.content.lessons.firstWhere((l) => l.id == 'theme10');
    final completed = CompleteTrainingLesson(scenario.now, scenario.config)(
      scenario.allDone(),
      scenario.content,
      extra,
    );
    final repository = scenario.repository(completed);
    final cubit = CourseGuideCubit(
      repository: repository,
      config: scenario.config,
      now: scenario.now,
    );
    addTearDown(repository.dispose);
    addTearDown(cubit.close);
    await cubit.load();
    final gate = Completer<void>();
    repository.beforeSave = gate.future;
    final saving = cubit.doubleGoals();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.saving, isTrue);
    expect(cubit.state.training!.day!.doubled, isFalse);
    gate.complete();
    expect(await saving, isTrue);
    final persisted = await repository.load(scenario.course);
    expect(persisted.day!.doubled, isTrue);
    expect(persisted.day!.next!.kind, GoalKind.lesson);
    expect(
      persisted.day!.goals.where((g) => g.kind == GoalKind.openings),
      hasLength(1),
    );
    final day = persisted.day!.toJson();
    expect(await cubit.doubleGoals(), isTrue);
    expect(cubit.state.training!.day!.toJson(), day);
    final reopened = CourseGuideCubit(
      repository: repository,
      config: scenario.config,
      now: scenario.now,
    );
    addTearDown(reopened.close);
    await reopened.load();
    expect(reopened.state.training!.day!.toJson(), day);
  });

  test('failed double keeps the visible day and allows retry', () async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final extra = scenario.content.lessons.firstWhere((l) => l.id == 'theme10');
    final completed = CompleteTrainingLesson(scenario.now, scenario.config)(
      scenario.allDone(),
      scenario.content,
      extra,
    );
    final repository = scenario.repository(completed);
    final cubit = CourseGuideCubit(
      repository: repository,
      config: scenario.config,
      now: scenario.now,
    );
    addTearDown(repository.dispose);
    addTearDown(cubit.close);
    await cubit.load();
    final before = cubit.state.training!.day!.toJson();
    repository.writeError = StateError('disk');
    expect(await cubit.doubleGoals(), isFalse);
    expect(cubit.state.failed, isTrue);
    expect(cubit.state.training!.day!.toJson(), before);
    repository.writeError = null;
    expect(await cubit.doubleGoals(), isTrue);
    expect(cubit.state.training!.day!.doubled, isTrue);
  });
}
