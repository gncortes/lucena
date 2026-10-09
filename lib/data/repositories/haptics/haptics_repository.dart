import '../../../domain/models/haptic_event.dart';

/// O retorno tátil do app.
abstract class HapticsRepository {
  /// Vibra do jeito de [event].
  Future<void> play(HapticEvent event);
}
