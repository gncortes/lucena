import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/app_language.dart';
import '../../../routing/routes.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.select(
      (SettingsCubit cubit) => cubit.state?.languageCode,
    );
    final language = AppLanguage.fromCode(languageCode);
    return Scaffold(
      key: SettingsKeys.screen,
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle, key: SettingsKeys.title),
      ),
      body: ListView(
        children: [
          ListTile(
            key: SettingsKeys.languageTile,
            leading: const Icon(Icons.language),
            title: Text(context.l10n.settingsLanguage),
            subtitle: Text(
              language?.nativeName ?? context.l10n.settingsLanguageSystem,
              key: SettingsKeys.languageValue,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.settingsLanguage),
          ),
        ],
      ),
    );
  }
}
