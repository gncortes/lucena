import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/voice/voice_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/voice.dart';
import '../../../domain/use_cases/spoken_text.dart';
import '../../../domain/use_cases/voice_resolver.dart';
import '../../../domain/use_cases/wiki_markup.dart';

class SpeechState {
  const SpeechState({
    this.loaded = false,
    this.settings = const VoiceSettings(),
    this.voices = const [],
    this.profiles = const {},
    this.characters = const [],
    this.speaking,
    this.speakerId,
    this.revealed,
  });

  final bool loaded;
  final VoiceSettings settings;

  /// As vozes do aparelho, de todos os idiomas.
  final List<TtsVoice> voices;
  final Map<String, CharacterVoiceProfile> profiles;

  /// Os adversários que falam (sem o professor nem o Stockfish), do nível
  /// mais baixo ao mais alto.
  final List<Character> characters;

  /// O texto (o da tela) que está sendo falado agora. Nulo: em silêncio.
  final String? speaking;

  /// Quem está falando.
  final String? speakerId;

  /// Até onde a voz chegou, em posição do texto da tela. Nulo: o
  /// sintetizador não conta o andamento (ou ainda não contou).
  final int? revealed;

  /// As vozes que falam [language] (`pt-BR`, `en`).
  List<TtsVoice> voicesFor(String language) =>
      TtsVoice.forLanguage(voices, language);

  /// Há voz no idioma: sem ela, o botão de áudio e os passos do tour somem.
  bool availableFor(String language) => voicesFor(language).isNotEmpty;

  /// Os personagens falam sozinhos nas partidas (o botão de som da
  /// partida).
  bool get charactersHeard => settings.enabled && !settings.charactersMuted;

  /// Fala [text] agora?
  /// Uma fala com nomes marcados (`{{Andersson|ulf-andersson}}`) vale pelo
  /// texto visível.
  bool isSpeaking(String? text) =>
      text != null && speaking == WikiMarkup.plain(text);

  /// A voz com que [characterId] fala em [language].
  ResolvedVoice? voiceOf(String characterId, String language) =>
      VoiceResolver.resolve(
        profile:
            profiles[characterId] ?? CharacterVoiceProfile.neutral(characterId),
        voices: voicesFor(language),
        teacherVoiceId: settings.teacherVoice,
        chosenVoiceId: settings.characterVoices[characterId],
        teacher: characterId == SpeechCubit.teacherId,
        speed: settings.speed,
        tone: toneOf(characterId),
      );

  /// O tom escolhido para [characterId] (o do professor sempre há).
  VoiceTone? toneOf(String characterId) => characterId == SpeechCubit.teacherId
      ? settings.teacherTone
      : settings.characterTones[characterId];

  SpeechState copyWith({
    bool? loaded,
    VoiceSettings? settings,
    List<TtsVoice>? voices,
    Map<String, CharacterVoiceProfile>? profiles,
    List<Character>? characters,
    String? Function()? speaking,
    String? Function()? speakerId,
    int? Function()? revealed,
  }) => SpeechState(
    loaded: loaded ?? this.loaded,
    settings: settings ?? this.settings,
    voices: voices ?? this.voices,
    profiles: profiles ?? this.profiles,
    characters: characters ?? this.characters,
    speaking: speaking == null ? this.speaking : speaking(),
    speakerId: speakerId == null ? this.speakerId : speakerId(),
    revealed: revealed == null ? this.revealed : revealed(),
  );
}

/// A voz do app: as preferências (o tour e as configurações mexem aqui) e a
/// fala do momento, uma de cada vez. Os balões pedem para falar e
/// acompanham até onde a voz chegou.
class SpeechCubit extends Cubit<SpeechState> {
  SpeechCubit(this._voice, {this._characters}) : super(const SpeechState()) {
    _events = _voice.events.listen(_onEvent);
  }

  /// O professor (o Viktor): fala com a voz escolhida para ele.
  static const teacherId = 'master';

  final VoiceRepository _voice;
  final CharacterRepository? _characters;
  late final StreamSubscription<TtsEvent> _events;
  SpokenUtterance? _utterance;

  // O idioma da fala do momento, para recomeçá-la noutra velocidade.
  String? _language;

  Future<void> load() async {
    final settings = await _voice.load();
    final voices = await _voice.voices();
    final profiles = await _voice.profiles();
    final characters = [
      for (final c in await _characters?.characters() ?? const <Character>[])
        if (c.id != teacherId && c.id != Character.stockfish.id) c,
    ]..sort((a, b) => a.level.compareTo(b.level));
    if (isClosed) return;
    emit(
      state.copyWith(
        loaded: true,
        settings: settings,
        voices: voices,
        profiles: profiles,
        characters: characters,
      ),
    );
  }

  /// Fala [text] na voz de [speakerId], em [language], interrompendo a fala
  /// anterior. Sem voz no idioma, nada. A marcação dos nomes
  /// (`{{Andersson|ulf-andersson}}`) sai: a voz lê só o texto visível.
  Future<void> say(
    String marked, {
    required String speakerId,
    required String language,
  }) async {
    final text = WikiMarkup.plain(marked);
    final voice = state.voiceOf(speakerId, language);
    if (voice == null) return;
    final utterance = _utterance = SpokenText.utterance(text, language);
    _language = language;
    emit(
      state.copyWith(
        speaking: () => text,
        speakerId: () => speakerId,
        revealed: () => null,
      ),
    );
    await _voice.speak(utterance.text, voice);
  }

  /// O botão de áudio: fala [text] ou, se já está falando, para.
  Future<void> toggle(
    String text, {
    required String speakerId,
    required String language,
  }) => state.isSpeaking(text)
      ? stop()
      : say(text, speakerId: speakerId, language: language);

