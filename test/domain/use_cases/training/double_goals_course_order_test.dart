import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/domain/use_cases/training/double_training_goals.dart';

import '../../../../testing/training/training_scenario_builder.dart';

void main() {
  // H-TRE-17 gap 7: dobrar o dia segue a ordem do curso, como o dia normal.
  test('dobrar não pula lição ainda não publicada nem fora da ordem', () {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final content = scenario.content;
    final extra = content.lessons.firstWhere((l) => l.id == 'theme10');
    final state = CompleteTrainingLesson(scenario.now, scenario.config)(
      scenario.allDone(),
      content,
      extra,
    );
    final next = content.lessons.firstWhere(
      (l) =>
          l.visible &&
          !state.completedLessons.containsKey(l.id) &&
          l.inCourseOrder,
    );
    TrainingResources withNext(
      TrainingLesson Function(TrainingLesson) change,
    ) => TrainingResources(
      lessons: [
        for (final l in content.lessons) l.id == next.id ? change(l) : l,
      ],
      banks: content.banks,
      openings: content.openings,
      errorFeedback: content.errorFeedback,
      offlineChapters: content.offlineChapters,
    );
    final blocked = withNext(
      (l) => TrainingLesson(
        id: l.id,
        kind: l.kind,
        title: l.title,
        group: l.group,
        groupId: l.groupId,
        partId: l.partId,
        partTitle: l.partTitle,
        visible: false,
        published: false,
      ),
    );
    List<String> lessonsAfter(TrainingResources r) =>
        DoubleTrainingGoals(scenario.now, scenario.config)(state, r).day!.goals
            .where((g) => g.kind == GoalKind.lesson && !g.done)
            .map((g) => g.ref)
            .toList();
    expect(lessonsAfter(content), contains(next.id));
    final added = lessonsAfter(blocked);
    expect(added, isNot(contains(next.id)));
    expect(
      added,
      isEmpty,
      reason:
          'a lição seguinte não saiu; nenhuma posterior pode passar na frente',
    );
  });
}
