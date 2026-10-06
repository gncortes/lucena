import '../../../domain/models/game_sound.dart';
import '../../services/sound_service.dart';
import 'sound_repository.dart';

/// Sons de verdade, no aparelho. Os arquivos são carregados no primeiro
/// pedido.
class DeviceSoundRepository implements SoundRepository {
  DeviceSoundRepository(this._sound);

  final SoundService _sound;
  Future<void>? _loaded;

  /// O arquivo de cada som.
  static const assets = {
    GameSound.move: 'assets/sounds/move.mp3',
    GameSound.capture: 'assets/sounds/capture.mp3',
    GameSound.check: 'assets/sounds/check.mp3',
    GameSound.lowTime: 'assets/sounds/low_time.mp3',
  };

  @override
  Future<void> play(GameSound sound) async {
    await (_loaded ??= _sound.load(assets.values.toList()));
    await _sound.play(assets[sound]!);
  }
}
