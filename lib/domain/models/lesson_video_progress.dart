/// Onde a aula em vídeo parou: retomada depois de pausar, sair ou fechar o
/// app. Guarda a fala e quanto dela já passou, não o instante: o instante
/// muda com a velocidade e com a voz desligada.
class VideoProgress {
  const VideoProgress({
    required this.line,
    this.fraction = 0,
    this.resolved = const {},
  });

  factory VideoProgress.fromJson(Map<String, dynamic> json) => VideoProgress(
    line: json['fala'] as String,
    fraction: (json['fracao'] as num? ?? 0).toDouble().clamp(0.0, 1.0),
    resolved: {for (final id in json['vez'] as List? ?? const []) id as String},
  );

  /// O id da fala da linha principal.
  final String line;

  /// Quanto da fala já tinha passado (0 a 1).
  final double fraction;

  /// As perguntas já respondidas (ids das falas).
  final Set<String> resolved;

  Map<String, dynamic> toJson() => {
    'fala': line,
    'fracao': fraction,
    'vez': [...resolved]..sort(),
  };

  @override
  bool operator ==(Object other) =>
      other is VideoProgress &&
      other.line == line &&
      other.fraction == fraction &&
      other.resolved.length == resolved.length &&
      other.resolved.containsAll(resolved);

  @override
  int get hashCode => Object.hash(line, fraction, resolved.length);
}

/// Os ajustes do player, os mesmos em todas as aulas. As marcações (setas e
/// casas) não estão aqui: usam a preferência das aulas que já existe
/// (`AppSettings.lessonMarks`).
class VideoSettings {
  const VideoSettings({this.captions = true, this.rate = 1});

  factory VideoSettings.fromJson(Map<String, dynamic> json) => VideoSettings(
    captions: json['legenda'] as bool? ?? true,
    rate: normalizeRate((json['velocidade'] as num? ?? 1).toDouble()),
  );

  /// As velocidades do botão, na ordem do ciclo.
  static const rates = [0.75, 1.0, 1.25, 1.5, 2.0];

  /// A velocidade da lista mais próxima de [rate].
  static double normalizeRate(double rate) {
    var best = 1.0;
    for (final r in rates) {
      if ((r - rate).abs() < (best - rate).abs()) best = r;
    }
    return best;
  }

  /// A legenda aparece.
  final bool captions;

  /// A velocidade da voz (e do vídeo).
  final double rate;

  /// A próxima velocidade do ciclo 0,75 → 1 → 1,25 → 1,5 → 2 → 0,75.
  double get nextRate {
    final i = rates.indexOf(normalizeRate(rate));
    return rates[(i + 1) % rates.length];
  }

  VideoSettings copyWith({bool? captions, double? rate}) => VideoSettings(
    captions: captions ?? this.captions,
    rate: rate == null ? this.rate : normalizeRate(rate),
  );

  Map<String, dynamic> toJson() => {'legenda': captions, 'velocidade': rate};

  @override
  bool operator ==(Object other) =>
      other is VideoSettings &&
      other.captions == captions &&
      other.rate == rate;

  @override
  int get hashCode => Object.hash(captions, rate);
}
