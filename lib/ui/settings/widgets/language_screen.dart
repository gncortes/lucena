import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
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
          _LanguageOption(
            key: SettingsKeys.languageSystem,
            label: context.l10n.settingsLanguageSystem,
            selected: languageCode == null,
            onTap: () => cubit.setLanguage(null),
          ),
          const Divider(height: 1),
          for (final language in cubit.languages)
            _LanguageOption(
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

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      selected: selected,
      // O nome de cada idioma fica sempre na escrita dele; a marca troca com animação.
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: selected
            ? const Icon(Icons.check, key: ValueKey('selected'))
            : const SizedBox.square(dimension: 24, key: ValueKey('empty')),
      ),
      onTap: onTap,
    );
  }
}
