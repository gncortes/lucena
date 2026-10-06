import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/dependencies.dart';
import '../../../domain/models/app_language.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/clock_settings_ui.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme_mode_ui.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../view_models/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.version = appVersion});

  /// A versão do app, no rodapé, para quem relata um problema. Vazia (build
  /// local, sem versão): não aparece.
  final String version;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.select(
      (SettingsCubit cubit) => cubit.state?.languageCode,
    );
    final language = AppLanguage.fromCode(languageCode);
    final themeMode = context.select(
      (SettingsCubit cubit) => cubit.state?.themeMode ?? AppThemeMode.system,
    );
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final clock = context.select(
      (SettingsCubit cubit) => cubit.state?.clock ?? const ClockSettings(),
    );
    final profile = context.select((ProfileCubit cubit) => cubit.state);
    final characterTalk = context.select(
      (SettingsCubit cubit) => cubit.state?.characterTalk ?? true,
    );
    final sound = context.select(
      (SettingsCubit cubit) => cubit.state?.sound ?? true,
    );
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
          ListTile(
            key: SettingsKeys.boardAppearanceTile,
            leading: const Icon(Icons.palette_outlined),
            title: Text(context.l10n.settingsBoardAppearance),
            subtitle: Text(
              '${board.colors.label(context.l10n)} · ${board.pieces.label}',
              key: SettingsKeys.boardAppearanceValue,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.settingsBoardAppearance),
          ),
          ListTile(
            key: SettingsKeys.boardBehaviorTile,
            leading: const Icon(Icons.touch_app_outlined),
            title: Text(context.l10n.settingsBoardBehavior),
            subtitle: Text(
              board.moveMethod.label(context.l10n),
              key: SettingsKeys.boardBehaviorValue,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.settingsBoardBehavior),
          ),
          ListTile(
            key: SettingsKeys.clockTile,
            leading: const Icon(Icons.timer_outlined),
            title: Text(context.l10n.settingsClock),
            subtitle: Text(
              clock.position.label(context.l10n),
              key: SettingsKeys.clockValue,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.settingsClock),
          ),
          SwitchListTile(
            key: SettingsKeys.soundSwitch,
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(context.l10n.settingsSound),
            subtitle: Text(context.l10n.settingsSoundHint),
            value: sound,
            onChanged: (value) =>
                context.read<SettingsCubit>().setSound(enabled: value),
          ),
          SwitchListTile(
            key: SettingsKeys.characterTalkSwitch,
            secondary: const Icon(Icons.chat_bubble_outline),
            title: Text(context.l10n.settingsCharacterTalk),
            subtitle: Text(context.l10n.settingsCharacterTalkHint),
            value: characterTalk,
            onChanged: (value) =>
                context.read<SettingsCubit>().setCharacterTalk(enabled: value),
          ),
          ListTile(
            key: SettingsKeys.tourTile,
            leading: const Icon(Icons.tour_outlined),
            title: Text(context.l10n.settingsTour),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.tour),
          ),
          // Só em build de desenvolvimento e de teste.
          if (showsDevTools)
            ListTile(
              key: SettingsKeys.maiaDebugTile,
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(context.l10n.maiaDebugTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(Routes.settingsMaia),
            ),
          if (version.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Text(
                context.l10n.homeVersion(version),
                key: SettingsKeys.version,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
