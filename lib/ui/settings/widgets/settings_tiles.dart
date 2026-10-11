import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/app_language.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/clock_settings_ui.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/keys/voice_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme_mode_ui.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../view_models/settings_cubit.dart';

/// Uma tela de um grupo das Configurações: o título e as opções dele.
class SettingsGroupScreen extends StatelessWidget {
  const SettingsGroupScreen({
    required this.screenKey,
    required this.title,
    required this.children,
    super.key,
  });

  final Key screenKey;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: scrollPadding(context), children: children),
    );
  }
}

/// Aparência: idioma, tema, tabuleiro e tela inicial.
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = AppLanguage.fromCode(
      context.select((SettingsCubit cubit) => cubit.state?.languageCode),
    );
    final themeMode = context.select(
      (SettingsCubit cubit) => cubit.state?.themeMode ?? AppThemeMode.system,
    );
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return SettingsGroupScreen(
      screenKey: SettingsKeys.appearanceScreen,
      title: l10n.settingsAppearance,
      children: [
        ListTile(
          key: SettingsKeys.languageTile,
          leading: const Icon(Icons.language),
          title: Text(l10n.settingsLanguage),
          subtitle: Text(
            language?.nativeName ?? l10n.settingsLanguageSystem,
            key: SettingsKeys.languageValue,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.settingsLanguage),
        ),
        ListTile(
          key: SettingsKeys.themeTile,
          leading: Icon(themeMode.icon),
          title: Text(l10n.settingsTheme),
          subtitle: Text(themeMode.label(l10n), key: SettingsKeys.themeValue),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.settingsTheme),
        ),
        ListTile(
          key: SettingsKeys.boardAppearanceTile,
          leading: const Icon(Icons.palette_outlined),
          title: Text(l10n.settingsBoardAppearance),
          subtitle: Text(
            '${board.colors.label(l10n)} · ${board.pieces.label}',
            key: SettingsKeys.boardAppearanceValue,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.settingsBoardAppearance),
        ),
        ListTile(
          key: SettingsKeys.homeLayoutTile,
          leading: const Icon(Icons.dashboard_customize_outlined),
          title: Text(l10n.homeLayoutTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.homeLayout),
        ),
      ],
    );
  }
}

/// Partida: como mover as peças, o relógio e os comentários do adversário.
class GameSettingsScreen extends StatelessWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final clock = context.select(
      (SettingsCubit cubit) => cubit.state?.clock ?? const ClockSettings(),
    );
    final characterTalk = context.select(
      (SettingsCubit cubit) => cubit.state?.characterTalk ?? true,
    );
    return SettingsGroupScreen(
      screenKey: SettingsKeys.gameScreen,
      title: l10n.settingsGame,
      children: [
        ListTile(
          key: SettingsKeys.boardBehaviorTile,
          leading: const Icon(Icons.touch_app_outlined),
          title: Text(l10n.settingsBoardBehavior),
          subtitle: Text(
            board.moveMethod.label(l10n),
            key: SettingsKeys.boardBehaviorValue,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.settingsBoardBehavior),
        ),
        ListTile(
          key: SettingsKeys.clockTile,
          leading: const Icon(Icons.av_timer_outlined),
          title: Text(l10n.settingsClock),
          subtitle: Text(
            clock.position.label(l10n),
            key: SettingsKeys.clockValue,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.settingsClock),
        ),
        SwitchListTile(
          key: SettingsKeys.characterTalkSwitch,
          secondary: const Icon(Icons.chat_bubble_outline),
          title: Text(l10n.settingsCharacterTalk),
          subtitle: Text(l10n.settingsCharacterTalkHint),
          value: characterTalk,
          onChanged: (value) =>
              context.read<SettingsCubit>().setCharacterTalk(enabled: value),
        ),
      ],
    );
  }
}

/// Som, vibração e voz.
class SoundSettingsScreen extends StatelessWidget {
  const SoundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sound = context.select(
      (SettingsCubit cubit) => cubit.state?.sound ?? true,
    );
    final vibration = context.select(
      (SettingsCubit cubit) => cubit.state?.vibration ?? true,
    );
    final voiceEnabled = context.select(
      (SpeechCubit cubit) => cubit.state.settings.enabled,
    );
    return SettingsGroupScreen(
      screenKey: SettingsKeys.soundScreen,
      title: l10n.settingsSoundGroup,
      children: [
        SwitchListTile(
          key: SettingsKeys.soundSwitch,
          secondary: const Icon(Icons.volume_up_outlined),
          title: Text(l10n.settingsSound),
          subtitle: Text(l10n.settingsSoundHint),
          value: sound,
          onChanged: (value) =>
              context.read<SettingsCubit>().setSound(enabled: value),
        ),
        SwitchListTile(
          key: SettingsKeys.vibrationSwitch,
          secondary: const Icon(Icons.vibration),
          title: Text(l10n.settingsVibration),
          subtitle: Text(l10n.settingsVibrationHint),
          value: vibration,
          onChanged: (value) =>
              context.read<SettingsCubit>().setVibration(enabled: value),
        ),
        ListTile(
          key: VoiceKeys.settingsTile,
          leading: const Icon(Icons.record_voice_over_outlined),
          title: Text(l10n.voiceSection),
          subtitle: Text(voiceEnabled ? l10n.voiceSpeakAloud : l10n.voiceNone),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.settingsVoice),
        ),
      ],
    );
  }
}
