import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_voice/lesson_voice_repository.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_voice_cubit.dart';

import '../../../../testing/fakes/fake_lesson_voice_repository.dart';

void main() {
  late FakeLessonVoiceRepository repository;
  late LessonVoiceCubit cubit;

  Future<void> start({VoicePackState? pack, bool on = true}) async {
    repository = FakeLessonVoiceRepository(states: {'c1': ?pack}, on: on);
    cubit = LessonVoiceCubit(repository, chapterId: 'c1');
    addTearDown(cubit.close);
    await cubit.load();
    await pumpEventQueue();
  }

  test('com o áudio baixado e a voz ligada, fala', () async {
    await start(pack: const VoicePackReady());
    expect(cubit.state.speaks, isTrue);
    expect(cubit.state.showsNoAudio, isFalse);
  });

  test('Vídeo 9: voz desligada vai em leitura e sem aviso', () async {
    await start(pack: const VoicePackReady(), on: false);
    expect(cubit.state.speaks, isFalse);
    expect(cubit.state.showsNoAudio, isFalse);
  });

  test('Vídeo 10: sem o áudio vai em leitura com "Sem áudio"', () async {
    await start();
    expect(cubit.state.speaks, isFalse);
    expect(cubit.state.showsNoAudio, isTrue);
  });

  test('"Baixar a voz" baixa e passa a falar', () async {
    await start();
    await cubit.download();
    expect(repository.downloads, ['c1']);
    expect(cubit.state.speaks, isTrue);
  });

  test(
    'Vídeo 11: falha ao baixar mantém o aviso e deixa tentar de novo',
    () async {
      await start();
      repository.nextDownload = const VoicePackFailed(VoicePackFailure.network);
      await cubit.download();
      expect(cubit.state.pack, const VoicePackFailed(VoicePackFailure.network));
      expect(cubit.state.showsNoAudio, isTrue);
      repository.nextDownload = const VoicePackReady();
      await cubit.download();
      expect(cubit.state.speaks, isTrue);
      expect(repository.downloads, ['c1', 'c1']);
    },
  );

  test('desligar a voz persiste', () async {
    await start(pack: const VoicePackReady());
    await cubit.setVoiceOn(on: false);
    expect(repository.on, isFalse);
    expect(cubit.state.voiceOn, isFalse);
  });
}
