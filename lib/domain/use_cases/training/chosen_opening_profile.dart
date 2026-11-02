import '../../models/training/training_state.dart';
import 'opening_parts.dart';

/// O perfil de abertura que o aluno escolheu, ou nulo se ainda não escolheu.
///
/// Mesma regra de `needsOpeningProfile`: instalação antiga com repertório ou
/// aula de abertura feita tem escolha implícita (o perfil salvo).
String? chosenOpeningProfile(TrainingState state) {
  final chosen =
      state.openingProfileStartPart.isNotEmpty ||
      state.openings.isNotEmpty ||
      state.completedLessons.keys.any(
        (id) => openingProfileForLesson(id) != null,
      );
  return chosen ? state.openingProfile : null;
}
