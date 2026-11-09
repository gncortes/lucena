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
/// vão `feitos`, `acertos`, `pontos`, o mapa [primeiras] (como `resultados`)
/// e [viuAnalise] (contrato T87, lidos pelo painel).
final class ProgressoPartida {
  const ProgressoPartida({
    this.resultados = const [],
    this.primeiras = const {},
    this.viuAnalise = false,
    this.feitosRemoto,
    this.acertosRemoto,
    this.pontosRemoto,
  });

  static const vazio = ProgressoPartida();

  final List<ResultadoExercicio> resultados;

  /// Exercício `n` → acertou de primeira (uma tentativa, sem a solução).
  /// Gravado uma vez por exercício: refazer não muda.
  final Map<int, bool> primeiras;

  /// Abriu a análise completa da partida.
  final bool viuAnalise;

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
    primeiras: primeiras.containsKey(resultado.n)
        ? primeiras
        : {
            ...primeiras,
            resultado.n:
                resultado.acertou &&
                resultado.tentativas == 1 &&
                !resultado.viuSolucao,
          },
    viuAnalise: viuAnalise,
  );

  /// "Refazer os exercícios": zera a rodada, mas não o que foi de primeira
  /// nem a análise vista.
  ProgressoPartida recomecar() =>
      ProgressoPartida(primeiras: primeiras, viuAnalise: viuAnalise);

  ProgressoPartida comAnaliseVista() => ProgressoPartida(
    resultados: resultados,
    primeiras: primeiras,
    viuAnalise: true,
    feitosRemoto: feitosRemoto,
    acertosRemoto: acertosRemoto,
    pontosRemoto: pontosRemoto,
  );

  /// O espelho que vai para o servidor.
  Map<String, Object?> toRemoto() => {
    'feitos': feitos,
    'acertos': acertos,
    'pontos': pontos,
    'resultados': {for (final e in primeiras.entries) '${e.key}': e.value},
    if (viuAnalise) 'viuAnalise': true,
  };

  static Map<int, bool> _primeiras(Object? json) => {
    for (final e in mapa(json).entries)
      if ((int.tryParse(e.key), e.value) case (final int n, final bool v)) n: v,
  };

  /// Lê o do aparelho (`resultados` em lista, `primeiras` em mapa) ou o
  /// espelho do servidor (`resultados` em mapa).
  static ProgressoPartida fromJson(Object? json) {
    final m = mapa(json);
    final bruto = m['resultados'];
    final resultados = [
      if (bruto is List)
        for (final r in bruto) ?ResultadoExercicio.fromJson(r),
    ];
    return ProgressoPartida(
      resultados: resultados,
      primeiras: bruto is Map ? _primeiras(bruto) : _primeiras(m['primeiras']),
      viuAnalise: logico(m['viuAnalise']),
      feitosRemoto: inteiroOuNulo(m['feitos']),
      acertosRemoto: inteiroOuNulo(m['acertos']),
      pontosRemoto: inteiroOuNulo(m['pontos']),
    );
  }

  /// O do aparelho.
  Map<String, Object?> toJson() => {
    ...toRemoto(),
    'primeiras': {for (final e in primeiras.entries) '${e.key}': e.value},
    'resultados': [for (final r in resultados) r.toJson()],
  };
}
