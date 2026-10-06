import '../../../domain/models/game_sound.dart';

/// Os sons do jogo.
abstract class SoundRepository {
  /// Toca [sound].
  Future<void> play(GameSound sound);
}
