import '../../../domain/models/haptic_event.dart';
import '../../services/vibration_service.dart';
import 'haptics_repository.dart';

/// Vibração de verdade, no aparelho.
class DeviceHapticsRepository implements HapticsRepository {
  const DeviceHapticsRepository(this._vibration);

  final VibrationService _vibration;

  /// O intervalo entre os dois toques do sucesso.
  static const successGap = Duration(milliseconds: 90);

  @override
  Future<void> play(HapticEvent event) async {
    switch (event) {
      case HapticEvent.selection:
        await _vibration.selection();
      case HapticEvent.move:
        await _vibration.light();
      case HapticEvent.capture:
      case HapticEvent.check:
        await _vibration.medium();
      case HapticEvent.success:
        // Um médio seguido de um leve.
        await _vibration.medium();
        await Future<void>.delayed(successGap);
        await _vibration.light();
      case HapticEvent.celebrate:
        await _vibration.heavy();
      case HapticEvent.warning:
        await _vibration.vibrate();
    }
  }
}
