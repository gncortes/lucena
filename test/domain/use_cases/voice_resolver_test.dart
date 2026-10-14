import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/use_cases/voice_resolver.dart';

TtsVoice _v(
  String id, {
  VoiceGender? gender,
  VoiceQuality quality = VoiceQuality.unknown,
}) => TtsVoice(id: id, locale: 'pt-BR', gender: gender, quality: quality);

CharacterVoiceProfile _p(
  String id,
  VoiceGender gender, [
  VoiceAge age = VoiceAge.adult,
]) => CharacterVoiceProfile(characterId: id, gender: gender, age: age);

void main() {
  const m = VoiceGender.male;
  const f = VoiceGender.female;
  const a = TtsVoice(id: 'pt-br-x-a', locale: 'pt-BR');
  const b = TtsVoice(id: 'pt-br-x-b', locale: 'pt-BR');
  const c = TtsVoice(id: 'pt-br-x-c', locale: 'pt-BR');

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
          voices: voices,
          teacherVoiceId: chosen,
        );
        expect(resolved?.voice, expected);
        if (resolved != null) expect(resolved.pitch, 1);
      });
    });

    test('tom escolhido e velocidade geral', () {
      final resolved = VoiceResolver.resolve(
        voices: const [a],
        teacherVoiceId: null,
        speed: 1.2,
        tone: VoiceTone.deep,
      )!;
      expect(resolved.pitch, VoiceTone.deep.pitch);
      expect(resolved.rate, closeTo(0.96 * 1.2, 1e-9));
    });
  });

  group('os personagens', () {
    Map<String, String> ids(
      Map<String, CharacterVoiceProfile> profiles,
      List<TtsVoice> voices, {
      String? teacher,
      Map<String, VoiceGender> known = const {},
    }) => {
      for (final e in VoiceResolver.assign(
        profiles: profiles,
        voices: voices,
        teacherVoiceId: teacher,
        known: known,
      ).entries)
        e.key: e.value.voice.id,
    };

    test(
      'o gênero vem na frente: homem na voz masculina, mulher na feminina',
      () {
        final voices = [_v('a', gender: f), _v('b', gender: m)];
        final out = ids(
          {'x': _p('x', m), 'y': _p('y', f)},
          voices,
          teacher: 'a',
        );
        expect(out, {'x': 'b', 'y': 'a'});
      },
    );

    test('gênero desconhecido vale menos que o igual e mais que o oposto', () {
      final voices = [_v('a', gender: f), _v('b'), _v('c', gender: m)];
      // O gênero vem antes de "não usada": a masculina serve aos dois.
      final out = ids({'x': _p('x', m), 'y': _p('y', m)}, voices, teacher: 'a');
      expect(out, {'x': 'c', 'y': 'c'});
      expect(
        ids({'x': _p('x', m)}, [_v('a', gender: f), _v('b')], teacher: 'z'),
        {'x': 'b'},
      );
    });

    test('a tabela known.json dá o gênero que o sistema não informa', () {
      final voices = [_v('a'), _v('b')];
      final out = ids(
        {'x': _p('x', f)},
        voices,
        teacher: 'z',
        known: {'a': m, 'b': f},
      );
      expect(out, {'x': 'b'});
    });

    test('o gênero do sistema vale mais que o da tabela', () {
      final out = ids(
        {'x': _p('x', m)},
        [_v('a', gender: f), _v('b')],
        teacher: 'z',
        known: {'a': m},
      );
      expect(out, {'x': 'b'});
    });

    test('diferente da do Viktor, se houver outra do mesmo gênero', () {
      final voices = [_v('a', gender: m), _v('b', gender: m)];
      expect(ids({'x': _p('x', m)}, voices, teacher: 'a'), {'x': 'b'});
    });

    test('espalha: "não usada" vale mais que a qualidade', () {
      final voices = [
        _v('a', gender: m, quality: VoiceQuality.veryHigh),
        _v('b', gender: m, quality: VoiceQuality.normal),
        _v('c', gender: m, quality: VoiceQuality.low),
        _v('t', gender: m),
      ];
      final out = ids(
        {
          for (final k in ['x', 'y', 'z']) k: _p(k, m),
        },
        voices,
        teacher: 't',
      );
      expect(out, {'x': 'a', 'y': 'b', 'z': 'c'});
    });

    test('a qualidade só desempata entre voz igual em tudo mais', () {
      final voices = [
        _v('a', gender: m, quality: VoiceQuality.low),
        _v('b', gender: m, quality: VoiceQuality.veryHigh),
        _v('c', gender: m, quality: VoiceQuality.high),
      ];
      expect(ids({'x': _p('x', m)}, voices, teacher: 'z'), {'x': 'b'});
    });

    test('sem mais nada, o id da voz desempata', () {
      expect(ids({'x': _p('x', m)}, [_v('b'), _v('a')], teacher: 'z'), {
        'x': 'a',
      });
    });

    test('determinístico: a ordem da lista não muda o resultado', () {
      final voices = [
        _v('a', gender: f),
        _v('b', gender: m),
        _v('c', gender: m),
        _v('d'),
      ];
      final profiles = {
        'p': _p('p', m),
        'q': _p('q', f),
        'r': _p('r', m),
        'k': _p('k', m),
      };
      final first = ids(profiles, voices, teacher: 'b');
      expect(ids(profiles, voices.reversed.toList(), teacher: 'b'), first);
      expect(ids(profiles, voices, teacher: 'b'), first);
    });

    test('uma voz só: todos nela, cada um com o tom da idade', () {
      final out = VoiceResolver.assign(
        profiles: {
          'x': _p('x', m, VoiceAge.elder),
          'y': _p('y', f, VoiceAge.child),
        },
        voices: const [a],
        teacherVoiceId: null,
      );
      expect(out['x']!.voice, a);
      expect(out['y']!.voice, a);
      expect(out['x']!.pitch, 0.8);
      expect(out['y']!.pitch, 1.3);
    });

    test('sem vozes no idioma: nada', () {
      expect(
        VoiceResolver.assign(
          profiles: {'x': _p('x', m)},
          voices: const [],
          teacherVoiceId: null,
        ),
        isEmpty,
      );
    });

    test('o ritmo da idade é multiplicado pela velocidade geral', () {
      final out = VoiceResolver.assign(
        profiles: {'x': _p('x', m, VoiceAge.young)},
        voices: const [a, b],
        teacherVoiceId: null,
        speed: 1.2,
      );
      expect(out['x']!.pitch, 1.05);
      expect(out['x']!.rate, closeTo(1.08 * 1.2, 1e-9));
    });
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
    test('lê gênero e idade', () {
      expect(
        CharacterVoiceProfile.fromJson('grandpa', {
          'genero': 'm',
          'idade': 'idoso',
        }),
        _p('grandpa', m, VoiceAge.elder),
      );
      expect(
        CharacterVoiceProfile.fromJson('prodigy', {
          'genero': 'f',
          'idade': 'crianca',
        }),
        _p('prodigy', f, VoiceAge.child),
      );
    });

    test('campo ausente ou estranho fica em homem adulto', () {
      expect(CharacterVoiceProfile.fromJson('x', {'genero': '?'}), _p('x', m));
    });
  });
}
