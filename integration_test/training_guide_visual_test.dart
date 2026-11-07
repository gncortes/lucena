import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/placement/placement_repository.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

void main() {
  patrolTest('T85 aba Aula depois da aula do dia concluída', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.done,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await capture.shot('lesson-done-today');
  }, tags: const ['training-guide-done']);

  patrolTest('T85 Progresso abre o teste de nível existente', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    final context = $.tester.element(find.byKey(CourseGuideKeys.screen));
    await context.read<PlacementRepository>().saveResult(
      PlacementResult(
        theta: 1500,
        low: 1400,
        high: 1600,
        nodes: const {},
        takenAt: e2eNow(),
        answers: [
          for (var i = 0; i < 20; i++)
            PlacementAnswer(
              itemId: 'fixture$i',
              node: 'fixture',
              difficulty: 1500,
              outcome: i < 16
                  ? PlacementOutcome.correct
                  : PlacementOutcome.wrong,
              phase: PlacementPhase.of(i),
            ),
        ],
      ),
    );
    if (!context.mounted) throw StateError('Guide was unmounted');
    await context.read<CourseGuideCubit>().load();
    await capture.tab('stats');
    await $(TrainingKeys.progressLevelTest).scrollTo().tap();
    await $(PlacementKeys.start).waitUntilVisible();
    await capture.shot('progress-level-test', ready: PlacementKeys.screen);
  });

  patrolTest('T85 guia primeira aula e capítulo', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.welcome,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await $(CourseGuideKeys.continueButton).scrollTo().tap();
    await $(TrainingKeys.planSave).scrollTo().tap();
    await capture.shot('lesson-first');
    await capture.tab('catalog');
    await capture.shot('catalog-first');
    await $(CourseGuideKeys.chapter('pilares.c1')).scrollTo();
    await capture.shot(
      'chapter-first',
      ready: CourseGuideKeys.chapter('pilares.c1'),
    );
  });

  patrolTest('T85 guia com aulas já concluídas', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.large,
    );
    final capture = TrainingCaptureRobot($);
    await capture.openGuide();
    await capture.shot('lesson-returning');
    await capture.tab('catalog');
    await $(CourseGuideKeys.chapter('pilares.c1')).scrollTo();
    await capture.shot(
      'chapter-returning',
      ready: CourseGuideKeys.chapter('pilares.c1'),
    );
  });
}
