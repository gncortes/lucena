import '../models/race.dart';

/// Os erros de uma família de finais (categoria do catálogo) nas últimas
/// Corridas.
class RaceCategoryScore {
  const RaceCategoryScore({
    required this.category,
    required this.errors,
    required this.total,
  });

  final String category;
  final int errors;
  final int total;

  double get rate => total == 0 ? 0 : errors / total;
}

/// Em que finais o jogador mais erra, pelas últimas Corridas. Conta por
/// categoria (Finais de peão, Torre e peões...): um tipo fino de final quase
/// nunca junta problemas suficientes em poucas Corridas.
class RaceDiagnosis {
  const RaceDiagnosis({
    required this.runs,
    this.weak = const [],
    this.good = const [],
  });

  /// O diagnóstico do [history] (a mais recente primeiro). [problems] dá a
  /// categoria de cada tipo de final.
  factory RaceDiagnosis.of(
    List<RaceResult> history,
    List<RaceProblem> problems,
  ) {
    final categoryOf = {
      for (final problem in problems) problem.subcategory: problem.category,
    };
    final recent = history.take(lastRuns).toList();
    final errors = <String, int>{};
    final totals = <String, int>{};
    for (final result in recent) {
      for (final answer in result.run.answers) {
        final category = categoryOf[answer.subcategory];
        if (category == null) continue;
        totals[category] = (totals[category] ?? 0) + 1;
        if (!answer.correct) errors[category] = (errors[category] ?? 0) + 1;
      }
    }
    final scores = [
      for (final MapEntry(key: category, value: total) in totals.entries)
        if (total >= minProblems)
          RaceCategoryScore(
            category: category,
            errors: errors[category] ?? 0,
            total: total,
          ),
    ];
    final weak = [
      for (final score in scores)
        if (score.rate >= weakRate) score,
    ]..sort(_worstFirst);
    final good = [
      for (final score in scores)
        if (score.rate < weakRate) score,
    ]..sort(_worstFirst);
    return RaceDiagnosis(runs: recent.length, weak: weak, good: good);
  }

  /// Quantas Corridas (as mais recentes) entram na conta.
  static const lastRuns = 5;

  /// Com quantas Corridas o diagnóstico aparece.
  static const neededRuns = 3;

  /// Quantos problemas uma categoria precisa para entrar.
  static const minProblems = 5;

  /// A partir de que taxa de erro a categoria precisa de treino.
  static const weakRate = 0.3;

  /// Quantas Corridas entraram na conta (no máximo [lastRuns]).
  final int runs;

  /// As categorias que precisam de treino, da pior para a melhor.
  final List<RaceCategoryScore> weak;

  /// As que vão bem.
  final List<RaceCategoryScore> good;

  /// Já há Corridas e problemas suficientes para mostrar o resultado.
  bool get ready => runs >= neededRuns && (weak.isNotEmpty || good.isNotEmpty);

  /// O ponto mais fraco, se houver.
  RaceCategoryScore? get weakest => weak.firstOrNull;

  // Maior taxa de erro primeiro; empate, o que tem mais problemas.
  static int _worstFirst(RaceCategoryScore a, RaceCategoryScore b) {
    final byRate = b.rate.compareTo(a.rate);
    return byRate != 0 ? byRate : b.total.compareTo(a.total);
  }
}
