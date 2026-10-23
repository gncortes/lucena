import 'package:flutter/material.dart';

import '../../../domain/models/race.dart';
import '../../core/l10n/l10n.dart';

/// Nomes e ícones dos temas da Corrida.
extension RaceThemeUi on RaceTheme {
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      RaceTheme.rook => l10n.raceThemeRook,
      RaceTheme.pawns => l10n.raceThemePawns,
      RaceTheme.queen => l10n.raceThemeQueen,
      RaceTheme.minor => l10n.raceThemeMinor,
    };
  }
}
