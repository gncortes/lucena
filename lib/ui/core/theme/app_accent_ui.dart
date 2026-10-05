import 'package:flutter/material.dart';

import '../../../domain/models/app_accent.dart';
import '../l10n/l10n.dart';

/// Como cada cor do app aparece nas telas de escolha.
extension AppAccentUi on AppAccent {
  String label(AppLocalizations l10n) => switch (this) {
    AppAccent.blue => l10n.settingsAccentBlue,
    AppAccent.green => l10n.settingsAccentGreen,
    AppAccent.purple => l10n.settingsAccentPurple,
    AppAccent.pink => l10n.settingsAccentPink,
    AppAccent.orange => l10n.settingsAccentOrange,
    AppAccent.teal => l10n.settingsAccentTeal,
  };

  /// A cor da bolinha de escolha: viva, a mesma no tema claro e no escuro.
  Color get swatch => switch (this) {
    AppAccent.blue => const Color(0xFF2F6FD0),
    AppAccent.green => const Color(0xFF2E9E6B),
    AppAccent.purple => const Color(0xFF7B55D4),
    AppAccent.pink => const Color(0xFFD6478D),
    AppAccent.orange => const Color(0xFFE07A1F),
    AppAccent.teal => const Color(0xFF1E9AA5),
  };
}