  /// Fala [text] sozinho, se a voz está ligada.
  Future<void> sayIfEnabled(
    String text, {
    required String speakerId,
    required String language,
  }) async {
    if (!state.settings.enabled) return;
    await say(text, speakerId: speakerId, language: language);
  }

  /// Para de falar.
  Future<void> stop() async {
    if (state.speaking == null) return;
    _utterance = null;
    emit(
      state.copyWith(
        speaking: () => null,
        speakerId: () => null,
        revealed: () => null,
      ),
    );
    await _voice.stop();
  }

  /// Para só se a fala é [text] (o balão que saiu da tela).
  Future<void> stopIf(String? text) async {
    if (state.isSpeaking(text)) await stop();
  }

  /// Uma amostra: [characterId] fala [text] com a voz [voiceId], do jeito
  /// que ela vai soar se for escolhida, sem gravar a escolha.
  Future<void> preview(
    String text, {
    required String characterId,
    required String voiceId,
    required String language,
    VoiceTone? tone,
  }) async {
    final voices = state.voicesFor(language);
    final voice = voices.where((v) => v.id == voiceId).firstOrNull;
    if (voice == null) return;
    _utterance = SpokenText.utterance(text, language);
    emit(
      state.copyWith(
        speaking: () => text,
        speakerId: () => characterId,
        revealed: () => null,
      ),
    );
    await _voice.speak(
      _utterance!.text,
      // Como a voz vai soar se for escolhida: no tom escolhido (natural, sem
      // tom).
      ResolvedVoice(
        voice: voice,
        pitch: (tone ?? state.toneOf(characterId) ?? VoiceTone.natural).pitch,
        rate:
            (tone ?? state.toneOf(characterId) ?? VoiceTone.natural).rate *
            state.settings.speed,
      ),
    );
  }

  /// Abre a tela de vozes do aparelho, para baixar vozes mais naturais. A
  /// volta ao app relê as vozes (pode ter chegado uma nova).
  Future<void> openSystemVoices() async {
    await _voice.stop();
    await _voice.openSystemVoices();
  }

  /// Relê as vozes do aparelho (ao voltar das configurações dele).
  Future<void> reloadVoices() async {
    final voices = await _voice.voices(refresh: true);
    if (isClosed) return;
    emit(state.copyWith(voices: voices));
  }

  /// O botão de som da partida: cala os personagens (para a fala na hora)
  /// ou volta a ouvi-los, ligando a voz se estava desligada. Fica gravado.
  Future<void> setCharactersHeard({required bool heard}) async {
    if (!heard) await stop();
    await _save(
      heard
          ? state.settings.copyWith(enabled: true, charactersMuted: false)
          : state.settings.copyWith(charactersMuted: true),
    );
  }

  Future<void> setEnabled({required bool enabled}) async {
    if (!enabled) await stop();
    await _save(state.settings.copyWith(enabled: enabled));
  }

  /// A velocidade geral. Falando, a fala recomeça já nela.
  Future<void> setSpeed(double speed) async {
    await _save(state.settings.copyWith(speed: speed));
    final text = state.speaking;
    final speaker = state.speakerId;
    final language = _language;
    if (text != null && speaker != null && language != null) {
      await say(text, speakerId: speaker, language: language);
    }
  }

  /// O botão de velocidade do balão: passa para a próxima da lista (depois
  /// da última, volta à primeira).
  Future<void> nextSpeed() {
    const speeds = VoiceSettings.speeds;
    final index = speeds.indexOf(state.settings.speed);
    return setSpeed(speeds[(index + 1) % speeds.length]);
  }

  /// A voz do professor; escolher uma liga a voz.
  Future<void> setTeacherVoice(String voiceId) => _save(
    state.settings.copyWith(enabled: true, teacherVoice: () => voiceId),
  );

  /// O tom de [characterId] (o professor ou um personagem). Nulo: o do
  /// perfil do personagem. Fala uma amostra no tom novo.
  Future<void> setTone(
    String characterId,
    VoiceTone? tone, {
    required String sample,
    required String language,
  }) async {
    if (characterId == SpeechCubit.teacherId) {
      await _save(
        state.settings.copyWith(teacherTone: tone ?? VoiceTone.natural),
      );
    } else {
      final tones = {...state.settings.characterTones};
      if (tone == null) {
        tones.remove(characterId);
      } else {
        tones[characterId] = tone;
      }
      await _save(state.settings.copyWith(characterTones: tones));
    }
    final voice = state.voiceOf(characterId, language);
    if (voice != null) {
      await preview(
        sample,
        characterId: characterId,
        voiceId: voice.voice.id,
        language: language,
      );
    }
  }

  /// A voz de um personagem. Nula: volta à escolhida pelo app.
  Future<void> setCharacterVoice(String characterId, String? voiceId) {
    final voices = {...state.settings.characterVoices};
    if (voiceId == null) {
      voices.remove(characterId);
    } else {
      voices[characterId] = voiceId;
    }
    return _save(state.settings.copyWith(characterVoices: voices));
  }

  Future<void> _save(VoiceSettings settings) async {
    emit(state.copyWith(settings: settings));
    await _voice.save(settings);
  }

  void _onEvent(TtsEvent event) {
    if (isClosed || state.speaking == null) return;
    switch (event) {
      case TtsStarted():
        break;
      case TtsProgress(:final end):
        final utterance = _utterance;
        if (utterance == null) return;
        emit(state.copyWith(revealed: () => utterance.displayOffset(end)));
      case TtsFinished():
        _utterance = null;
        emit(
          state.copyWith(
            speaking: () => null,
            speakerId: () => null,
            revealed: () => null,
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    await _events.cancel();
    await _voice.stop();
    return super.close();
  }
}
