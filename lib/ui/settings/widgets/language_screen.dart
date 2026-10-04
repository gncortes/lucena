import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/choice_tile.dart';
import '../view_models/settings_cubit.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final languageCode = context.select(
      (SettingsCubit cubit) => cubit.state?.languageCode,
    );
    return Scaffold(
      key: SettingsKeys.languageScreen,
      appBar: AppBar(title: Text(context.l10n.settingsLanguage)),
      body: ListView(
        children: [
          ChoiceTile(
            key: SettingsKeys.languageSystem,
            label: context.l10n.settingsLanguageSystem,
            selected: languageCode == null,
            onTap: () => cubit.setLanguage(null),
          ),
          const Divider(height: 1),
          // O nome de cada idioma fica sempre na escrita dele.
          for (final language in cubit.languages)
            ChoiceTile(
              key: SettingsKeys.languageOption(language.code),
              label: language.nativeName,
              selected: languageCode == language.code,
              onTap: () => cubit.setLanguage(language),
            ),
        ],
      ),
    );
  }
}
