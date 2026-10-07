import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/use_cases/voice_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = TtsVoice(id: 'pt-br-x-a', locale: 'pt-BR');
  const b = TtsVoice(id: 'pt-br-x-b', locale: 'pt-BR');
  const c = TtsVoice(id: 'pt-br-x-c', locale: 'pt-BR');
  const tito = CharacterVoiceProfile(
    characterId: 'grandpa',
    pitch: 0.8,
    rate: 0.85,
    slot: 1,
  );
  const viktor = CharacterVoiceProfile(characterId: 'master', pitch: 0.9);

  group('o professor', () {
    final cases = <String, (List<TtsVoice>, String?, TtsVoice?)>{
      'usa a voz escolhida': ([a, b, c], 'pt-br-x-b', b),
      'sem escolha, a primeira': ([a, b, c], null, a),
      'voz salva que sumiu: a primeira': ([a, c], 'pt-br-x-b', a),
      'sem voz no idioma: nenhuma': ([], 'pt-br-x-b', null),
    };
    cases.forEach((name, data) {
      final (voices, chosen, expected) = data;
      test(name, () {
        final resolved = VoiceResolver.resolve(
          profile: viktor,
          voices: voices,
          teacherVoiceId: chosen,
          teacher: true,
        );
        expect(resolved?.voice, expected);
        // A voz do professor sai como ela é: sem o tom do perfil.
        if (resolved != null) expect(resolved.pitch, 1);
      });
    });
  });

  group('um personagem', () {
    final cases = <String, (List<TtsVoice>, String?, String?, TtsVoice?)>{
      'usa a voz que o usuário escolheu': (
        [a, b, c],
        'pt-br-x-a',
        'pt-br-x-a',
        a,
      ),
      'sem escolha, uma diferente da do professor (pela vaga)': (
        [a, b, c],
        'pt-br-x-a',
        null,
        c,
      ),
      'a vaga dá a volta nas vozes que sobram': ([a, b], 'pt-br-x-a', null, b),
      'com uma voz só, todos usam essa': ([a], 'pt-br-x-a', null, a),
      'voz escolhida que sumiu: como sem escolha': (
        [a, b, c],
        'pt-br-x-b',
        'sumiu',
        c,
      ),
      'sem voz no idioma: nenhuma': ([], null, 'pt-br-x-a', null),
    };
    cases.forEach((name, data) {
      final (voices, teacher, chosen, expected) = data;
      test(name, () {
        final resolved = VoiceResolver.resolve(
          profile: tito,
          voices: voices,
          teacherVoiceId: teacher,
          chosenVoiceId: chosen,
        );
        expect(resolved?.voice, expected);
      });
    });
  });

  test('a mesma voz escolhida soa igual no professor e num personagem', () {
    final teacher = VoiceResolver.resolve(
      profile: viktor,
      voices: const [a, b],
      teacherVoiceId: 'pt-br-x-b',
      teacher: true,
    );
    final coco = VoiceResolver.resolve(
      profile: tito,
      voices: const [a, b],
      teacherVoiceId: 'pt-br-x-a',
      chosenVoiceId: 'pt-br-x-b',
    );
    expect(coco, teacher);
  });

  test('a voz que o app escolheu tem o tom e a velocidade do perfil, e a '
      'velocidade geral multiplica', () {
    final resolved = VoiceResolver.resolve(
      profile: tito,
      voices: const [a],
      teacherVoiceId: null,
      speed: 1.2,
    )!;
    expect(resolved.pitch, 0.8);
    expect(resolved.rate, closeTo(1.02, 1e-9));
  });

  group('as vozes do idioma', () {
    const us = TtsVoice(id: 'en-us', locale: 'en-US');
    const gb = TtsVoice(id: 'en-gb', locale: 'en_GB');
    const pt = TtsVoice(id: 'pt', locale: 'pt-PT');
    const br = TtsVoice(id: 'br', locale: 'pt-BR');
    test('com voz da região do app, só as dela', () {
      expect(TtsVoice.forLanguage([us, pt, gb], 'en-GB'), [gb]);
      expect(TtsVoice.forLanguage([us, pt, gb], 'en'), [us]);
    });

    test('o português do app é o do Brasil; o de Portugal, o pt-PT', () {
      expect(TtsVoice.forLanguage([pt, br], 'pt'), [br]);
      expect(TtsVoice.forLanguage([pt, br], 'pt-PT'), [pt]);
    });

    test('sem voz da região, as do idioma; sem voz do idioma, nenhuma', () {
      expect(TtsVoice.forLanguage([pt], 'pt'), [pt]);
      expect(TtsVoice.forLanguage([gb], 'en'), [gb]);
      expect(TtsVoice.forLanguage([us, gb], 'pt'), isEmpty);
    });
  });

  group('o perfil do JSON', () {
    test('lê tom, velocidade e vaga', () {
      expect(
        CharacterVoiceProfile.fromJson('grandpa', {
          'pitch': 0.8,
          'rate': 0.85,
          'slot': 1,
        }),
        tito,
      );
    });

    test('campo ausente fica neutro e valor absurdo vem para a faixa', () {
      final profile = CharacterVoiceProfile.fromJson('x', {'pitch': 9});
      expect(profile.pitch, 2);
      expect(profile.rate, 1);
      expect(profile.slot, 0);
    });
  });
}
