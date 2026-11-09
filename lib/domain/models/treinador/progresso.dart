import 'json.dart';

/// Como foi um exercício da partida.
final class ResultadoExercicio {
  const ResultadoExercicio({
    required this.n,
    required this.acertou,
    required this.pontos,
    this.tentativas = 1,
    this.viuSolucao = false,
  });

  final int n;

  /// Achou o lance (em qualquer tentativa, sem ver a solução).
  final bool acertou;
  final int pontos;
  final int tentativas;
  final bool viuSolucao;

  static ResultadoExercicio? fromJson(Object? json) {
    final m = mapa(json);
    final n = inteiroOuNulo(m['n']);
    if (n == null) return null;
    return ResultadoExercicio(
      n: n,
      acertou: logico(m['acertou']),
      pontos: inteiro(m['pontos']),
      tentativas: inteiro(m['tentativas'], 1),
      viuSolucao: logico(m['viuSolucao']),
    );
  }

  Map<String, Object?> toJson() => {
    'n': n,
    'acertou': acertou,
    'pontos': pontos,
    'tentativas': tentativas,
    'viuSolucao': viuSolucao,
  };
}

/// O progresso dos exercícios de uma partida. No aparelho guarda também cada
/// [resultados] e o exercício aberto; em `users/{uid}/partidas/{id}.progresso`
/// vão só `feitos`, `acertos` e `pontos` (contrato T87).
final class ProgressoPartida {
  const ProgressoPartida({
    this.resultados = const [],
    this.feitosRemoto,
    this.acertosRemoto,
    this.pontosRemoto,
  });

  static const vazio = ProgressoPartida();

  final List<ResultadoExercicio> resultados;

  // Lidos do espelho do servidor quando o aparelho não tem os resultados
  // (outro aparelho, reinstalação).
  final int? feitosRemoto;
  final int? acertosRemoto;
  final int? pontosRemoto;

  int get feitos =>
      resultados.isEmpty ? (feitosRemoto ?? 0) : resultados.length;

  int get acertos => resultados.isEmpty
      ? (acertosRemoto ?? 0)
      : resultados.where((r) => r.acertou).length;

  int get pontos => resultados.isEmpty
      ? (pontosRemoto ?? 0)
      : resultados.fold(0, (soma, r) => soma + r.pontos);

  /// Terminou os [total] exercícios.
  bool completo(int total) => total > 0 && feitos >= total;

  /// O próximo exercício a fazer (1 a [total]); nulo se acabou.
  int? proximo(int total) => completo(total) ? null : feitos + 1;

  ProgressoPartida com(ResultadoExercicio resultado) => ProgressoPartida(
    resultados: [
      for (final r in resultados)
        if (r.n != resultado.n) r,
      resultado,
    ]..sort((a, b) => a.n.compareTo(b.n)),
  );

  /// O espelho que vai para o servidor.
  Map<String, Object?> toRemoto() => {
    'feitos': feitos,
    'acertos': acertos,
    'pontos': pontos,
  };

  static ProgressoPartida fromJson(Object? json) {
    final m = mapa(json);
    final resultados = [
      for (final r in lista(m['resultados'])) ?ResultadoExercicio.fromJson(r),
    ];
    return ProgressoPartida(
      resultados: resultados,
      feitosRemoto: inteiroOuNulo(m['feitos']),
      acertosRemoto: inteiroOuNulo(m['acertos']),
      pontosRemoto: inteiroOuNulo(m['pontos']),
    );
  }

  Map<String, Object?> toJson() => {
    ...toRemoto(),
    'resultados': [for (final r in resultados) r.toJson()],
  };
}
