import 'json.dart';

/// `treinador_config/geral` (o painel grava).
final class TreinadorConfig {
  const TreinadorConfig({
    this.ativo = true,
    this.exerciciosPorPartida = 4,
    this.orcamentoMensalUsd,
    this.filaGratis = false,
  });

  static const padrao = TreinadorConfig();

  final bool ativo;

  /// 1 a 6 (padrão 4).
  final int exerciciosPorPartida;
  final double? orcamentoMensalUsd;

  /// O orçamento do mês chegou a 100%: quem não assina espera na fila.
  final bool filaGratis;

  static TreinadorConfig fromJson(Object? json) {
    final m = mapa(json);
    return TreinadorConfig(
      ativo: m['ativo'] != false,
      exerciciosPorPartida: inteiro(m['exerciciosPorPartida'], 4).clamp(1, 6),
      orcamentoMensalUsd: numero(m['orcamentoMensalUsd']),
      filaGratis: logico(m['filaGratis']),
    );
  }

  Map<String, Object?> toJson() => {
    'ativo': ativo,
    'exerciciosPorPartida': exerciciosPorPartida,
    'orcamentoMensalUsd': orcamentoMensalUsd,
    'filaGratis': filaGratis,
  };
}

/// Uma partida-modelo de uma abertura (`treinador_modelos/{eco}`).
final class PartidaModelo {
  const PartidaModelo({
    required this.fonte,
    required this.titulo,
    this.subtitulo,
    this.url,
  });

  /// `torneio`, `historica`, `estudo` ou `artigo`.
  final String fonte;
  final String titulo;
  final String? subtitulo;
  final String? url;

  static PartidaModelo? fromJson(Object? json) {
    final m = mapa(json);
    final titulo = texto(m['titulo']);
    if (titulo == null) return null;
    return PartidaModelo(
      fonte: texto(m['fonte']) ?? '',
      titulo: titulo,
      subtitulo: texto(m['subtitulo']),
      url: texto(m['url']),
    );
  }

  /// O documento guarda a lista em `modelos` (Firestore não aceita lista na
  /// raiz).
  static List<PartidaModelo> listFromJson(Object? json) => [
    for (final m in lista(json is Map ? json['modelos'] : json))
      ?PartidaModelo.fromJson(m),
  ];

  Map<String, Object?> toJson() => {
    'fonte': fonte,
    'titulo': titulo,
    'subtitulo': subtitulo,
    'url': url,
  };
}
