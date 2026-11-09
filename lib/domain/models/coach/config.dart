import 'json.dart';

/// `treinador_config/geral` (o painel grava).
final class CoachConfig {
  const CoachConfig({
    this.active = true,
    this.exercisesPerGame = 4,
    this.monthlyBudgetUsd,
    this.freeQueue = false,
  });

  static const standard = CoachConfig();

  final bool active;

  /// 1 a 6 (padrão 4).
  final int exercisesPerGame;
  final double? monthlyBudgetUsd;

  /// O orçamento do mês chegou a 100%: quem não assina espera na fila.
  final bool freeQueue;

  static CoachConfig fromJson(Object? json) {
    final m = asMap(json);
    return CoachConfig(
      active: m['ativo'] != false,
      exercisesPerGame: integer(m['exerciciosPorPartida'], 4).clamp(1, 6),
      monthlyBudgetUsd: number(m['orcamentoMensalUsd']),
      freeQueue: logical(m['filaGratis']),
    );
  }

  Map<String, Object?> toJson() => {
    'ativo': active,
    'exerciciosPorPartida': exercisesPerGame,
    'orcamentoMensalUsd': monthlyBudgetUsd,
    'filaGratis': freeQueue,
  };
}

/// Uma partida-modelo de uma abertura (`treinador_modelos/{eco}`).
final class ModelGame {
  const ModelGame({
    required this.source,
    required this.title,
    this.subtitle,
    this.url,
  });

  /// `torneio`, `historica`, `estudo` ou `artigo`.
  final String source;
  final String title;
  final String? subtitle;
  final String? url;

  static ModelGame? fromJson(Object? json) {
    final m = asMap(json);
    final title = text(m['titulo']);
    if (title == null) return null;
    return ModelGame(
      source: text(m['fonte']) ?? '',
      title: title,
      subtitle: text(m['subtitulo']),
      url: text(m['url']),
    );
  }

  /// O documento guarda a lista em `modelos` (Firestore não aceita lista na
  /// raiz).
  static List<ModelGame> listFromJson(Object? json) => [
    for (final m in list(json is Map ? json['modelos'] : json))
      ?ModelGame.fromJson(m),
  ];

  Map<String, Object?> toJson() => {
    'fonte': source,
    'titulo': title,
    'subtitulo': subtitle,
    'url': url,
  };
}
