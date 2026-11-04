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

  // H-TRE-17 gap 4: aba só guarda onde o aluno parou; nome desconhecido não
  // pode impedir de ler o progresso inteiro.
  test('aba desconhecida volta para Lição sem perder o resto', () {
    final json = TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 's',
      onboardingDone: true,
    ).toJson()..['tab'] = 'aba-do-futuro';
    final read = TrainingState.fromJson(json);
    expect(read.tab, CourseGuideTab.lesson);
    expect(read.onboardingDone, isTrue);
  });
}
