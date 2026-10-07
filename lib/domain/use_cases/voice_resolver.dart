import '../models/voice.dart';

/// Escolhe a voz de cada um: o professor com a voz que o usuário escolheu, e
/// cada personagem com a dele (ou, sem escolha, uma diferente da do
/// professor).
///
/// A voz escolhida pelo usuário (a do professor sempre é) sai como ele a
/// ouviu, com o tom que ele deu ([VoiceTone]; natural, sem tom). O perfil do
/// personagem só vale na voz que o app escolheu para ele, sem tom escolhido,
/// para ele não soar igual a outro que caiu na mesma voz.
abstract final class VoiceResolver {
  /// A voz do professor entre [voices] (as do idioma do app): a escolhida
  /// ([chosenId]) ou, sem ela (ou se sumiu do aparelho), a primeira.
  static TtsVoice? teacherVoice(List<TtsVoice> voices, String? chosenId) {
    if (voices.isEmpty) return null;
    return _byId(voices, chosenId) ?? voices.first;
  }

  /// A voz de quem tem o perfil [profile]. [teacher] diz se é o professor.
  /// [speed] multiplica a velocidade (a velocidade geral das
  /// configurações). Nula se o aparelho não tem voz no idioma.
  static ResolvedVoice? resolve({
    required CharacterVoiceProfile profile,
    required List<TtsVoice> voices,
    required String? teacherVoiceId,
    String? chosenVoiceId,
    bool teacher = false,
    double speed = 1,
    VoiceTone? tone,
  }) {
    final teacherVoice = VoiceResolver.teacherVoice(voices, teacherVoiceId);
    if (teacherVoice == null) return null;
    final chosen = teacher ? teacherVoice : _byId(voices, chosenVoiceId);
    final voice = chosen ?? _other(voices, teacherVoice, profile.slot);
    if (chosen != null || tone != null) {
      final t = tone ?? VoiceTone.natural;
      return ResolvedVoice(voice: voice, pitch: t.pitch, rate: t.rate * speed);
    }
    return ResolvedVoice(
      voice: voice,
      pitch: profile.pitch,
      rate: profile.rate * speed,
    );
  }

  /// Uma voz que não é a do professor, pela vaga do perfil; sem outra, a do
  /// professor (o tom e a velocidade ainda distinguem quem fala).
  static TtsVoice _other(List<TtsVoice> voices, TtsVoice teacher, int slot) {
    final others = [
      for (final v in voices)
        if (v.id != teacher.id) v,
    ];
    if (others.isEmpty) return teacher;
    return others[slot % others.length];
  }

  static TtsVoice? _byId(List<TtsVoice> voices, String? id) {
    if (id == null) return null;
    for (final v in voices) {
      if (v.id == id) return v;
    }
    return null;
  }
}
