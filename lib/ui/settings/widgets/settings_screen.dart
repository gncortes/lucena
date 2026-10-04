import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/app_language.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/routes.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme_mode_ui.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../view_models/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.select(
      (SettingsCubit cubit) => cubit.state?.languageCode,
    );
    final language = AppLanguage.fromCode(languageCode);
    final themeMode = context.select(
      (SettingsCubit cubit) => cubit.state?.themeMode ?? AppThemeMode.system,
    );
    final profile = context.select((ProfileCubit cubit) => cubit.state);
    return Scaffold(
      key: SettingsKeys.screen,
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle, key: SettingsKeys.title),
      ),
      body: ListView(
        children: [
          ListTile(
            key: SettingsKeys.profileTile,
            leading: const Icon(Icons.person_outline),
            title: Text(context.l10n.settingsProfile),
            subtitle: Text(
              profile == null ? '' : _profileSummary(context, profile),
              key: SettingsKeys.profileValue,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.settingsProfile),
          ),
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
          ListTile(
            key: SettingsKeys.themeTile,
            leading: Icon(themeMode.icon),
            title: Text(context.l10n.settingsTheme),
            subtitle: Text(
              themeMode.label(context.l10n),
              key: SettingsKeys.themeValue,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.settingsTheme),
          ),
        ],
      ),
    );
  }

  /// "Apelido · faixa", com o apelido padrão quando o jogador não escolheu um.
  String _profileSummary(BuildContext context, UserProfile profile) {
    final nickname = profile.nickname.isEmpty
        ? context.l10n.profileNicknameDefault
        : profile.nickname;
    return '$nickname · ${profile.level.name(context.l10n)}';
  }
}
