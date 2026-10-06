import 'package:lucena/data/repositories/sound/sound_repository.dart';
import 'package:lucena/domain/models/game_sound.dart';

/// Não toca nada: guarda os sons pedidos, na ordem.
class FakeSoundRepository implements SoundRepository {
  final played = <GameSound>[];

  @override
  Future<void> play(GameSound sound) async => played.add(sound);
}
