import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/app_accent.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../core/board/board_appearance_widgets.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_accent_ui.dart';
import '../../core/theme/app_theme_mode_ui.dart';
import '../../core/widgets/accent_picker.dart';
import '../../core/widgets/choice_tile.dart';
import '../view_models/settings_cubit.dart';

/// Claro, escuro ou o do aparelho, e a cor predominante do app.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final selected = context.select(
      (SettingsCubit cubit) => cubit.state?.themeMode ?? AppThemeMode.system,
    );
    // Sem cor escolhida, vale a de fábrica do tema que está na tela.
    final accent =
        context.select((SettingsCubit cubit) => cubit.state?.accent) ??
        AppAccent.standard(
          dark: Theme.of(context).brightness == Brightness.dark,
        );
    return Scaffold(
      key: SettingsKeys.themeScreen,
      appBar: AppBar(title: Text(l10n.settingsTheme)),
      body: ListView(
        children: [
          for (final mode in AppThemeMode.values)
            ChoiceTile(
              key: SettingsKeys.themeOption(mode),
              icon: mode.icon,
              label: mode.label(l10n),
              selected: selected == mode,
              onTap: () => cubit.setThemeMode(mode),
            ),
          const Divider(height: 24),
          AppearanceSectionTitle(
            l10n.settingsAccent,
            value: accent.label(l10n),
            valueKey: SettingsKeys.accentValue,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: AccentPicker(
              selected: accent,
              keyOf: SettingsKeys.accentOption,
              onSelected: cubit.setAccent,
            ),
          ),
        ],
      ),
    );
  }
}
