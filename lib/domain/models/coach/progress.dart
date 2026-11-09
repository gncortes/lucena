import 'json.dart';

/// Como foi um exercício da partida.
final class ExerciseResult {
  const ExerciseResult({
    required this.n,
    required this.solved,
    required this.points,
    this.attempts = 1,
    this.sawSolution = false,
    this.hints = 0,
  });

  final int n;

  /// Achou o lance (em qualquer tentativa, sem ver a solução).
  final bool solved;
  final int points;
  final int attempts;
  final bool sawSolution;

  /// Quantas dicas pediu (cada uma desce um degrau dos pontos).
  final int hints;

  static ExerciseResult? fromJson(Object? json) {
    final m = asMap(json);
    final n = intOrNull(m['n']);
    if (n == null) return null;
    return ExerciseResult(
      n: n,
      solved: logical(m['acertou']),
      points: integer(m['pontos']),
      attempts: integer(m['tentativas'], 1),
      sawSolution: logical(m['viuSolucao']),
      hints: integer(m['dicas']),
    );
  }

  Map<String, Object?> toJson() => {
    'n': n,
    'acertou': solved,
    'pontos': points,
    'tentativas': attempts,
    'viuSolucao': sawSolution,
    'dicas': hints,
  };
}

/// O progresso dos exercícios de uma partida. No aparelho guarda também cada
/// [results] e o exercício aberto; em `users/{uid}/partidas/{id}.progresso`
/// vão `feitos`, `acertos`, `pontos`, o mapa [firstOnes] (como `resultados`)
/// e [sawAnalysis] (contrato T87, lidos pelo painel).
final class GameProgress {
  const GameProgress({
    this.results = const [],
    this.firstOnes = const {},
    this.sawAnalysis = false,
    this.remoteDone,
    this.remoteCorrect,
    this.remotePoints,
  });

  static const empty = GameProgress();

  final List<ExerciseResult> results;

  /// Exercício `n` → acertou de primeira (uma tentativa, sem dica nem a
  /// solução).
  /// Gravado uma vez por exercício: refazer não muda.
  final Map<int, bool> firstOnes;

  /// Abriu a análise completa da partida.
  final bool sawAnalysis;

  // Lidos do espelho do servidor quando o aparelho não tem os resultados
  // (outro aparelho, reinstalação).
  final int? remoteDone;
  final int? remoteCorrect;
  final int? remotePoints;

  int get doneCount => results.isEmpty ? (remoteDone ?? 0) : results.length;

  int get corrects => results.isEmpty
      ? (remoteCorrect ?? 0)
      : results.where((r) => r.solved).length;

  int get points => results.isEmpty
      ? (remotePoints ?? 0)
      : results.fold(0, (sum, r) => sum + r.points);

  /// Terminou os [total] exercícios.
  bool isComplete(int total) => total > 0 && doneCount >= total;

  /// O próximo exercício a fazer (1 a [total]); nulo se acabou.
  int? next(int total) => isComplete(total) ? null : doneCount + 1;

  GameProgress withValue(ExerciseResult result) => GameProgress(
    results: [
      for (final r in results)
        if (r.n != result.n) r,
      result,
    ]..sort((a, b) => a.n.compareTo(b.n)),
    firstOnes: firstOnes.containsKey(result.n)
        ? firstOnes
        : {
            ...firstOnes,
            result.n:
                result.solved &&
                result.attempts == 1 &&
                result.hints == 0 &&
                !result.sawSolution,
          },
    sawAnalysis: sawAnalysis,
  );

  /// "Refazer os exercícios": zera a rodada, mas não o que foi de primeira
  /// nem a análise vista.
  GameProgress restartExercises() =>
      GameProgress(firstOnes: firstOnes, sawAnalysis: sawAnalysis);

  GameProgress withAnalysisViewed() => GameProgress(
    results: results,
    firstOnes: firstOnes,
    sawAnalysis: true,
    remoteDone: remoteDone,
    remoteCorrect: remoteCorrect,
    remotePoints: remotePoints,
  );

  /// O espelho que vai para o servidor.
  Map<String, Object?> toRemote() => {
    'feitos': doneCount,
    'acertos': corrects,
    'pontos': points,
    'resultados': {for (final e in firstOnes.entries) '${e.key}': e.value},
    if (sawAnalysis) 'viuAnalise': true,
  };

  static Map<int, bool> _first(Object? json) => {
    for (final e in asMap(json).entries)
      if ((int.tryParse(e.key), e.value) case (final int n, final bool v)) n: v,
  };

  /// Lê o do aparelho (`resultados` em lista, `primeiras` em mapa) ou o
  /// espelho do servidor (`resultados` em mapa).
  static GameProgress fromJson(Object? json) {
    final m = asMap(json);
    final raw = m['resultados'];
    final results = [
      if (raw is List)
        for (final r in raw) ?ExerciseResult.fromJson(r),
    ];
    return GameProgress(
      results: results,
      firstOnes: raw is Map ? _first(raw) : _first(m['primeiras']),
      sawAnalysis: logical(m['viuAnalise']),
      remoteDone: intOrNull(m['feitos']),
      remoteCorrect: intOrNull(m['acertos']),
      remotePoints: intOrNull(m['pontos']),
    );
  }

  /// O do aparelho.
  Map<String, Object?> toJson() => {
    ...toRemote(),
    'primeiras': {for (final e in firstOnes.entries) '${e.key}': e.value},
    'resultados': [for (final r in results) r.toJson()],
  };
}
