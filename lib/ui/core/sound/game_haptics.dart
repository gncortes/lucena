import '../../../data/repositories/haptics/haptics_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/haptic_event.dart';
import '../../../domain/use_cases/sound_rules.dart';

/// O retorno tátil, só se o usuário deixou a vibração ligada nas
/// configurações. É o que os view models usam, como os `GameSounds`.
class GameHaptics {
  const GameHaptics(this._settings, this._haptics);

  final SettingsRepository _settings;
  final HapticsRepository _haptics;

  /// Vibra do jeito de [event], se a vibração está ligada.
  Future<void> play(HapticEvent event) async {
    final settings = await _settings.load();
    if (!settings.vibration) return;
    // O aviso de pouco tempo tem também a chave própria, no relógio.
    if (event == HapticEvent.warning && !settings.clock.lowTimeVibration) {
      return;
    }
    await _haptics.play(event);
  }

  /// A vibração do lance do jogador escrito em [san].
  Future<void> move(String san) => play(HapticRules.ofMove(san));
}
