/// O gênero de uma voz, quando o sistema informa (o iOS informa; o Android,
/// não).
enum VoiceGender {
  male,
  female;

  static VoiceGender? fromCode(String? code) => switch (code?.toLowerCase()) {
    'male' => male,
    'female' => female,
    _ => null,
  };

  /// O gênero dos JSONs de voz (`m`, `f`); outra coisa, nulo.
  static VoiceGender? fromLetter(Object? letter) => switch (letter) {
    'm' => male,
    'f' => female,
    _ => null,
  };
}

/// A qualidade de uma voz, como o sistema informa (o Android diz "very
/// high" a "very low"; o iOS, "premium", "enhanced" e "default").
enum VoiceQuality {
  veryLow,
  low,
  normal,
  high,
  veryHigh,
  unknown;

  /// A qualidade que o sistema informou ([raw]); o que não se reconhece é
  /// [unknown].
  static VoiceQuality fromSystem(Object? raw) {
    if (raw is! String) return unknown;
    return switch (raw.trim().toLowerCase().replaceAll(RegExp('[ _-]'), '')) {
      'veryhigh' || 'premium' => veryHigh,
      'high' || 'enhanced' => high,
      'normal' || 'default' => normal,
      'low' => low,
      'verylow' => veryLow,
      _ => unknown,
    };
  }
}

/// A idade de um personagem: dá o tom e o ritmo da fala dele, multiplicados
/// sobre os da voz escolhida.
enum VoiceAge {
  child(pitch: 1.3, rate: 1.1),
  young(pitch: 1.05, rate: 1.08),
  adult(pitch: 1, rate: 1),
  elder(pitch: 0.8, rate: 0.85);

  const VoiceAge({required this.pitch, required this.rate});

  final double pitch;
  final double rate;

  /// A idade do JSON (`crianca`, `jovem`, `adulto`, `idoso`); outra coisa
  /// vira [adult].
  static VoiceAge fromCode(Object? code) => switch (code) {
    'crianca' || 'criança' => child,
    'jovem' => young,
    'idoso' => elder,
    _ => adult,
  };
}

/// O tom que o usuário dá a uma voz: muda o tom e o ritmo dela, de leve.
enum VoiceTone {
  /// Mais grave e um pouco mais lenta.
  deep(pitch: 0.88, rate: 0.96),

  /// A voz como ela é.
  natural(pitch: 1, rate: 1),

  /// Calma: um pouco mais lenta e leve.
  soft(pitch: 1.05, rate: 0.9),

  /// Mais aguda e um pouco mais rápida.
  high(pitch: 1.15, rate: 1.04);

  const VoiceTone({required this.pitch, required this.rate});

  final double pitch;

  /// Multiplica a velocidade.
  final double rate;

  static VoiceTone? fromName(Object? name) {
    for (final tone in values) {
      if (tone.name == name) return tone;
    }
    return null;
  }
}

/// Uma voz do sintetizador do aparelho.
class TtsVoice {
  const TtsVoice({
    required this.id,
    required this.locale,
    this.gender,
    this.quality = VoiceQuality.unknown,
  });

  /// O nome com que o sistema a identifica (e com que ela é pedida).
  final String id;

  /// O idioma da voz, como o sistema informa (`pt-BR`, `en_US`).
  final String locale;
  final VoiceGender? gender;

  /// A qualidade que o sistema informa; [VoiceQuality.unknown] se não diz.
  final VoiceQuality quality;

  /// O idioma sem a região, em minúsculas (`pt`).
  String get language => _parts(locale).$1;

  /// A região em maiúsculas (`BR`), ou nula.
  String? get region => _parts(locale).$2;

  static (String, String?) _parts(String tag) {
    final parts = tag.split(RegExp('[-_]'));
    return (
      parts.first.toLowerCase(),
      parts.length > 1 ? parts[1].toUpperCase() : null,
    );
  }

  /// As vozes de [voices] que falam [languageTag] (`pt`, `pt-BR`), na ordem
  /// do sistema. Havendo vozes da região do app, só elas: o português do app
  /// é o do Brasil (`pt` vira `pt-BR`), e o de Portugal tem o idioma próprio
  /// (`pt-PT`). Sem voz da região, as do idioma em qualquer região.
  static List<TtsVoice> forLanguage(List<TtsVoice> voices, String languageTag) {
    final (language, tagRegion) = _parts(languageTag);
    final region = tagRegion ?? defaultRegions[language];
    final same = [
      for (final v in voices)
        if (v.language == language) v,
    ];
    if (region == null) return same;
    final local = [
      for (final v in same)
        if (v.region == region) v,
    ];
    return local.isEmpty ? same : local;
  }

  /// A região de cada idioma do app que vem sem região.
  static const defaultRegions = {'pt': 'BR', 'en': 'US', 'zh': 'CN'};

