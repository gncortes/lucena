import '../../data/repositories/coach/coach_repository.dart';
import '../../data/services/firebase/coach_service.dart';
import 'core.dart';

/// O Treinador de partidas (T87): conta ligada, partidas analisadas e o
/// progresso dos exercícios. Sem Firebase, nenhum.
class CoachDependencies {
  CoachDependencies._({required this.coach});

  factory CoachDependencies.create(CoreDependencies core) =>
      CoachDependencies._(
        coach: core.firebase
            ? CloudCoachRepository(
                FirebaseCoachService(),
                core.preferences,
                uids: core.auth.changes.map((account) => account?.uid),
                currentUid: core.uid,
              )
            : const NoCoachRepository(),
      );

  final CoachRepository coach;
}
