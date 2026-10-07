import 'package:lucena/data/services/tts_service.dart';
import 'package:lucena/domain/models/voice.dart';

/// O sintetizador sem som: vozes prontas e as falas guardadas, na ordem. É
/// o dos cenários Patrol, para a voz não depender do aparelho.
class FakeTtsService extends TtsService {
  FakeTtsService({this.installed = sampleVoices});

  /// As vozes "instaladas". Vazio: o aparelho sem voz no idioma.
  List<TtsVoice> installed;

  /// As falas pedidas.
  final spoken = <(String, ResolvedVoice)>[];
  var stops = 0;

  static const sampleVoices = [
    TtsVoice(id: 'en-us-x-a', locale: 'en-US'),
    TtsVoice(id: 'en-us-x-b', locale: 'en-US'),
    TtsVoice(id: 'en-us-x-c', locale: 'en-US'),
    TtsVoice(id: 'pt-br-x-a', locale: 'pt-BR'),
    TtsVoice(id: 'pt-br-x-b', locale: 'pt-BR'),
    TtsVoice(id: 'es-es-x-a', locale: 'es-ES'),
    // A variante em árabe da suíte.
    TtsVoice(id: 'ar-x-a', locale: 'ar'),
    TtsVoice(id: 'ar-x-b', locale: 'ar'),
  ];

  /// Volta ao começo de um cenário: as vozes de sempre, nada falado.
  void reset() {
    installed = sampleVoices;
    spoken.clear();
    stops = 0;
  }

  @override
  Future<List<TtsVoice>> voices({bool refresh = false}) async => installed;

  /// Fala na hora: começa e conta que chegou ao fim do texto, mas segue
  /// "falando" até parar (o botão de áudio continua em "parar").
  @override
  Future<void> speak(String text, ResolvedVoice voice) async {
    spoken.add((text, voice));
    addEvent(const TtsStarted());
    addEvent(TtsProgress(0, text.length));
  }

  @override
  Future<void> stop() async => stops++;
}