  @override
  bool operator ==(Object other) =>
      other is TtsVoice &&
      other.id == id &&
      other.locale == locale &&
      other.gender == gender &&
      other.quality == quality;

  @override
  int get hashCode => Object.hash(id, locale, gender, quality);

  @override
  String toString() => 'TtsVoice($id, $locale)';
}

/// Como um personagem fala: o gênero e a idade dele. O app escolhe a voz e
/// a idade dá o tom e o ritmo ([VoiceAge]).
class CharacterVoiceProfile {
  const CharacterVoiceProfile({
    required this.characterId,
    this.gender = VoiceGender.male,
    this.age = VoiceAge.adult,
  });

  /// O perfil neutro, para um personagem sem perfil no JSON.
  const CharacterVoiceProfile.neutral(this.characterId)
    : gender = VoiceGender.male,
      age = VoiceAge.adult;

  final String characterId;
  final VoiceGender gender;
  final VoiceAge age;

  /// O perfil do JSON (`{"genero": "m", "idade": "adulto"}`); campos
  /// ausentes ou estranhos ficam em homem adulto.
  static CharacterVoiceProfile fromJson(
    String characterId,
    Map<String, dynamic> json,
  ) => CharacterVoiceProfile(
    characterId: characterId,
    gender: VoiceGender.fromLetter(json['genero']) ?? VoiceGender.male,
    age: VoiceAge.fromCode(json['idade']),
  );

  @override
  bool operator ==(Object other) =>
      other is CharacterVoiceProfile &&
      other.characterId == characterId &&
      other.gender == gender &&
      other.age == age;

  @override
  int get hashCode => Object.hash(characterId, gender, age);
}

/// A voz com que uma fala sai: qual voz, o tom e a velocidade.
class ResolvedVoice {
  const ResolvedVoice({
    required this.voice,
    required this.pitch,
    required this.rate,
  });

  final TtsVoice voice;
  final double pitch;
  final double rate;

  @override
  bool operator ==(Object other) =>
      other is ResolvedVoice &&
      other.voice == voice &&
      other.pitch == pitch &&
      other.rate == rate;

  @override
  int get hashCode => Object.hash(voice, pitch, rate);

  @override
  String toString() => 'ResolvedVoice(${voice.id}, $pitch, $rate)';
}

/// As preferências da voz: tudo o que o usuário escolhe no tour e nas
/// configurações.
class VoiceSettings {
  const VoiceSettings({
    this.enabled = false,
    this.speed = 1,
    this.teacherVoice,
    this.teacherTone = VoiceTone.natural,
    this.charactersMuted = false,
  });

  /// A fala começa sozinha quando o balão troca de texto. Desligada, o
  /// botão de áudio do balão continua lá.
  final bool enabled;

  /// A velocidade geral, que multiplica a de cada personagem.
  final double speed;

  /// A voz do professor. Nula: a primeira do idioma.
  final String? teacherVoice;

  /// O tom da voz do professor (os adversários têm o da idade deles).
  final VoiceTone teacherTone;

  /// Os personagens das partidas calados (o botão de som da partida). O
  /// professor continua falando.
  final bool charactersMuted;

  /// As velocidades oferecidas nas configurações.
  static const speeds = [0.8, 1.0, 1.2, 1.4];

  VoiceSettings copyWith({
    bool? enabled,
    double? speed,
    String? Function()? teacherVoice,
    VoiceTone? teacherTone,
    bool? charactersMuted,
  }) => VoiceSettings(
    enabled: enabled ?? this.enabled,
    speed: speed ?? this.speed,
    teacherVoice: teacherVoice == null ? this.teacherVoice : teacherVoice(),
    teacherTone: teacherTone ?? this.teacherTone,
    charactersMuted: charactersMuted ?? this.charactersMuted,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'speed': speed,
    'teacher': teacherVoice,
    'teacherTone': teacherTone.name,
    'charactersMuted': charactersMuted,
  };

  /// As preferências salvas; o que faltar ou vier estragado fica no padrão.
  static VoiceSettings fromJson(Object? json) {
    if (json is! Map) return const VoiceSettings();
    final speed = json['speed'];
    final teacher = json['teacher'];
    return VoiceSettings(
      enabled: json['enabled'] == true,
      speed: speed is num ? speed.toDouble().clamp(0.5, 2) : 1,
      teacherVoice: teacher is String ? teacher : null,
      teacherTone: VoiceTone.fromName(json['teacherTone']) ?? VoiceTone.natural,
      charactersMuted: json['charactersMuted'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VoiceSettings &&
      other.enabled == enabled &&
      other.speed == speed &&
      other.teacherVoice == teacherVoice &&
      other.teacherTone == teacherTone &&
      other.charactersMuted == charactersMuted;

  @override
  int get hashCode =>
      Object.hash(enabled, speed, teacherVoice, teacherTone, charactersMuted);
}
