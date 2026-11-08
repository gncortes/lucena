import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';

import 'package:lucena/ui/core/utils/save_retry.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';

import '../../../testing/training/training_scenario_builder.dart';

void main() {
  Future<void> wait(WidgetTester tester, Duration total) async {
    for (var i = 0; i < total.inSeconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  // H-TRE-17 gap 5: gravação que falha não repete a cada 1 s para sempre.
  testWidgets(
    'guia: gravação recusada tenta poucas vezes, com espera crescente',
    (tester) async {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final repository = scenario.repository(scenario.large());
      final cubit = CourseGuideCubit(
        repository: repository,
        config: TrainingCourseConfig.pilares,
        now: scenario.now,
      );
      addTearDown(cubit.close);
      addTearDown(repository.dispose);
      await cubit.load();
      repository.writeError = StateError('disk');
      unawaited(cubit.selectTab(CourseGuideTab.goals));
      await wait(tester, const Duration(minutes: 10));
      expect(repository.failedWrites, inInclusiveRange(2, 7));
      expect(cubit.state.failed, isTrue);
      final settled = repository.failedWrites;
      await wait(tester, const Duration(minutes: 10));
      expect(repository.failedWrites, settled, reason: 'parou de insistir');
      repository.writeError = null;
      await tester.runAsync(() => cubit.selectTab(CourseGuideTab.goals));
      expect(cubit.state.failed, isFalse, reason: 'tentar de novo ainda vale');
    },
  );

  testWidgets('exercício: dica e resposta com disco recusando não viram laço', (
    tester,
  ) async {
    final now = FakeNow(DateTime(2026, 10, 29, 12));
    final exercise = TrainingExercise(
      id: 'e',
      stars: 1,
      fen: GameRules.initial.fen,
      solution: ['e2e4', 'e7e5', 'g1f3'],
    );
    final goal = TrainingGoal(
      kind: GoalKind.exercise,
      ref: 'lesson',
      itemId: 'e',
      stars: 1,
    );
    final repository = FakeTrainingRepository(
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'test',
          day: DayGoals(date: '2026-10-29', studyDay: true, goals: [goal]),
          cycles: {
            'lesson': ThemeCycle(lessonId: 'lesson', startedOn: '2026-10-20'),
          },
        ),
      },
      content: {
        TrainingCourse.pilares: TrainingResources(
          banks: {
            'lesson': [exercise],
          },
        ),
      },
    );
    final cubit = TrainingExerciseCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: now,
      goalKey: goal.key,
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    repository.writeError = StateError('disk');
    unawaited(cubit.hint());
    await wait(tester, const Duration(minutes: 10));
    expect(repository.failedWrites, inInclusiveRange(2, 7));
    expect(cubit.state.error, isTrue);
    final afterHint = repository.failedWrites;
    unawaited(cubit.play('e2e4'));
    unawaited(cubit.play('g1f3'));
    await wait(tester, const Duration(minutes: 10));
    expect(repository.failedWrites - afterHint, lessThanOrEqualTo(8));
    final settled = repository.failedWrites;
    await wait(tester, const Duration(minutes: 10));
    expect(repository.failedWrites, settled);
  });

  testWidgets('abertura: gravação recusada não repete a cada 1 s', (
    tester,
  ) async {
    final now = FakeNow(DateTime(2026, 10, 29, 12));
    final repository = FakeTrainingRepository(
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'test',
          day: DayGoals(
            date: '2026-10-29',
            studyDay: true,
            goals: [
              TrainingGoal(
                kind: GoalKind.openings,
                ref: 'openings',
                items: {'white': 't1'},
              ),
            ],
          ),
          openings: {
            'white': OpeningTrack(lessonId: 'white', startedOn: '2026-10-28'),
          },
        ),
      },
      content: {
        TrainingCourse.pilares: TrainingResources(
          openings: {
            'white': [
              OpeningTrecho(
                id: 't1',
                title: 'line',
                moves: ['e2e4', 'e7e5', 'g1f3'],
              ),
            ],
          },
        ),
      },
    );
    final cubit = TrainingOpeningCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: now,
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load(lessonId: 'white');
    repository.writeError = StateError('disk');
    unawaited(cubit.play('e2e4'));
    unawaited(cubit.play('g1f3'));
    await wait(tester, const Duration(minutes: 10));
    expect(cubit.state.error, isTrue);
    expect(repository.failedWrites, inInclusiveRange(2, 7));
    final settled = repository.failedWrites;
    await wait(tester, const Duration(minutes: 10));
    expect(repository.failedWrites, settled);
  });

  test('SaveRetry dobra a espera, respeita o teto e o limite', () async {
    final retry = SaveRetry(
      maxAttempts: 3,
      firstDelay: const Duration(milliseconds: 10),
    );
    var runs = 0;
    expect(retry.schedule(() => runs++), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(runs, 1);
    expect(retry.schedule(() => runs++), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(runs, 1, reason: 'a segunda espera é de 20 ms');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(runs, 2);
    expect(retry.schedule(() => runs++), isTrue);
    expect(retry.schedule(() => runs++), isFalse, reason: 'limite atingido');
    retry.reset();
    expect(retry.schedule(() => runs++), isTrue);
    retry.cancel();
  });
}
