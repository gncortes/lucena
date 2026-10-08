import 'package:flutter/services.dart';

/// Embrulha o retorno tátil do aparelho.
class VibrationService {
  const VibrationService();

  /// Um clique leve de seleção.
  Future<void> selection() => HapticFeedback.selectionClick();

  /// Um toque leve.
  Future<void> light() => HapticFeedback.lightImpact();

  /// Um toque médio.
  Future<void> medium() => HapticFeedback.mediumImpact();

  /// Um toque forte.
  Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Uma vibração curta.
  Future<void> vibrate() => HapticFeedback.vibrate();
}
