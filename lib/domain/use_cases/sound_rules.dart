import '../models/game_sound.dart';
import '../models/haptic_event.dart';

/// Que som cada lance faz.
abstract final class SoundRules {
  /// O som do lance escrito em [san] (`Nf3`, `exd5`, `Qh5+`, `O-O`): o xeque
  /// ganha da captura.
  static GameSound ofMove(String san) {
    if (san.contains('+') || san.contains('#')) return GameSound.check;
    if (san.contains('x')) return GameSound.capture;
    return GameSound.move;
  }
}

/// Que vibração cada lance do jogador faz: a mesma regra do som.
abstract final class HapticRules {
  /// A vibração do lance escrito em [san].
  static HapticEvent ofMove(String san) => switch (SoundRules.ofMove(san)) {
    GameSound.check => HapticEvent.check,
    GameSound.capture => HapticEvent.capture,
    _ => HapticEvent.move,
  };
}
