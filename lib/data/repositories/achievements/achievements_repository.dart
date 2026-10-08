import '../../../domain/models/achievement.dart';

/// As conquistas: as definições (dados) e as que já apareceram ao jogador.
abstract class AchievementsRepository {
  /// Todas as conquistas, na ordem da lista.
  Future<List<Achievement>> all();

  /// As já mostradas, pelo id, com o instante e a origem (quando gravada).
  Future<Map<String, UnlockedAchievement>> unlocked();

  /// Marca [achievements] como mostradas. As já gravadas ficam como estavam.
  Future<void> unlock(Iterable<UnlockedAchievement> achievements);
}
