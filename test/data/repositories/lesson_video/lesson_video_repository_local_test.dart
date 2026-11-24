import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_video/lesson_video_repository_local.dart';
import 'package:lucena/data/repositories/lesson_video/video_audio_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late PreferencesService preferences;
  late LocalLessonVideoRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesService();
    repository = LocalLessonVideoRepository(preferences);
  });

  const progress = VideoProgress(
    line: 'ideia.ex1.p',
    fraction: 0.4,
    resolved: {'ideia.ex1.p'},
  );

  test('sem nada salvo: sem progresso e ajustes padrão', () async {
    expect(await repository.progress('l', 'p', 'ideia'), isNull);
    expect(await repository.settings(), const VideoSettings());
  });

  test('o progresso volta depois de reabrir, por etapa', () async {
    await repository.saveProgress('l', 'p', 'ideia', progress);
    final reopened = LocalLessonVideoRepository(PreferencesService());
    expect(await reopened.progress('l', 'p', 'ideia'), progress);
    expect(await reopened.progress('l', 'p', 'demos'), isNull);
    expect(await reopened.progress('l', 'outra', 'ideia'), isNull);
  });

  test('esquecer o progresso volta ao começo', () async {
    await repository.saveProgress('l', 'p', 'ideia', progress);
    await repository.clearProgress('l', 'p', 'ideia');
    expect(await repository.progress('l', 'p', 'ideia'), isNull);
  });

  test('os ajustes persistem', () async {
    const settings = VideoSettings(captions: false, rate: 1.5);
    await repository.saveSettings(settings);
    expect(
      await LocalLessonVideoRepository(PreferencesService()).settings(),
      settings,
    );
  });

  test('salvo ilegível vira nulo ou o padrão', () async {
    await preferences.setString(
      LocalLessonVideoRepository.progressKeyOf('l', 'p', 'ideia'),
      'não é json',
    );
    await preferences.setString(LocalLessonVideoRepository.settingsKey, '[1]');
    expect(await repository.progress('l', 'p', 'ideia'), isNull);
    expect(await repository.settings(), const VideoSettings());
  });

  test('o áudio silencioso não toca nem tem posição', () async {
    const audio = SilentVideoAudioRepository();
    await audio.play('audio/pt/viktor/x.opus', from: Duration.zero);
    expect(await audio.position(), isNull);
    await audio.stop();
    await audio.dispose();
  });
}
