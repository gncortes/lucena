import 'dart:async';

import 'package:lucena/data/services/voice_audio_service.dart';

/// A voz sem som para view models e cenários: guarda os pedidos, anda a
/// posição só quando o teste manda e simula ligação/fone desconectado.
class FakeVoiceAudioService implements VoiceAudioService {
  /// Os arquivos que "abrem"; os outros falham (fala em modo leitura).
  Set<String>? playable;

  final plays = <({String path, Duration from, double rate})>[];
  final seeks = <Duration>[];
  final speeds = <double>[];
  var pauses = 0;
  var disposed = false;
  bool playing = false;
  Duration? current;
  final _interruptions = StreamController<VoiceInterruption>.broadcast();

  @override
  Future<bool> play(
    String path, {
    required Duration from,
    double rate = 1,
  }) async {
    plays.add((path: path, from: from, rate: rate));
    if (playable != null && !playable!.contains(path)) return false;
    playing = true;
    current = from;
    return true;
  }

  @override
  Future<void> pause() async {
    pauses++;
    playing = false;
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    current = position;
  }

  @override
  Future<void> setSpeed(double rate) async => speeds.add(rate);

  @override
  Future<Duration?> position() async => playing ? current : null;

  @override
  Stream<VoiceInterruption> get interruptions => _interruptions.stream;

  /// O sistema tira o foco: pausa e avisa, como o serviço real.
  void interrupt(VoiceInterruption reason) {
    if (!playing) return;
    playing = false;
    _interruptions.add(reason);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    playing = false;
    await _interruptions.close();
  }
}
