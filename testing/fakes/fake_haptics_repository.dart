import 'package:lucena/data/repositories/haptics/haptics_repository.dart';
import 'package:lucena/domain/models/haptic_event.dart';

/// Não vibra: só guarda as vibrações pedidas.
class FakeHapticsRepository implements HapticsRepository {
  final events = <HapticEvent>[];

  /// Quantos avisos de pouco tempo.
  int get lowTimeCalls => events.where((e) => e == HapticEvent.warning).length;

  @override
  Future<void> play(HapticEvent event) async => events.add(event);
}
