import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucena/data/services/voice_audio_service.dart';

/// O tocador do `just_audio` sem plataforma: guarda os pedidos e deixa o
/// teste segurar o carregamento.
class _FakePlayer extends Fake implements AudioPlayer {
  final calls = <String>[];
  final broken = <String>{};
  Completer<void>? loading;
  bool _playing = false;
  Duration _position = Duration.zero;
  double lastSpeed = 1;

  @override
  bool get playing => _playing;

  @override
  ProcessingState get processingState => ProcessingState.ready;

  @override
  Duration get position => _position;

  @override
  Future<Duration?> setFilePath(
    String filePath, {
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    calls.add('load $filePath ${initialPosition?.inMilliseconds}');
    await loading?.future;
    if (broken.contains(filePath)) throw PlayerException(0, 'ilegível', null);
    _position = initialPosition ?? Duration.zero;
    return const Duration(seconds: 5);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    calls.add('seek ${position?.inMilliseconds}');
    _position = position ?? Duration.zero;
  }

  @override
  Future<void> setSpeed(double speed) async {
    calls.add('speed $speed');
    lastSpeed = speed;
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _playing = true;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _playing = false;
  }

  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  late _FakePlayer player;
  late StreamController<VoiceInterruption> focus;
  late JustAudioVoiceAudioService service;

  setUp(() {
    player = _FakePlayer();
    focus = StreamController<VoiceInterruption>();
    service = JustAudioVoiceAudioService(player: player, focus: focus.stream);
  });

  tearDown(() => focus.close());

  test('toca a fala pelo arquivo a partir do ponto e na velocidade', () async {
    final ok = await service.play(
      '/voz/a.opus',
      from: const Duration(milliseconds: 1200),
      rate: 1.5,
    );
    expect(ok, isTrue);
    expect(player.calls, ['load /voz/a.opus 1200', 'speed 1.5', 'play']);
    expect(await service.position(), const Duration(milliseconds: 1200));
  });

  test('a mesma fala de novo só busca, sem recarregar o arquivo', () async {
    await service.play('/voz/a.opus', from: Duration.zero);
    player.calls.clear();
    await service.play('/voz/a.opus', from: const Duration(seconds: 2));
    expect(player.calls, ['seek 2000', 'speed 1.0', 'play']);
  });

  test('Vídeo 38: fala com áudio ilegível devolve falso e não toca', () async {
    player.broken.add('/voz/ruim.opus');
    expect(await service.play('/voz/ruim.opus', from: Duration.zero), isFalse);
    expect(player.calls, isNot(contains('play')));
    expect(await service.position(), isNull);
  });

  test('pedido antigo que termina de carregar depois não toca', () async {
    player.loading = Completer<void>();
    final old = service.play('/voz/a.opus', from: Duration.zero);
    await service.pause();
    player.loading!.complete();
    expect(await old, isFalse);
    expect(player.calls, isNot(contains('play')));
  });

  test('pausa, busca e velocidade obedecem sem trocar o arquivo', () async {
    await service.play('/voz/a.opus', from: Duration.zero);
    await service.pause();
    expect(await service.position(), isNull);
    await service.seek(const Duration(seconds: 3));
    await service.setSpeed(2);
    expect(player.calls.skip(3), ['pause', 'seek 3000', 'speed 2.0']);
  });

  test('busca sem fala carregada não faz nada', () async {
    await service.seek(const Duration(seconds: 3));
    expect(player.calls, isEmpty);
  });

  test('Vídeo 39: ligação pausa, avisa e não volta sozinho', () async {
    final events = <VoiceInterruption>[];
    service.interruptions.listen(events.add);
    await service.play('/voz/a.opus', from: Duration.zero);
    focus.add(VoiceInterruption.focusLost);
    await pumpEventQueue();
    expect(player.playing, isFalse);
    expect(events, [VoiceInterruption.focusLost]);
    expect(player.calls.where((c) => c == 'play'), hasLength(1));
  });

  test('Vídeo 39: fone desconectado pausa e avisa', () async {
    final events = <VoiceInterruption>[];
    service.interruptions.listen(events.add);
    await service.play('/voz/a.opus', from: Duration.zero);
    focus.add(VoiceInterruption.unplugged);
    await pumpEventQueue();
    expect(player.playing, isFalse);
    expect(events, [VoiceInterruption.unplugged]);
  });

  test('perda de foco com a voz parada não avisa', () async {
    final events = <VoiceInterruption>[];
    service.interruptions.listen(events.add);
    focus.add(VoiceInterruption.focusLost);
    await pumpEventQueue();
    expect(events, isEmpty);
  });

  test('dispose solta o tocador', () async {
    await service.dispose();
    expect(player.calls.last, 'dispose');
  });
}
