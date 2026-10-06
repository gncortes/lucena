import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/game_sound.dart';
import 'package:lucena/ui/core/sound/game_sounds.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_sound_repository.dart';

void main() {
  late FakeSettingsRepository settings;
  late FakeSoundRepository sound;
  late GameSounds sounds;

  setUp(() {
    settings = FakeSettingsRepository();
    sound = FakeSoundRepository();
    sounds = GameSounds(settings, sound);
  });

  test('de fábrica os sons estão ligados: toca o que foi pedido', () async {
    await sounds.play(GameSound.lowTime);
    await sounds.move('Nf3');
    await sounds.move('exd5');
    await sounds.move('Qh5+');
    expect(sound.played, [
      GameSound.lowTime,
      GameSound.move,
      GameSound.capture,
      GameSound.check,
    ]);
  });

  test('com os sons desligados nas configurações, não toca nada', () async {
    settings.settings = const AppSettings(sound: false);
    await sounds.play(GameSound.lowTime);
    await sounds.move('Nf3');
    expect(sound.played, isEmpty);
  });

  test(
    'a preferência é lida a cada som: desligar vale no lance seguinte',
    () async {
      await sounds.move('e4');
      settings.settings = const AppSettings(sound: false);
      await sounds.move('e5');
      expect(sound.played, [GameSound.move]);
    },
  );
}
