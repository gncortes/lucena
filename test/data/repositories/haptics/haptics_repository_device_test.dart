import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/haptics/haptics_repository_device.dart';
import 'package:lucena/data/services/vibration_service.dart';
import 'package:lucena/domain/models/haptic_event.dart';

/// Guarda os toques pedidos ao aparelho.
class _RecordingVibration implements VibrationService {
  final calls = <String>[];

  @override
  Future<void> selection() async => calls.add('selection');
  @override
  Future<void> light() async => calls.add('light');
  @override
  Future<void> medium() async => calls.add('medium');
  @override
  Future<void> heavy() async => calls.add('heavy');
  @override
  Future<void> vibrate() async => calls.add('vibrate');
}

void main() {
  test('cada momento chama o toque certo do aparelho', () async {
    final expected = {
      HapticEvent.selection: ['selection'],
      HapticEvent.move: ['light'],
      HapticEvent.capture: ['medium'],
      HapticEvent.check: ['medium'],
      HapticEvent.success: ['medium', 'light'],
      HapticEvent.celebrate: ['heavy'],
      HapticEvent.warning: ['vibrate'],
    };
    for (final MapEntry(key: event, value: calls) in expected.entries) {
      final vibration = _RecordingVibration();
      await DeviceHapticsRepository(vibration).play(event);
      expect(vibration.calls, calls, reason: event.name);
    }
  });
}
