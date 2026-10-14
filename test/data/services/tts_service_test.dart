import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucena/data/services/tts_service.dart';
import 'package:lucena/domain/models/voice.dart';

/// O sintetizador sem aparelho: guarda as chamadas e devolve vozes prontas.
class _FakeFlutterTts implements FlutterTts {
  _FakeFlutterTts(this.rawVoices);

  final Object? rawVoices;
  final calls = <String>[];
  Completer<void>? voiceGate;
  final voiceEntered = Completer<void>();
  @override
  VoidCallback? startHandler;
  @override
  VoidCallback? completionHandler;
  @override
  VoidCallback? cancelHandler;
  @override
  ProgressHandler? progressHandler;
  @override
  ErrorHandler? errorHandler;

  @override
  Future<dynamic> get getVoices async => rawVoices;

  /// O mecanismo preferido do aparelho.
  String engine = 'com.samsung.SMT';

  @override
  Future<dynamic> get getDefaultEngine async => engine;

  @override
  Future<dynamic> setEngine(String engine) async => calls.add('engine $engine');

  @override
  void setStartHandler(VoidCallback callback) => startHandler = callback;
  @override
  void setCompletionHandler(VoidCallback callback) =>
      completionHandler = callback;
  @override
  void setCancelHandler(VoidCallback callback) => cancelHandler = callback;
  @override
  void setProgressHandler(ProgressHandler callback) =>
      progressHandler = callback;
  @override
  void setErrorHandler(ErrorHandler handler) => errorHandler = handler;

