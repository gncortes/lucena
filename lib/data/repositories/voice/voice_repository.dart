import '../../../domain/models/voice.dart';
import '../../services/tts_service.dart';

export '../../services/tts_service.dart'
    show TtsEvent, TtsFinished, TtsProgress, TtsStarted;

/// A voz dos personagens: as preferências, as vozes do aparelho, o jeito de
/// falar de cada personagem e a fala em si.
abstract class VoiceRepository {
  /// As preferências salvas.
  Future<VoiceSettings> load();

  Future<void> save(VoiceSettings settings);

  /// As vozes do aparelho que falam sem internet, de todos os idiomas. Com
  /// [refresh], pergunta de novo ao sistema (depois de baixar uma voz).
  Future<List<TtsVoice>> voices({bool refresh = false});

  /// O jeito de falar de cada personagem, pelo id dele.
  Future<Map<String, CharacterVoiceProfile>> profiles();

  /// Fala [text] com [voice], interrompendo a fala anterior.
  Future<void> speak(String text, ResolvedVoice voice);

  Future<void> stop();

  /// O andamento da fala.
  Stream<TtsEvent> get events;

  /// Abre a tela de vozes do aparelho (texto para fala), onde dá para baixar
  /// vozes mais naturais. Falso se não deu para abrir.
  Future<bool> openSystemVoices();
}
