import '../models/game_sound.dart';

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
