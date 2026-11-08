import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() => registerTrainingOpeningCompletionTests();

void registerTrainingOpeningCompletionTests() {
  patrolTest('T85 quatro aberturas por dia até todos os trechos firmes', (
    $,
  ) async {
    final app = AppRobot($);
    final capture = TrainingCaptureRobot($);
    await app.open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.opening,
    );
    await $(HomeKeys.goalAction).tap();
    await $(TrainingKeys.openingBoard).waitUntilVisible();
    await capture.begin('opening-completion');
    late final List<String> openingIds;
    for (var day = 0; day < 2; day++) {
      for (var opening = 0; opening < 4; opening++) {
        final cubit = $.tester
            .element(find.byKey(TrainingKeys.openingScreen))
            .read<TrainingOpeningCubit>();
        expect(cubit.state.cursor, 0);
        expect(cubit.state.trecho!.id, day == 0 ? 't1' : 't2');
        final next = cubit.state.pending
            .where((id) => id != cubit.state.lessonId)
            .firstOrNull;
        await capture.openingMove('d2d4');
        if (day == 0) await capture.openingMove('c1f4');
        if (day == 0 && opening == 0) {
          openingIds = cubit.state.goal!.items.keys.toList();
          expect(openingIds, hasLength(4));
        }
        if (next != null) {
          // AberturaParteFim mantém o aluno na parte concluída. A próxima
          // abertura só é aberta pela ação explícita, via Metas.
          await $(TrainingKeys.nextGoal).waitUntilVisible();
          expect(
            cubit.state.phase,
            TrainingOpeningPhase.complete,
            reason:
                'day=$day opening=$opening lesson=${cubit.state.lessonId} '
                'cursor=${cubit.state.cursor} wrong=${cubit.state.wrong} '
                'error=${cubit.state.error} fen=${cubit.state.fen}',
          );
          await $(TrainingKeys.nextGoal).tap();
          await $(CourseGuideKeys.screen).waitUntilVisible();
          await $(TrainingKeys.trainTrecho(next)).scrollTo().tap();
          await $(TrainingKeys.openingTitle(next)).waitUntilVisible();
          await $.pumpAndSettle();
        }
      }
      await $(TrainingKeys.nextGoal).waitUntilVisible();
      await capture.shot(
        'opening-day${day + 1}-finished',
        ready: TrainingKeys.nextGoal,
      );
      if (day == 1) {
        await $(TrainingKeys.openingBack).tap();
        await capture.shot(
          'opening-all-done-today',
          ready: CourseGuideKeys.screen,
        );
        e2eNow.advance(const Duration(days: 1));
        await $(CourseGuideKeys.planAction).tap();
        await $(TrainingKeys.planScreen).waitUntilVisible();
        await $(TrainingKeys.planBack).tap();
        for (final id in openingIds) {
          await $(TrainingKeys.openingAllPartsDone(id)).scrollTo();
        }
        await capture.shot('opening-all-firm', ready: CourseGuideKeys.screen);
        break;
      }
      await $(TrainingKeys.nextGoal).tap();
      await $(CourseGuideKeys.screen).waitUntilVisible();
      final repository = $.tester
          .element(find.byKey(CourseGuideKeys.screen))
          .read<TrainingRepository>();
      final saved = await repository.load(TrainingCourse.pilares);
      final goal = saved.day!.goals.singleWhere(
        (g) => g.kind == GoalKind.openings,
      );
      expect(goal.done, isTrue);
      await capture.shot('opening-last-next-goal');
      e2eNow.advance(const Duration(days: 1));
      await app.restart();
      await capture.openGuide();
      await capture.tab('goals');
      final restored = await $.tester
          .element(find.byKey(CourseGuideKeys.screen))
          .read<TrainingRepository>()
          .load(TrainingCourse.pilares);
      final tomorrow = restored.day!.goals.singleWhere(
        (g) => g.kind == GoalKind.openings,
      );
      final train = find.byKey(
        TrainingKeys.trainTrecho(tomorrow.items.keys.first),
      );
      await $(train).scrollTo().tap();
      await $(TrainingKeys.openingBoard).waitUntilVisible();
    }
  }, tags: ['training-opening-completion']);
}
