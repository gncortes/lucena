import 'dart:async';

import 'package:lucena/data/repositories/voice/voice_repository.dart';
import 'package:lucena/domain/models/voice.dart';

/// Não fala nada: guarda as falas pedidas e conta o andamento quando o teste
/// manda ([emit]).
class FakeVoiceRepository implements VoiceRepository {
  FakeVoiceRepository({
    this.settings = const VoiceSettings(),
    List<TtsVoice>? voices,
    Map<String, CharacterVoiceProfile>? profiles,
  }) : _voices = voices ?? sampleVoices,
       _profiles = profiles ?? sampleProfiles;

  VoiceSettings settings;
  final List<TtsVoice> _voices;
  final Map<String, CharacterVoiceProfile> _profiles;
  final _events = StreamController<TtsEvent>.broadcast();

  /// As falas pedidas, na ordem.
  final spoken = <(String, ResolvedVoice)>[];
  var stops = 0;

  static const sampleVoices = [
    TtsVoice(id: 'en-us-a', locale: 'en-US'),
    TtsVoice(id: 'en-us-b', locale: 'en-US'),
    TtsVoice(id: 'pt-br-a', locale: 'pt-BR'),
    TtsVoice(id: 'pt-br-b', locale: 'pt-BR'),
    TtsVoice(id: 'pt-br-c', locale: 'pt-BR'),
  ];

  static const sampleProfiles = {
    'master': CharacterVoiceProfile(characterId: 'master', pitch: 0.9),
    'grandpa': CharacterVoiceProfile(
      characterId: 'grandpa',
      pitch: 0.8,
      rate: 0.85,
    ),
  };

  /// Conta [event] a quem ouve, como o sintetizador.
  void emit(TtsEvent event) => _events.add(event);

  @override
  Future<VoiceSettings> load() async => settings;

  @override
  Future<void> save(VoiceSettings settings) async => this.settings = settings;

  @override
  Future<List<TtsVoice>> voices({bool refresh = false}) async => _voices;

  @override
  Future<Map<String, CharacterVoiceProfile>> profiles() async => _profiles;

  /// Termina cada fala logo depois de começar, como um sintetizador rápido.
  bool autoFinish = false;

  @override
  Future<void> speak(String text, ResolvedVoice voice) async {
    spoken.add((text, voice));
    if (autoFinish) scheduleMicrotask(() => _events.add(const TtsFinished()));
  }

  @override
  Future<void> stop() async {
    stops++;
    _events.add(const TtsFinished());
  }

  @override
  Stream<TtsEvent> get events => _events.stream;

  /// Quantas vezes a tela de vozes do aparelho foi aberta.
  var systemOpened = 0;

  @override
  Future<bool> openSystemVoices() async {
    systemOpened++;
    return true;
  }
}
