import '../../../domain/models/voice.dart';
import '../../services/speech_input_service.dart';

export '../../services/speech_input_service.dart'
    show
        SpeechFailed,
        SpeechHeard,
        SpeechInputEvent,
        SpeechLevel,
        SpeechStopped;

/// Ouvir o jogador: o microfone e o reconhecedor de voz do aparelho.
abstract class SpeechInputRepository {
  /// O microfone já foi liberado?
  Future<bool> hasPermission();

  /// Pede o microfone (e prepara o reconhecedor). Falso se negado ou sem
  /// reconhecedor.
  Future<bool> requestPermission();

  /// Escuta uma fala em [languageTag] (`pt-BR`). Com [onDevice], só no
  /// aparelho.
  Future<void> listen(String languageTag, {required bool onDevice});

  /// Para de escutar: o que foi dito vira o resultado.
  Future<void> stop();

  /// Para e descarta.
  Future<void> cancel();

  Stream<SpeechInputEvent> get events;
}

/// O reconhecedor do sistema.
class DeviceSpeechInputRepository implements SpeechInputRepository {
  DeviceSpeechInputRepository(this._service);

  final SpeechInputService _service;

  @override
  Future<bool> hasPermission() => _service.hasPermission();

  @override
  Future<bool> requestPermission() => _service.initialize();

  /// O idioma com a região: o reconhecedor do Android entende "pt" como um
  /// português qualquer; o do app é o do Brasil ("pt-BR").
  static String localeFor(String languageTag) {
    final parts = languageTag.split(RegExp('[-_]'));
    final language = parts.first.toLowerCase();
    final region = parts.length > 1
        ? parts[1].toUpperCase()
        : TtsVoice.defaultRegions[language];
    return region == null ? language : '${language}_$region';
  }

  @override
  Future<void> listen(String languageTag, {required bool onDevice}) =>
      _service.listen(localeFor(languageTag), onDevice: onDevice);

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> cancel() => _service.cancel();

  @override
  Stream<SpeechInputEvent> get events => _service.events;
}
