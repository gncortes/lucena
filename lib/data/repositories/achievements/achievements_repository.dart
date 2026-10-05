import '../../../domain/models/achievement.dart';

/// As conquistas: as definições (dados) e as que já apareceram ao jogador.
abstract class AchievementsRepository {
  /// Todas as conquistas, na ordem da lista.
  Future<List<Achievement>> all();

  /// As já mostradas, com o instante em que apareceram.
  Future<Map<String, DateTime>> unlocked();

  /// Marca [ids] como mostradas no instante [at].
  Future<void> unlock(Iterable<String> ids, DateTime at);
}
