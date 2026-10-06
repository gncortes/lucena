import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/sound/sound_repository.dart';
import '../../../domain/models/game_sound.dart';
import '../../../domain/use_cases/sound_rules.dart';

/// Os sons do jogo, tocados só se o usuário os deixou ligados nas
/// configurações. É o que os view models das telas com tabuleiro usam.
class GameSounds {
  const GameSounds(this._settings, this._sound);

  final SettingsRepository _settings;
  final SoundRepository _sound;

  /// Toca [sound], se os sons estão ligados.
  Future<void> play(GameSound sound) async {
    final settings = await _settings.load();
    if (settings.sound) await _sound.play(sound);
  }

  /// O som do lance escrito em [san].
  Future<void> move(String san) => play(SoundRules.ofMove(san));
}
