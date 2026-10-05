/// Emoção de um personagem: escolhe a imagem e filtra as falas.
enum Emotion {
  calm,
  happy,
  confident,
  playful,
  focused,
  surprised,
  nervous,
  frustrated,
  sad;

  /// A emoção de um código do JSON; desconhecido vira null.
  static Emotion? fromCode(String? code) {
    for (final e in values) {
      if (e.name == code) return e;
    }
    return null;
  }
}

/// Categoria de evento de uma fala, sempre do ponto de vista do personagem
/// ("opponent" é o jogador).
enum LineCategory {
  gameStart,
  bigAdvantage,
  better,
  equal,
  worse,
  bigDisadvantage,
  opponentBlunder,
  ownBlunder,
  strongMove,
  comeback,
  collapse,
  pieceCaptured,
  pieceLost,
  ownPromotion,
  opponentPromotion,
  opponentLowTime,
  ownLowTime,
  timeAdvantage,
  opponentThinking,
  win,
  loss,
  draw;

  /// A categoria de um código do JSON; desconhecida vira null, para dados
  /// novos não quebrarem versões antigas do app.
  static LineCategory? fromCode(String? code) {
    for (final c in values) {
      if (c.name == code) return c;
    }
    return null;
  }
}

/// Para quem é a fala, além de todo jogador.
enum LineAudience {
  /// Só para quem fez aulas com o personagem (o Viktor reencontrando o
  /// ex-aluno).
  student;

  static LineAudience? fromCode(String? code) {
    for (final a in values) {
      if (a.name == code) return a;
    }
    return null;
  }
}

/// Uma fala de personagem, já no idioma do arquivo de onde veio.
class CharacterLine {
  const CharacterLine({
    required this.id,
    required this.category,
    required this.intensity,
    required this.emotion,
    required this.text,
    this.audience,
  });

  final String id;
  final LineCategory category;

  /// De 1 (leve) a 3 (forte).
  final int intensity;
  final Emotion emotion;
  final String text;

  /// Nula: a fala serve para qualquer jogador.
  final LineAudience? audience;

  /// A fala do JSON; null se faltar campo ou a categoria ou emoção for
  /// desconhecida.
  static CharacterLine? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['text'];
    final intensity = json['intensity'];
    final category = LineCategory.fromCode(_string(json['category']));
    final emotion = Emotion.fromCode(_string(json['emotion']));
    if (id is! String || text is! String || intensity is! num) return null;
    if (category == null || emotion == null) return null;
    return CharacterLine(
      id: id,
      category: category,
      intensity: intensity.toInt().clamp(1, 3),
      emotion: emotion,
      text: text,
      audience: LineAudience.fromCode(_string(json['audience'])),
    );
  }

  static String? _string(Object? v) => v is String ? v : null;

  @override
  bool operator ==(Object other) =>
      other is CharacterLine &&
      other.id == id &&
      other.category == category &&
      other.intensity == intensity &&
      other.emotion == emotion &&
      other.text == text &&
      other.audience == audience;

  @override
  int get hashCode =>
      Object.hash(id, category, intensity, emotion, text, audience);
}

/// Um personagem: o rosto de um nível do Maia.
class Character {
  const Character({
    required this.id,
    required this.level,
    required this.name,
    required this.tagline,
    required this.personality,
    required this.traits,
    required this.avatar,
    this.images = const {},
  });

  final String id;

  /// Nível do Maia que ele representa (1000 a 2600).
  final int level;
  final String name;

  /// Frase curta por idioma (código: 'en', 'pt').
  final Map<String, String> tagline;

  /// Descrição da personalidade por idioma.
  final Map<String, String> personality;
  final List<String> traits;

  /// Imagem padrão (asset).
  final String avatar;

  /// Imagem por emoção, quando houver; as que faltam usam [avatar].
  final Map<Emotion, String> images;

  /// A imagem da emoção [e], ou o avatar.
  String imageFor(Emotion? e) => images[e] ?? avatar;

  /// A frase no idioma [language]; sem ela, em inglês; sem inglês, qualquer.
  String taglineIn(String language) =>
      tagline[language] ??
      tagline['en'] ??
      (tagline.isEmpty ? '' : tagline.values.first);

  /// O personagem do JSON; null se faltar campo obrigatório.
  static Character? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final level = json['level'];
    final name = json['name'];
    final avatar = json['avatar'];
    if (id is! String || level is! num || name is! String) return null;
    if (avatar is! String) return null;
    final images = <Emotion, String>{};
    final rawImages = json['images'];
    if (rawImages is Map) {
      rawImages.forEach((key, value) {
        final emotion = Emotion.fromCode(_string(key));
        if (emotion != null && value is String) images[emotion] = value;
      });
    }
    return Character(
      id: id,
      level: level.toInt(),
      name: name,
      tagline: _strings(json['tagline']),
      personality: _strings(json['personality']),
      traits: [
        for (final t in (json['traits'] as List?) ?? const [])
          if (t is String) t,
      ],
      avatar: avatar,
      images: images,
    );
  }

  static String? _string(Object? v) => v is String ? v : null;

  static Map<String, String> _strings(Object? raw) => {
    if (raw is Map)
      for (final e in raw.entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
  };

  @override
  bool operator ==(Object other) => other is Character && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
