import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/voice.dart';

void main() {
  test('JSON velho com as vozes e tons por personagem: lido sem eles', () {
    final settings = VoiceSettings.fromJson({
      'enabled': true,
      'speed': 1.2,
      'teacher': 'pt-br-x-a',
      'teacherTone': 'deep',
      'characters': {'grandpa': 'pt-br-x-b'},
      'characterTones': {'grandpa': 'high'},
      'charactersMuted': true,
    });
    expect(
      settings,
      const VoiceSettings(
        enabled: true,
        speed: 1.2,
        teacherVoice: 'pt-br-x-a',
        teacherTone: VoiceTone.deep,
        charactersMuted: true,
      ),
    );
  });

  test('regravado, o JSON não leva mais os personagens', () {
    final json = VoiceSettings.fromJson({
      'characters': {'grandpa': 'x'},
      'characterTones': {'grandpa': 'high'},
    }).toJson();
    expect(json.containsKey('characters'), isFalse);
    expect(json.containsKey('characterTones'), isFalse);
    expect(json['teacherTone'], 'natural');
  });
}
