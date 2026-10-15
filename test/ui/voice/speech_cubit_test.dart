import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/voice/voice_repository.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_voice_repository.dart';

void main() {
  late FakeVoiceRepository voice;

  Future<SpeechCubit> open({VoiceSettings? settings}) async {
    voice = FakeVoiceRepository(settings: settings ?? const VoiceSettings());
    final cubit = SpeechCubit(voice);
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  test('T65: novo inactive invalida retomada aguardando parada', () async {
    final delayed = _DelayedStopVoice();
    final cubit = SpeechCubit(delayed);
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.say('Continue.', speakerId: 'master', language: 'en');
    final gate = delayed.stopGate = Completer<void>();
    final pause = cubit.pauseForBackground();
    final resume = cubit.resumeFromBackground();
    await cubit.pauseForBackground();
    gate.complete();
    await pause;
    await resume;
    expect(delayed.spoken, hasLength(1));
    await cubit.resumeFromBackground();
    expect(delayed.spoken, hasLength(2));
  });

  test(
    'T65: background conserva fala, retoma palavra e permite parar',
    () async {
      final cubit = await open();
      await cubit.say(
        'Agora Tf3 e o rei foge.',
        speakerId: 'master',
        language: 'pt',
      );
      voice.emit(const TtsProgress(15, 16));
      await Future<void>.delayed(Duration.zero);
      await cubit.pauseForBackground();
      await cubit.pauseForBackground();
      expect(voice.stops, 1);
      expect(cubit.state.speaking, 'Agora Tf3 e o rei foge.');
      voice.emit(const TtsFinished());
      await Future<void>.delayed(Duration.zero);
      await cubit.resumeFromBackground();
      expect(voice.spoken.last.$1, 'e o rei foge.');
      voice.emit(const TtsProgress(2, 3));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.revealed, 'Agora Tf3 e o'.length);
      await cubit.pauseForBackground();
      await cubit.stop();
      final count = voice.spoken.length;
      await cubit.resumeFromBackground();
      expect(voice.spoken.length, count);
      expect(cubit.state.speaking, isNull);
    },
  );

  test(
    'T65: sem progresso repete fala, pedido em background aguarda',
    () async {
      final cubit = await open();
      await cubit.pauseForBackground();
      await cubit.say('Espere.', speakerId: 'master', language: 'pt');
      expect(voice.spoken, isEmpty);
      await cubit.resumeFromBackground();
      expect(voice.spoken.single.$1, 'Espere.');
      await cubit.pauseForBackground();
      await cubit.resumeFromBackground();
      expect(voice.spoken.last.$1, 'Espere.');
    },
  );

  test(
    'o professor fala com a voz escolhida, do jeito dela, e o texto falável',
    () async {
      final cubit = await open(
        settings: const VoiceSettings(teacherVoice: 'pt-br-b'),
      );
      await cubit.say('Agora Tf3.', speakerId: 'master', language: 'pt-BR');
      final (text, resolved) = voice.spoken.single;
      expect(text, 'Agora torre f3.');
      expect(resolved.voice.id, 'pt-br-b');
      expect(resolved.pitch, 1);
      // O texto da tela é o que fica marcado como falando.
      expect(cubit.state.speaking, 'Agora Tf3.');
      expect(cubit.state.speakerId, 'master');
    },
  );

  test('um personagem fala com outra voz que não a do professor', () async {
    final cubit = await open(
      settings: const VoiceSettings(teacherVoice: 'pt-br-a'),
    );
    await cubit.say('Oi!', speakerId: 'grandpa', language: 'pt-BR');
    final (_, resolved) = voice.spoken.single;
    expect(resolved.voice.id, isNot('pt-br-a'));
    expect(resolved.pitch, 0.8);
    expect(resolved.rate, 0.85);
  });

  test('sem voz no idioma, não fala e o idioma fica sem voz', () async {
    final cubit = await open();
    expect(cubit.state.availableFor('ja'), isFalse);
    expect(cubit.state.availableFor('pt-BR'), isTrue);
    await cubit.say('こんにちは', speakerId: 'master', language: 'ja');
    expect(voice.spoken, isEmpty);
    expect(cubit.state.speaking, isNull);
  });

  test('sozinho só com a voz ligada', () async {
    final off = await open();
    await off.sayIfEnabled('Oi', speakerId: 'master', language: 'en');
    expect(voice.spoken, isEmpty);

    final on = await open(settings: const VoiceSettings(enabled: true));
    await on.sayIfEnabled('Oi', speakerId: 'master', language: 'en');
    expect(voice.spoken, hasLength(1));
  });

  test('o botão fala e, falando, para', () async {
    final cubit = await open();
    await cubit.toggle('Oi', speakerId: 'master', language: 'en');
    expect(cubit.state.isSpeaking('Oi'), isTrue);
    await cubit.toggle('Oi', speakerId: 'master', language: 'en');
    expect(cubit.state.speaking, isNull);
    expect(voice.stops, 1);
  });

  test('o balão que sai da tela para só a fala dele', () async {
    final cubit = await open();
    await cubit.say('Um', speakerId: 'master', language: 'en');
    await cubit.stopIf('Outro');
    expect(voice.stops, 0);
    await cubit.stopIf('Um');
    expect(voice.stops, 1);
  });

  test(
    'o andamento da voz vira a posição no texto da tela; o fim limpa',
    () async {
      final cubit = await open();
      await cubit.say(
        'Agora Tf3 e o rei foge.',
        speakerId: 'master',
        language: 'pt',
      );
      // "Agora torre f3 e o rei foge.": até "e", depois do lance.
      voice.emit(const TtsProgress(15, 16));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.revealed, 'Agora Tf3 e'.length);

      voice.emit(const TtsFinished());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.speaking, isNull);
      expect(cubit.state.revealed, isNull);
    },
  );

  test('escolher a voz do professor liga a voz e é gravado', () async {
    final cubit = await open();
    await cubit.setTeacherVoice('pt-br-c');
    expect(voice.settings.enabled, isTrue);
    expect(voice.settings.teacherVoice, 'pt-br-c');
  });

  test('desligar a voz para a fala e grava', () async {
    final cubit = await open(settings: const VoiceSettings(enabled: true));
    await cubit.say('Oi', speakerId: 'master', language: 'en');
    await cubit.setEnabled(enabled: false);
    expect(voice.stops, 1);
    expect(voice.settings.enabled, isFalse);
  });

  test('a voz de um personagem vem do app, com o tom da idade', () async {
    final cubit = await open();
    final grandpa = cubit.state.voiceOf('grandpa', 'pt-BR')!;
    // Não é a do professor (a primeira) e o Tito é idoso.
    expect(grandpa.voice.id, isNot('pt-br-a'));
    expect(grandpa.pitch, 0.8);
    expect(grandpa.rate, 0.85);
    // Quem não tem perfil fala como homem adulto.
    expect(cubit.state.voiceOf('stockfish', 'pt-BR')!.pitch, 1);
  });

  test('trocar a voz do professor recalcula a dos personagens', () async {
    final cubit = await open();
    final before = cubit.state.voiceOf('grandpa', 'pt-BR')!.voice.id;
    await cubit.setTeacherVoice(before);
    expect(cubit.state.voiceOf('grandpa', 'pt-BR')!.voice.id, isNot(before));
  });

  test('a amostra fala com a voz pedida, sem gravar a escolha', () async {
    final cubit = await open();
    await cubit.preview(
      'Oi, eu sou o Tito.',
      characterId: 'grandpa',
      voiceId: 'pt-br-c',
      language: 'pt-BR',
    );
    final (_, resolved) = voice.spoken.single;
    expect(resolved.voice.id, 'pt-br-c');
    expect(resolved.pitch, 1);
  });

  test('a velocidade geral é gravada e multiplica a de cada um', () async {
    final cubit = await open();
    await cubit.setSpeed(1.2);
    expect(voice.settings.speed, 1.2);
    expect(cubit.state.voiceOf('grandpa', 'pt')!.rate, closeTo(1.02, 1e-9));
  });

  test('a velocidade do balão dá a volta na lista', () async {
    final cubit = await open();
    for (final expected in [1.2, 1.4, 0.8, 1.0]) {
      await cubit.nextSpeed();
      expect(voice.settings.speed, expected);
    }
    // Calado, mudar a velocidade não fala nada.
    expect(voice.spoken, isEmpty);
  });

  test('o personagem calado fica calado ao reabrir o app', () {
    const muted = VoiceSettings(enabled: true, charactersMuted: true);
    final back = VoiceSettings.fromJson(muted.toJson());
    expect(back, muted);
    expect(back.charactersMuted, isTrue);
  });
}

class _DelayedStopVoice extends FakeVoiceRepository {
  Completer<void>? stopGate;

  @override
  Future<void> stop() async {
    await stopGate?.future;
    await super.stop();
  }
}
