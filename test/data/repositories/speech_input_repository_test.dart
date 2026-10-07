import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/blind/speech_input_repository.dart';

void main() {
  test('o idioma vai com a região: o português do app é o do Brasil', () {
    expect(DeviceSpeechInputRepository.localeFor('pt'), 'pt_BR');
    expect(DeviceSpeechInputRepository.localeFor('pt-PT'), 'pt_PT');
    expect(DeviceSpeechInputRepository.localeFor('en'), 'en_US');
    expect(DeviceSpeechInputRepository.localeFor('es-MX'), 'es_MX');
    expect(DeviceSpeechInputRepository.localeFor('de'), 'de');
  });
}
