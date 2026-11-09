import '../../data/repositories/treinador/treinador_repository.dart';
import '../../data/services/firebase/treinador_service.dart';
import 'core.dart';

/// O Treinador de partidas (T87): conta ligada, partidas analisadas e o
/// progresso dos exercícios. Sem Firebase, nenhum.
class TreinadorDependencies {
  TreinadorDependencies._({required this.treinador});

  factory TreinadorDependencies.create(CoreDependencies core) =>
      TreinadorDependencies._(
        treinador: core.firebase
            ? CloudTreinadorRepository(
                FirebaseTreinadorService(),
                core.preferences,
                uids: core.auth.changes.map((account) => account?.uid),
                currentUid: core.uid,
              )
            : const NoTreinadorRepository(),
      );

  final TreinadorRepository treinador;
}
