import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';

void main() {
  test('save antigo com a aba "progress" abre em Estatísticas', () {
    final json = TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 's',
    ).toJson()..['tab'] = 'progress';
    expect(TrainingState.fromJson(json).tab, CourseGuideTab.stats);
  });
}
