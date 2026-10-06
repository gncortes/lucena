import 'package:sound_effect/sound_effect.dart';

/// Embrulha o toque de sons curtos do aparelho. Um erro de áudio nunca chega
/// a quem pediu o som: sem som, o jogo segue.
class SoundService {
  SoundService([SoundEffect? player]) : _player = player ?? SoundEffect();

  final SoundEffect _player;
  Future<void>? _ready;

  /// Deixa os sons de [assets] prontos para tocar sem atraso.
  Future<void> load(List<String> assets) async {
    try {
      await (_ready ??= _player.initialize(maxStreams: 2));
      for (final asset in assets) {
        await _player.load(asset, asset);
      }
    } on Object {
      // Aparelho sem áudio, arquivo ilegível: fica sem som.
    }
  }

  /// Toca o som de [asset], já carregado por [load].
  Future<void> play(String asset) async {
    try {
      await _player.play(asset);
    } on Object {
      // Idem.
    }
  }
}
