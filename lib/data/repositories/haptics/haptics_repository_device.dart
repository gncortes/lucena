import '../../services/vibration_service.dart';
import 'haptics_repository.dart';

/// Vibração de verdade, no aparelho.
class DeviceHapticsRepository implements HapticsRepository {
  const DeviceHapticsRepository(this._vibration);

  final VibrationService _vibration;

  @override
  Future<void> lowTime() => _vibration.vibrate();
}
