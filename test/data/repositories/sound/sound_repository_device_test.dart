import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/sound/sound_repository_device.dart';
import 'package:lucena/data/services/sound_service.dart';
import 'package:lucena/domain/models/game_sound.dart';

/// Guarda o que foi carregado e tocado, sem tocar no aparelho.
class _RecordingSoundService extends SoundService {
  final loads = <List<String>>[];
  final played = <String>[];

  @override
  Future<void> load(List<String> assets) async => loads.add(assets);

  @override
  Future<void> play(String asset) async => played.add(asset);
}

void main() {
  test(
    'carrega os quatro arquivos uma vez só e toca o do som pedido',
    () async {
      final service = _RecordingSoundService();
      final repository = DeviceSoundRepository(service);

      await repository.play(GameSound.move);
      await repository.play(GameSound.capture);
      await repository.play(GameSound.check);
      await repository.play(GameSound.lowTime);

      expect(service.loads, hasLength(1));
      expect(service.loads.single, hasLength(GameSound.values.length));
      expect(service.played, [
        'assets/sounds/move.mp3',
        'assets/sounds/capture.mp3',
        'assets/sounds/check.mp3',
        'assets/sounds/low_time.mp3',
      ]);
    },
  );

  test('todo som tem um arquivo', () {
    expect(DeviceSoundRepository.assets.keys, GameSound.values);
  });
}
