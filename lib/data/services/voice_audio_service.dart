import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Por que a voz parou sozinha (foco de áudio): o vídeo pausa e **não volta
/// sozinho** (contrato, Vídeo 14 e 39).
enum VoiceInterruption {
  /// Ligação, outro app tocando som ou o sistema tirou o foco.
  focusLost,

  /// Fone desconectado (o som iria para o alto-falante).
  unplugged,
}

/// Toca a voz gravada de uma fala da aula em vídeo. O relógio do vídeo manda:
/// o view model pede para tocar a fala a partir de um ponto, pausar, buscar e
/// mudar a velocidade; quem implementa só obedece.
abstract interface class VoiceAudioService {
  /// Toca o arquivo [path] a partir de [from] na velocidade [rate]. Falso se
  /// o arquivo falta ou não abre (só essa fala vai em modo leitura, Vídeo 38)
  /// ou se um pedido mais novo passou na frente.
  Future<bool> play(String path, {required Duration from, double rate = 1});

  /// Pausa onde está (o arquivo continua carregado).
  Future<void> pause();

  /// Leva a fala carregada para [position] sem mudar se toca ou não.
  Future<void> seek(Duration position);

  /// Muda a velocidade (0,75 a 2) sem parar.
  Future<void> setSpeed(double rate);

  /// A posição do áudio em curso, para corrigir a deriva; nula sem áudio
  /// tocando.
  Future<Duration?> position();

  /// O sistema parou a voz (foco de áudio); a voz já está pausada.
  Stream<VoiceInterruption> get interruptions;

  /// Solta o tocador (a tela saiu).
  Future<void> dispose();
}

/// A voz pelo `just_audio`, um arquivo por fala, lido do disco. O foco de
/// áudio vem do `audio_session` (configuração de fala): ligação ou outro app
/// pausa, fone desconectado pausa, e nada volta a tocar sozinho.
class JustAudioVoiceAudioService implements VoiceAudioService {
  JustAudioVoiceAudioService({
    required this._player,
    Stream<VoiceInterruption> focus = const Stream.empty(),
  }) {
    _focus = focus.listen((event) async {
      if (!_player.playing) return;
      _request++;
      await _player.pause();
      _interruptions.add(event);
    });
  }

  /// O serviço do aparelho: tocador sem o tratamento automático de
  /// interrupção (ele retomaria sozinho) e o foco de áudio da sessão de fala.
  static Future<JustAudioVoiceAudioService> create() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    final focus = _merge([
      session.interruptionEventStream
          .where((e) => e.begin && e.type != AudioInterruptionType.duck)
          .map((_) => VoiceInterruption.focusLost),
      session.becomingNoisyEventStream.map((_) => VoiceInterruption.unplugged),
    ]);
    return JustAudioVoiceAudioService(
      player: AudioPlayer(handleInterruptions: false),
      focus: focus,
    );
  }

  final AudioPlayer _player;
  late final StreamSubscription<VoiceInterruption> _focus;
  final _interruptions = StreamController<VoiceInterruption>.broadcast();
  String? _path;

  // Cada pedido ganha um número: um pedido antigo que termina de carregar
  // depois de um novo não toca por cima dele.
  int _request = 0;
  bool _loading = false;

  @override
  Stream<VoiceInterruption> get interruptions => _interruptions.stream;

  @override
  Future<bool> play(
    String path, {
    required Duration from,
    double rate = 1,
  }) async {
    final request = ++_request;
    _loading = true;
    try {
      if (_path != path) {
        _path = path;
        await _player.setFilePath(path, initialPosition: from);
      } else {
        await _player.seek(from);
      }
      if (request != _request) return false;
      await _player.setSpeed(rate);
      if (request != _request) return false;
      unawaited(_player.play());
      return true;
    } on Object {
      // Arquivo faltando ou ilegível: o vídeo segue no relógio, sem voz.
      _path = null;
      return false;
    } finally {
      if (request == _request) _loading = false;
    }
  }

  @override
  Future<void> pause() async {
    _request++;
    _loading = false;
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_path == null) return;
    await _player.seek(position);
  }

  @override
  Future<void> setSpeed(double rate) => _player.setSpeed(rate);

  @override
  Future<Duration?> position() async {
    if (_loading ||
        !_player.playing ||
        _player.processingState != ProcessingState.ready) {
      return null;
    }
    return _player.position;
  }

  @override
  Future<void> dispose() async {
    _request++;
    await _focus.cancel();
    await _interruptions.close();
    await _player.dispose();
  }
}

/// Junta streams sem depender do pacote `async` (fora das dependências).
Stream<T> _merge<T>(List<Stream<T>> streams) {
  final subscriptions = <StreamSubscription<T>>[];
  late final StreamController<T> controller;
  controller = StreamController<T>.broadcast(
    onListen: () {
      for (final stream in streams) {
        subscriptions.add(stream.listen(controller.add));
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      subscriptions.clear();
    },
  );
  return controller.stream;
}
