import 'package:flutter/material.dart';

import '../../../domain/models/app_theme_mode.dart';
import '../l10n/l10n.dart';

/// Como cada tema aparece nas telas de Configurações.
extension AppThemeModeUi on AppThemeMode {
  IconData get icon => switch (this) {
    AppThemeMode.system => Icons.brightness_auto_outlined,
    AppThemeMode.light => Icons.light_mode_outlined,
    AppThemeMode.dark => Icons.dark_mode_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    AppThemeMode.system => l10n.settingsThemeSystem,
    AppThemeMode.light => l10n.settingsThemeLight,
    AppThemeMode.dark => l10n.settingsThemeDark,
  };

  ThemeMode get material => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
