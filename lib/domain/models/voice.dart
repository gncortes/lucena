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
  const TtsVoice({required this.id, required this.locale, this.gender});

  /// O nome com que o sistema a identifica (e com que ela é pedida).
  final String id;

  /// O idioma da voz, como o sistema informa (`pt-BR`, `en_US`).
  final String locale;
  final VoiceGender? gender;

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
      other.gender == gender;

  @override
  int get hashCode => Object.hash(id, locale, gender);

  @override
  String toString() => 'TtsVoice($id, $locale)';
}

/// Como um personagem fala: o tom, a velocidade e a "vaga" de voz que ele
/// prefere entre as que sobram depois da do professor (assim dois
/// personagens tendem a cair em vozes diferentes).
class CharacterVoiceProfile {
  const CharacterVoiceProfile({
    required this.characterId,
    this.pitch = 1,
    this.rate = 1,
    this.slot = 0,
  });

  /// O perfil neutro, para um personagem sem perfil no JSON.
  const CharacterVoiceProfile.neutral(this.characterId)
    : pitch = 1,
      rate = 1,
      slot = 0;

  final String characterId;

  /// O tom: 1 é o da voz; abaixo, mais grave; acima, mais agudo.
  final double pitch;

  /// A velocidade: 1 é a normal da voz.
  final double rate;
  final int slot;

  /// O perfil do JSON (`{"pitch": 0.8, "rate": 0.9, "slot": 1}`); campos
  /// ausentes ficam no neutro e valores absurdos são trazidos para a faixa.
  static CharacterVoiceProfile fromJson(
    String characterId,
    Map<String, dynamic> json,
  ) {
    double number(Object? v, double min, double max) =>
        v is num ? v.toDouble().clamp(min, max) : 1;
    final slot = json['slot'];
    return CharacterVoiceProfile(
      characterId: characterId,
      pitch: number(json['pitch'], 0.5, 2),
      rate: number(json['rate'], 0.5, 2),
      slot: slot is num ? slot.toInt().clamp(0, 99) : 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CharacterVoiceProfile &&
      other.characterId == characterId &&
      other.pitch == pitch &&
      other.rate == rate &&
      other.slot == slot;

  @override
  int get hashCode => Object.hash(characterId, pitch, rate, slot);
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
    this.characterVoices = const {},
    this.teacherTone = VoiceTone.natural,
    this.characterTones = const {},
    this.charactersMuted = false,
  });

  /// A fala começa sozinha quando o balão troca de texto. Desligada, o
  /// botão de áudio do balão continua lá.
  final bool enabled;

  /// A velocidade geral, que multiplica a de cada personagem.
  final double speed;

  /// A voz do professor. Nula: a primeira do idioma.
  final String? teacherVoice;

  /// A voz escolhida para cada personagem (pelo id dele).
  final Map<String, String> characterVoices;

  /// O tom da voz do professor.
  final VoiceTone teacherTone;

  /// O tom escolhido para cada personagem. Sem escolha, o do perfil dele.
  final Map<String, VoiceTone> characterTones;

  /// Os personagens das partidas calados (o botão de som da partida). O
  /// professor continua falando.
  final bool charactersMuted;

  /// As velocidades oferecidas nas configurações.
  static const speeds = [0.8, 1.0, 1.2, 1.4];

  VoiceSettings copyWith({
    bool? enabled,
    double? speed,
    String? Function()? teacherVoice,
    Map<String, String>? characterVoices,
    VoiceTone? teacherTone,
    Map<String, VoiceTone>? characterTones,
    bool? charactersMuted,
  }) => VoiceSettings(
    enabled: enabled ?? this.enabled,
    speed: speed ?? this.speed,
    teacherVoice: teacherVoice == null ? this.teacherVoice : teacherVoice(),
    characterVoices: characterVoices ?? this.characterVoices,
    teacherTone: teacherTone ?? this.teacherTone,
    characterTones: characterTones ?? this.characterTones,
    charactersMuted: charactersMuted ?? this.charactersMuted,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'speed': speed,
    'teacher': teacherVoice,
    'characters': characterVoices,
    'teacherTone': teacherTone.name,
    'characterTones': {
      for (final e in characterTones.entries) e.key: e.value.name,
    },
    'charactersMuted': charactersMuted,
  };

  /// As preferências salvas; o que faltar ou vier estragado fica no padrão.
  static VoiceSettings fromJson(Object? json) {
    if (json is! Map) return const VoiceSettings();
    final speed = json['speed'];
    final teacher = json['teacher'];
    final characters = json['characters'];
    final tones = json['characterTones'];
    return VoiceSettings(
      enabled: json['enabled'] == true,
      speed: speed is num ? speed.toDouble().clamp(0.5, 2) : 1,
      teacherVoice: teacher is String ? teacher : null,
      characterVoices: {
        if (characters is Map)
          for (final e in characters.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
      },
      teacherTone: VoiceTone.fromName(json['teacherTone']) ?? VoiceTone.natural,
      characterTones: {
        if (tones is Map)
          for (final e in tones.entries)
            if (e.key is String && VoiceTone.fromName(e.value) != null)
              e.key as String: VoiceTone.fromName(e.value)!,
      },
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
      other.charactersMuted == charactersMuted &&
      _sameMap(other.characterVoices, characterVoices) &&
      _sameMap(other.characterTones, characterTones);

  static bool _sameMap<T>(Map<String, T> a, Map<String, T> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    enabled,
    speed,
    teacherVoice,
    teacherTone,
    charactersMuted,
    Object.hashAllUnordered(
      characterVoices.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      characterTones.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
