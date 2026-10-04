import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/app_theme_mode.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme_mode_ui.dart';
import '../../core/widgets/choice_tile.dart';
import '../view_models/settings_cubit.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final selected = context.select(
      (SettingsCubit cubit) => cubit.state?.themeMode ?? AppThemeMode.system,
    );
    return Scaffold(
      key: SettingsKeys.themeScreen,
      appBar: AppBar(title: Text(context.l10n.settingsTheme)),
      body: ListView(
        children: [
          for (final mode in AppThemeMode.values)
            ChoiceTile(
              key: SettingsKeys.themeOption(mode),
              icon: mode.icon,
              label: mode.label(context.l10n),
              selected: selected == mode,
              onTap: () => cubit.setThemeMode(mode),
            ),
        ],
      ),
    );
  }
}
