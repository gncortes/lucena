import '../models/goal_preference.dart';

/// O que a tela inicial esconde de quem está aprendendo a jogar (objetivo
/// "Aprender a jogar"): o rating ainda não diz nada e os finais em destaque
/// ainda não servem.
abstract final class BeginnerHome {
  /// As partidas que mexem no rating antes de o número aparecer.
  static const gamesForRating = 3;

  /// O número do rating aparece? Quem aprende a jogar só o vê depois de
  /// [gamesForRating] partidas que contaram.
  static bool showsRating(GoalPreference? goal, int ratedGames) =>
      goal != GoalPreference.learn || ratedGames >= gamesForRating;

  /// "Finais em destaque" (o final do dia e o destaque) aparece? Quem
  /// aprende a jogar só o vê depois da primeira vitória na Jornada
  /// ([journeyStarted], contra o Coco).
  static bool showsFeatured(GoalPreference? goal, bool journeyStarted) =>
      goal != GoalPreference.learn || journeyStarted;
}
