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
  Future<dynamic> setVoice(Map<String, String> voice) async =>
      calls.add('voice ${voice['name']} ${voice['locale']}');
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
