import 'package:flutter/material.dart';

import '../../../domain/models/clock_settings.dart';
import '../l10n/l10n.dart';

/// Como cada posição do relógio aparece nas telas de Configurações.
extension ClockPositionUi on ClockPosition {
  String label(AppLocalizations l10n) => switch (this) {
    ClockPosition.sides => l10n.clockPositionSides,
    ClockPosition.top => l10n.clockPositionTop,
    ClockPosition.bottom => l10n.clockPositionBottom,
  };

  IconData get icon => switch (this) {
    ClockPosition.sides => Icons.unfold_more,
    ClockPosition.top => Icons.vertical_align_top,
    ClockPosition.bottom => Icons.vertical_align_bottom,
  };
}
