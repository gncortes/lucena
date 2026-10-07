import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/models/voice.dart';

/// O que o sintetizador conta enquanto fala.
sealed class TtsEvent {
  const TtsEvent();
}

/// Começou a falar.
class TtsStarted extends TtsEvent {
  const TtsStarted();
}

/// Está falando o trecho de [start] a [end] (posições no texto mandado).
class TtsProgress extends TtsEvent {
  const TtsProgress(this.start, this.end);

  final int start;
  final int end;
}

/// Terminou, foi interrompido ou deu erro: não está mais falando.
class TtsFinished extends TtsEvent {
  const TtsFinished();
}

/// Embrulha o sintetizador de voz do aparelho (`flutter_tts`): o único lugar
/// que conhece o pacote. Um erro de voz nunca chega a quem pediu: sem voz, o
/// app segue em silêncio.
class TtsService {
  TtsService([FlutterTts? tts]) : _given = tts;

  // Criado no primeiro uso: montar o app não depende da plataforma.
  final FlutterTts? _given;
  late final FlutterTts _tts = _given ?? FlutterTts();
  final _events = StreamController<TtsEvent>.broadcast();
  bool _ready = false;

  // Pediu uma fala e ela ainda não começou: o "cancelado" que chega agora é
  // o da fala anterior, interrompida, e não conta.
  bool _awaitingStart = false;

  /// A velocidade normal para o flutter_tts.
  static const normalRate = 0.5;

  /// Os eventos da fala atual.
  Stream<TtsEvent> get events => _events.stream;

  /// Conta [event] como se viesse do sintetizador (o falso dos cenários).
  @visibleForTesting
  void addEvent(TtsEvent event) => _events.add(event);

  void _setUp() {
    if (_ready) return;
    _ready = true;
    void finished() {
      if (!_awaitingStart) _events.add(const TtsFinished());
    }

    _tts
      ..setStartHandler(() {
        _awaitingStart = false;
        _events.add(const TtsStarted());
      })
      ..setProgressHandler((text, start, end, word) {
        if (!_awaitingStart) _events.add(TtsProgress(start, end));
      })
      ..setCompletionHandler(finished)
      ..setCancelHandler(finished)
      ..setErrorHandler((_) => finished());
  }

  // O mecanismo de voz em uso (Android): o preferido do aparelho.
  String? _engine;

  /// As vozes instaladas que falam sem internet. Com [refresh] (a volta das
  /// configurações do aparelho), passa antes para o mecanismo preferido, se
  /// ele mudou (de Samsung para Google, por exemplo).
  Future<List<TtsVoice>> voices({bool refresh = false}) async {
    await _followDefaultEngine(switchEngine: refresh);
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map) ?_voice(item),
      ];
    } on Object catch (error) {
      debugPrint('TtsService.voices: $error');
      return const [];
    }
  }

  Future<void> _followDefaultEngine({required bool switchEngine}) async {
    try {
      final engine = await _tts.getDefaultEngine;
      if (engine is! String || engine == _engine) return;
      if (switchEngine && _engine != null) await _tts.setEngine(engine);
      _engine = engine;
    } on Object catch (error) {
      // Fora do Android não há mecanismo para escolher.
      debugPrint('TtsService.engine: $error');
    }
  }

  static TtsVoice? _voice(Map<Object?, Object?> map) {
    final name = map['name'];
    final locale = map['locale'];
    if (name is! String || locale is! String) return null;
    // Android: vozes que precisam de rede ou não foram baixadas ficam de fora.
    if (map['network_required'] == '1') return null;
    final features = map['features'];
    if (features is String && features.contains('notInstalled')) return null;
    final gender = map['gender'];
    return TtsVoice(
      id: name,
      locale: locale,
      gender: VoiceGender.fromCode(gender is String ? gender : null),
    );
  }

  /// Fala [text] com [voice], interrompendo a fala anterior. Não pede o foco
  /// do áudio: os sons do jogo continuam no mesmo volume.
  Future<void> speak(String text, ResolvedVoice voice) async {
    _setUp();
    _awaitingStart = true;
    try {
      await _tts.stop();
      await _tts.setVoice({
        'name': voice.voice.id,
        'locale': voice.voice.locale,
      });
      await _tts.setPitch(voice.pitch);
      // No flutter_tts a velocidade normal é 0,5 em todas as plataformas (no
      // Android ele dobra o valor antes de passar ao sistema).
      await _tts.setSpeechRate(voice.rate * normalRate);
      await _tts.speak(text);
    } on Object catch (error) {
      debugPrint('TtsService.speak: $error');
      _awaitingStart = false;
      _events.add(const TtsFinished());
    }
  }

  /// Para de falar. O fim chega pelo sintetizador (o "cancelado"); quem
  /// pediu para parar já sabe que parou.
  Future<void> stop() async {
    _awaitingStart = false;
    try {
      await _tts.stop();
    } on Object catch (error) {
      debugPrint('TtsService.stop: $error');
    }
  }
}
