import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// O que o reconhecedor conta enquanto escuta.
sealed class SpeechInputEvent {
  const SpeechInputEvent();
}

/// O que ele entendeu até agora: as alternativas, da mais provável para a
/// menos. [isFinal]: acabou de escutar esta fala.
class SpeechHeard extends SpeechInputEvent {
  const SpeechHeard(this.alternatives, {required this.isFinal});

  final List<String> alternatives;
  final bool isFinal;

  @override
  String toString() => 'ouviu${isFinal ? ' (final)' : ''}: $alternatives';
}

/// Não deu: [offlineMissing] quando o idioma não tem reconhecimento sem
/// internet no aparelho.
class SpeechFailed extends SpeechInputEvent {
  const SpeechFailed(this.error, {this.offlineMissing = false});

  final String error;
  final bool offlineMissing;

  @override
  String toString() => 'falhou: $error';
}

/// O volume da voz agora (em dB, como o Android conta: de uns -2 a 10).
class SpeechLevel extends SpeechInputEvent {
  const SpeechLevel(this.level);

  final double level;
}

/// Terminou de escutar: o resultado final (se houve) já chegou.
class SpeechStopped extends SpeechInputEvent {
  const SpeechStopped();

  @override
  String toString() => 'terminou';
}

/// Embrulha o reconhecimento de voz do sistema (`speech_to_text`): o único
/// lugar que conhece o pacote. Um erro nunca chega como exceção: vira
/// [SpeechFailed].
class SpeechInputService {
  SpeechInputService([SpeechToText? speech]) : _given = speech;

  final SpeechToText? _given;
  late final SpeechToText _speech = _given ?? SpeechToText();
  final _events = StreamController<SpeechInputEvent>.broadcast();
  bool _ready = false;

  /// O que acontece enquanto escuta.
  Stream<SpeechInputEvent> get events => _events.stream;

  /// O microfone já foi liberado?
  Future<bool> hasPermission() async {
    try {
      return await _speech.hasPermission;
    } on Object catch (error) {
      debugPrint('SpeechInputService.hasPermission: $error');
      return false;
    }
  }

  /// Prepara o reconhecedor; no Android, pede o microfone se preciso. Falso
  /// se não há reconhecedor ou o microfone foi negado.
  Future<bool> initialize() async {
    if (_ready) return true;
    try {
      return _ready = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        // No modo debug, o plugin conta tudo no log.
        debugLogging: kDebugMode,
      );
    } on Object catch (error) {
      debugPrint('SpeechInputService.initialize: $error');
      return false;
    }
  }

  /// Escuta uma fala em [localeId] (`pt_BR`). Com [onDevice], só no aparelho
  /// (sem internet).
  Future<void> listen(String localeId, {required bool onDevice}) async {
    debugPrint('[voz] escutar $localeId (só no aparelho: $onDevice)');
    if (!await initialize()) {
      _events.add(const SpeechFailed('not_available'));
      return;
    }
    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: (level) => _events.add(SpeechLevel(level)),
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          onDevice: onDevice,
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } on Object catch (error) {
      debugPrint('SpeechInputService.listen: $error');
      _events.add(SpeechFailed('$error'));
    }
  }

  /// Para de escutar: o que já foi dito vira o resultado final.
  Future<void> stop() async {
    try {
      await _speech.stop();
    } on Object catch (error) {
      debugPrint('SpeechInputService.stop: $error');
    }
  }

  /// Para de escutar e descarta o que foi dito.
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } on Object catch (error) {
      debugPrint('SpeechInputService.cancel: $error');
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    debugPrint(
      '[voz] resultado ${result.finalResult ? 'final' : 'parcial'}: '
      '${[for (final a in result.alternates) a.recognizedWords]}',
    );
    final alternatives = [
      for (final words in result.alternates)
        if (words.recognizedWords.trim().isNotEmpty) words.recognizedWords,
    ];
    _events.add(SpeechHeard(alternatives, isFinal: result.finalResult));
  }

  void _onError(SpeechRecognitionError error) {
    final message = error.errorMsg;
    debugPrint('[voz] erro: $message (permanente: ${error.permanent})');
    _events.add(
      SpeechFailed(message, offlineMissing: _offlineErrors.contains(message)),
    );
  }

  // Só o "done" encerra: o "notListening" chega no instante em que o
  // microfone fecha, antes do resultado final (que vem uns 100 ms depois).
  void _onStatus(String status) {
    debugPrint('[voz] status: $status');
    if (status == SpeechToText.doneStatus) _events.add(const SpeechStopped());
  }

  /// Os erros do Android quando falta o pacote de idioma no aparelho.
  static const _offlineErrors = {
    'error_language_unavailable',
    'error_language_not_supported',
    'error_network',
    'error_network_timeout',
    'error_server',
    'error_server_disconnected',
  };
}
