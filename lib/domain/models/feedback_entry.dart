/// O assunto do "Enviar feedback" (E1.26).
enum FeedbackType {
  problem('problema'),
  idea('ideia'),
  praise('elogio');

  const FeedbackType(this.code);

  /// O código mandado à nuvem (a regra do Firestore só aceita estes).
  final String code;

  static FeedbackType? byCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// O que vai para `feedback/{id}`: o texto livre do Perfil. Sem uid; a versão
/// do app e o modelo do celular vão juntos.
class FeedbackEntry {
  const FeedbackEntry.free({
    required this.type,
    required this.text,
    this.language,
  });

  /// O tamanho máximo do texto livre.
  static const maxText = 500;

  final FeedbackType type;
  final String text;
  final String? language;

  String get kind => 'livre';

  /// O texto sem espaços nas pontas e cortado em [maxText].
  static String clip(String text) {
    final trimmed = text.trim();
    return trimmed.length > maxText ? trimmed.substring(0, maxText) : trimmed;
  }

  /// O documento, sem o `createdAt` (quem grava põe o horário do servidor).
  /// [level] é o nível ou rating do perfil.
  Map<String, Object?> toJson({
    String? level,
    String? appVersion,
    String? model,
    String? manufacturer,
    String? origin,
  }) {
    return {
      'kind': kind,
      'type': type.code,
      'text': clip(text),
      'level': ?_cut(level, 32),
      'origin': ?_cut(origin, 32),
      'appVersion': ?_cut(appVersion, 32),
      'model': ?_cut(model, 64),
      'manufacturer': ?_cut(manufacturer, 64),
      'language': ?_cut(language, 32),
    };
  }
}

String? _cut(String? value, int max) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.length > max ? trimmed.substring(0, max) : trimmed;
}

/// O rascunho do "Enviar feedback": o assunto (se já escolhido) e o texto.
class FeedbackDraft {
  const FeedbackDraft({this.type, this.text = ''});

  factory FeedbackDraft.fromJson(Map<String, Object?> json) => FeedbackDraft(
    type: FeedbackType.byCode(json['type']),
    text: json['text'] is String ? json['text']! as String : '',
  );

  final FeedbackType? type;
  final String text;

  Map<String, Object?> toJson() => {'type': ?type?.code, 'text': text};
}
