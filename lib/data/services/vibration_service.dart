import 'package:flutter/services.dart';

/// Embrulha a vibração do aparelho.
class VibrationService {
  const VibrationService();

  /// Uma vibração curta.
  Future<void> vibrate() => HapticFeedback.vibrate();
}