  @override
  Future<dynamic> stop() async => calls.add('stop');
  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    if (!voiceEntered.isCompleted) voiceEntered.complete();
    await voiceGate?.future;
    calls.add('voice ${voice['name']} ${voice['locale']}');
  }

  @override
  Future<dynamic> setPitch(double pitch) async => calls.add('pitch $pitch');
  @override
  Future<dynamic> setSpeechRate(double rate) async => calls.add('rate $rate');
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async =>
      calls.add('speak $text focus=$focus');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('T65: stop cancela speak aguardando configuração da voz', () async {
    final fake = _FakeFlutterTts(const []);
    final gate = fake.voiceGate = Completer<void>();
    final tts = TtsService(fake);
    const voice = ResolvedVoice(
      voice: TtsVoice(id: 'a', locale: 'en'),
      pitch: 1,
      rate: 1,
    );
    final pending = tts.speak('Antiga', voice);
    await fake.voiceEntered.future;
    await tts.stop();
    gate.complete();
    await pending;
    expect(fake.calls.where((call) => call.startsWith('speak')), isEmpty);
    await tts.speak('Retomada', voice);
    expect(fake.calls.last, 'speak Retomada focus=false');
  });

  test('as vozes: só as que falam sem internet e estão instaladas', () async {
    final tts = TtsService(
      _FakeFlutterTts([
        {'name': 'pt-br-x-a', 'locale': 'pt-BR', 'network_required': '0'},
        {'name': 'pt-br-x-net', 'locale': 'pt-BR', 'network_required': '1'},
        {
          'name': 'pt-br-x-b',
          'locale': 'pt-BR',
          'network_required': '0',
          'features': 'notInstalled',
        },
        {'name': 'Luciana', 'locale': 'pt-BR', 'gender': 'female'},
        {'locale': 'pt-BR'},
      ]),
    );
    expect(await tts.voices(), const [
      TtsVoice(id: 'pt-br-x-a', locale: 'pt-BR'),
      TtsVoice(id: 'Luciana', locale: 'pt-BR', gender: VoiceGender.female),
    ]);
  });

  test(
    'a qualidade: Android e iOS; o que não se reconhece é desconhecido',
    () async {
      final tts = TtsService(
        _FakeFlutterTts([
          {'name': 'a', 'locale': 'pt-BR', 'quality': 'very high'},
          {'name': 'b', 'locale': 'pt-BR', 'quality': 'high'},
          {'name': 'c', 'locale': 'pt-BR', 'quality': 'normal'},
          {'name': 'd', 'locale': 'pt-BR', 'quality': 'low'},
          {'name': 'e', 'locale': 'pt-BR', 'quality': 'very low'},
          {'name': 'f', 'locale': 'pt-BR', 'quality': 'premium'},
          {'name': 'g', 'locale': 'pt-BR', 'quality': 'enhanced'},
          {'name': 'h', 'locale': 'pt-BR', 'quality': 'default'},
          {'name': 'i', 'locale': 'pt-BR', 'quality': 'xyz'},
          {'name': 'j', 'locale': 'pt-BR'},
        ]),
      );
      expect(
        [for (final v in await tts.voices()) v.quality],
        const [
          VoiceQuality.veryHigh,
          VoiceQuality.high,
          VoiceQuality.normal,
          VoiceQuality.low,
          VoiceQuality.veryLow,
          VoiceQuality.veryHigh,
          VoiceQuality.high,
          VoiceQuality.normal,
          VoiceQuality.unknown,
          VoiceQuality.unknown,
        ],
      );
    },
  );

  test('sem lista de vozes: nenhuma', () async {
    expect(await TtsService(_FakeFlutterTts(null)).voices(), isEmpty);
  });

  test('falar: para a fala anterior, escolhe a voz e não pede o foco do '
      'áudio (os sons do jogo seguem no mesmo volume)', () async {
    final fake = _FakeFlutterTts(const []);
    await TtsService(fake).speak(
      'Olá',
      const ResolvedVoice(
        voice: TtsVoice(id: 'pt-br-x-a', locale: 'pt-BR'),
        pitch: 0.8,
        rate: 0.9,
      ),
    );
    expect(fake.calls, [
      'stop',
      'voice pt-br-x-a pt-BR',
      'pitch 0.8',
      'rate 0.45',
      'speak Olá focus=false',
    ]);
  });

  test('os eventos do sintetizador viram início, andamento e fim', () async {
    final fake = _FakeFlutterTts(const []);
    final tts = TtsService(fake);
    final events = <TtsEvent>[];
    tts.events.listen(events.add);
    await tts.speak(
      'Olá mundo',
      const ResolvedVoice(
        voice: TtsVoice(id: 'a', locale: 'pt-BR'),
        pitch: 1,
        rate: 1,
      ),
    );
    fake.startHandler!();
    fake.progressHandler!('Olá mundo', 4, 9, 'mundo');
    fake.completionHandler!();
    fake.errorHandler!('x');
    await Future<void>.delayed(Duration.zero);
    expect(events[0], isA<TtsStarted>());
    expect((events[1] as TtsProgress).end, 9);
    expect(events[2], isA<TtsFinished>());
    expect(events[3], isA<TtsFinished>());
  });

  test('o cancelamento da fala anterior, que chega depois de pedir a nova, '
      'não conta como fim', () async {
    final fake = _FakeFlutterTts(const []);
    final tts = TtsService(fake);
    final events = <TtsEvent>[];
    tts.events.listen(events.add);
    await tts.speak(
      'Nova',
      const ResolvedVoice(
        voice: TtsVoice(id: 'a', locale: 'pt-BR'),
        pitch: 1,
        rate: 1,
      ),
    );
    fake.cancelHandler!();
    fake.startHandler!();
    fake.completionHandler!();
    await Future<void>.delayed(Duration.zero);
    expect(events, [isA<TtsStarted>(), isA<TtsFinished>()]);
  });

  test('na volta das configurações, passa para o mecanismo preferido se ele '
      'mudou', () async {
    final fake = _FakeFlutterTts(const []);
    final tts = TtsService(fake);
    await tts.voices();
    await tts.voices(refresh: true);
    expect(fake.calls, isEmpty);

    fake.engine = 'com.google.android.tts';
    await tts.voices(refresh: true);
    expect(fake.calls, ['engine com.google.android.tts']);
  });
}
