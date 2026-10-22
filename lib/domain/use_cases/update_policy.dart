/// O que o app pede de atualização (E1.32 §3).
enum UpdateDecision { none, required, recommended }

/// Decide a atualização pelo build instalado (`versionCode`, que só cresce)
/// e pelas chaves `update_*` do Remote Config.
abstract final class UpdatePolicy {
  /// [seen] é o valor da recomendada que a pessoa já viu (0: nenhum).
  /// [playHasUpdate] nulo: a Play não respondeu (app fora da Play).
  ///
  /// Abaixo da mínima bloqueia, menos quando a Play diz que não há versão
  /// nova: aí vira a recomendada (um número alto antes do rollout não tranca
  /// ninguém). A recomendada aparece uma vez por valor.
  static UpdateDecision decide({
    required int build,
    required int minBuild,
    required int recommendedBuild,
    required int seen,
    required bool? playHasUpdate,
  }) {
    if (build < minBuild && playHasUpdate != false) {
      return UpdateDecision.required;
    }
    final target = recommendedTarget(
      minBuild: minBuild,
      recommendedBuild: recommendedBuild,
    );
    if (build < target && seen != target) return UpdateDecision.recommended;
    return UpdateDecision.none;
  }

  /// O valor que a recomendada guarda como vista: a mínima, quando ela
  /// virou recomendada, conta como um valor novo.
  static int recommendedTarget({
    required int minBuild,
    required int recommendedBuild,
  }) => minBuild > recommendedBuild ? minBuild : recommendedBuild;
}
