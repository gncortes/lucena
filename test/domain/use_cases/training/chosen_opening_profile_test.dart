import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/chosen_opening_profile.dart';

void main() {
  test('sem escolha, sem repertorio e sem aula de abertura feita: nulo', () {
    expect(
      chosenOpeningProfile(
        TrainingState(course: TrainingCourse.pilares, installSeed: 'x'),
      ),
      isNull,
    );
  });
  test('escolha registrada vale o perfil salvo', () {
    final state = TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 'x',
    ).copyWith(openingProfile: 'agressivo', openingProfileStartPart: 'chosen');
    expect(chosenOpeningProfile(state), 'agressivo');
  });
  test('instalacao antiga com aula de abertura feita vale o perfil salvo', () {
    final state = TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 'x',
    ).copyWith(completedLessons: {'pilares.ab1.london1': '2026-01-01'});
    expect(chosenOpeningProfile(state), 'solido');
  });
}
