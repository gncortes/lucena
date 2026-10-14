import '../models/voice.dart';

/// Escolhe a voz de cada um: o professor com a voz e o tom que o usuário
/// escolheu, e cada personagem com a que o app acha que combina com ele.
///
/// A escolha dos personagens é determinística: a mesma lista de vozes dá
/// sempre o mesmo resultado, então nada é gravado por personagem.
abstract final class VoiceResolver {
  /// A voz do professor entre [voices] (as do idioma do app): a escolhida
  /// ([chosenId]) ou, sem ela (ou se sumiu do aparelho), a primeira.
  static TtsVoice? teacherVoice(List<TtsVoice> voices, String? chosenId) {
    if (voices.isEmpty) return null;
    return _byId(voices, chosenId) ?? voices.first;
  }

  /// A voz do professor, com o tom [tone] e a velocidade [speed] (a
  /// velocidade geral das configurações). Nula se o aparelho não tem voz no
  /// idioma.
  static ResolvedVoice? resolve({
    required List<TtsVoice> voices,
    required String? teacherVoiceId,
    double speed = 1,
    VoiceTone tone = VoiceTone.natural,
  }) {
    final voice = teacherVoice(voices, teacherVoiceId);
    if (voice == null) return null;
    return ResolvedVoice(
      voice: voice,
      pitch: tone.pitch,
      rate: tone.rate * speed,
    );
  }

  /// A voz de cada personagem de [profiles], pelo id. Eles são atendidos na
  /// ordem do id e cada um fica com a melhor candidata de [voices], pela
  /// ordem das regras:
  ///
  /// 1. gênero: igual ao do personagem, depois desconhecido, depois oposto
  ///    (o gênero vem do sistema ou de [known], a tabela por id da voz);
  /// 2. diferente da do professor;
  /// 3. ainda não usada por outro personagem (espalha as vozes);
  /// 4. qualidade maior;
  /// 5. o id da voz.
  ///
  /// O tom e o ritmo vêm da idade do personagem; o ritmo é multiplicado por
  /// [speed]. Com uma voz só, todos usam ela. Sem voz no idioma, o mapa é
  /// vazio.
  static Map<String, ResolvedVoice> assign({
    required Map<String, CharacterVoiceProfile> profiles,
    required List<TtsVoice> voices,
    required String? teacherVoiceId,
    Map<String, VoiceGender> known = const {},
    double speed = 1,
  }) {
    final teacher = teacherVoice(voices, teacherVoiceId);
    if (teacher == null) return const {};
    final used = <String>{};
    final result = <String, ResolvedVoice>{};
    for (final id in profiles.keys.toList()..sort()) {
      final profile = profiles[id]!;
      final voice = _best(voices, profile.gender, teacher, used, known);
      used.add(voice.id);
      result[id] = ResolvedVoice(
        voice: voice,
        pitch: profile.age.pitch,
        rate: profile.age.rate * speed,
      );
    }
    return result;
  }

  static TtsVoice _best(
    List<TtsVoice> voices,
    VoiceGender wanted,
    TtsVoice teacher,
    Set<String> used,
    Map<String, VoiceGender> known,
  ) {
    int genderRank(TtsVoice v) {
      final gender = v.gender ?? known[v.id];
      if (gender == null) return 1;
      return gender == wanted ? 0 : 2;
    }

    int qualityRank(TtsVoice v) => switch (v.quality) {
      VoiceQuality.veryHigh => 0,
      VoiceQuality.high => 1,
      VoiceQuality.normal || VoiceQuality.unknown => 2,
      VoiceQuality.low => 3,
      VoiceQuality.veryLow => 4,
    };
    int flag(bool value) => value ? 1 : 0;
    final sorted = [...voices]
      ..sort((a, b) {
        final byRule = [
          genderRank(a).compareTo(genderRank(b)),
          flag(a.id == teacher.id).compareTo(flag(b.id == teacher.id)),
          flag(used.contains(a.id)).compareTo(flag(used.contains(b.id))),
          qualityRank(a).compareTo(qualityRank(b)),
          a.id.compareTo(b.id),
        ];
        return byRule.firstWhere((c) => c != 0, orElse: () => 0);
      });
    return sorted.first;
  }

  static TtsVoice? _byId(List<TtsVoice> voices, String? id) {
    if (id == null) return null;
    for (final v in voices) {
      if (v.id == id) return v;
    }
    return null;
  }
}
